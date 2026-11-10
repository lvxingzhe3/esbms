import 'dart:async';
import 'dart:convert';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/asyncLock.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/helper/routes.dart';
import 'package:bms_app/helper/topsnackbar.dart';
import 'package:bms_app/model/batpackinfo.dart';
import 'package:bms_app/model/bmscmd.dart';
import 'package:bms_app/model/device.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/state/bluetooth_state.dart';
import 'package:bms_app/state/user_state.dart';
import 'package:bms_app/ui/page/device/alarm_page.dart';
import 'package:bms_app/ui/page/device/battery_cell_page.dart';
import 'package:bms_app/ui/page/device/bmsrunning_page.dart';
import 'package:bms_app/ui/theme/custombackground.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/utils/iconfont.dart';
import 'package:bms_app/utils/loggerdebug_util.dart';
import 'package:bms_app/utils/securestorageutil.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:getwidget/getwidget.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Timer? _timer; //定时任务
  String devname = "--"; //设备名称
  List<DeviceItem> _deviceList = []; //设备列表
  String? _currentDeviceId; //当前设备ID
  bool _isLoadingDevice = false; //是否正在加载设备列表
  bool _isConnected = false; //是否连接设备
  bool hasDevice = false; //是否有设备
  int refreshnum = 0;
  // 侧边栏的 GlobalKey
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AsyncLock _comLock = AsyncLock();

  @override
  void initState() {
    super.initState();
  }

  bool _initDone = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initDone) {
      _initDone = true;
      _loadDevices();
      // ✅ 放到微任务队列，等build完成再执行
      Future.microtask(() async {
        //batMinitorCheck();
        bmsMinitorCheck();
      });

      _timer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
        bmsMinitorCheck();
        //batMinitorCheck();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 手动打开侧边栏
  void _openDrawer() {
    //Scaffold.of(context).openDrawer();
    // AppBar 里面的 `context` 是ppBar 自己的 context，不是 Scaffold 的 context，用 GlobalKey
    _scaffoldKey.currentState?.openDrawer();
  }

  /// 关闭侧边栏
  void _closeDrawer() {
    final state = _scaffoldKey.currentState;
    if (state?.isDrawerOpen ?? false) {
      state?.closeDrawer();
    }
  }

  // 蓝牙发送
  Future writecmd(List<int> data) async {
    final writechar = ref.read(bleStateProvider).characteristic;
    try {
      await writechar!.write(data, withoutResponse: true);
    } catch (e) {
      print(e);
    }
  }

  ///蓝牙发送并返回
  Future<List<int>?> writeAndRead({
    required List<int> sendBytes,
    int timeoutMs = 500,
  }) async {
    final writeChar = ref.read(bleStateProvider).characteristic;
    final recChar = ref.read(bleStateProvider).reccharacteristic;
    if (writeChar == null || recChar == null) return null;
    final completer = Completer<List<int>>();
    late StreamSubscription sub;
    sub = recChar.onValueReceived.listen((data) {
      completer.complete(data);
      sub.cancel();
    });
    // 超时
    Future.delayed(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        sub.cancel();
        print('writeAndRead timeout error');
        return null;
      }
    });
    // 下发命令
    await writeChar.write(sendBytes, withoutResponse: true);
    return await completer.future;
  }

  //通信测试
  Future<void> batMinitorCheck() async {
    await _comLock.run(() async {
      // 这里面同一时间只会进入一次
      try {
        if (GlobalData.DeviceConnectType == 1) {
          Batpackinfo batpackinfo = new Batpackinfo();
          final notifier = ref.watch(bleStateProvider.notifier);
          _currentDeviceId = GlobalData.currentDeviceId;
          devname = GlobalData.currentDeviceName ?? "--";
          /************WIFI连接*************/
          if (_currentDeviceId != null && _currentDeviceId!.isNotEmpty) {
            var apiService = ref.read(apiServiceProvider);
            var rec = await apiService.getdeviceBmsInfo(_currentDeviceId!);
            var apiRes = ApiResponse.fromJson(rec);
            if (apiRes.data == null) return;
            var devjson = apiRes.data['fields'];

            bool alarmstate = false;
            //故障状态
            dynamic paramvalue = devjson['fault_status'];
            BatPackbmsinfo bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }

            //保护状态
            paramvalue = devjson['protection_status'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }

            //告警状态
            paramvalue = devjson['alarm_status'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }

            batpackinfo.isConnected = true;
            setState(() {
              _isConnected = true;
            });
            //累加电压
            paramvalue = devjson['battery_total_voltage'];
            //final Map<String,dynamic> map = volinfo as Map<String,dynamic>;
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.voltage = bmsinfo.value;
            //电流
            paramvalue = devjson['battery_current'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.current = bmsinfo.value;
            //实时功率
            paramvalue = devjson['battery_realtime_power'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.power = bmsinfo.value;

            //告警状态
            paramvalue = devjson['alarm_status_hex'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            int val = bmsinfo.value.toInt();
            // 取高8位、低8位
            batpackinfo.bms_alarmH = (val >> 8) & 0xFF;
            batpackinfo.bms_alarmL = val & 0xFF;

            //保护状态
            paramvalue = devjson['alarm_status_hex'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            val = bmsinfo.value.toInt();
            // 取高8位、低8位
            batpackinfo.bms_protectH = (val >> 8) & 0xFF;
            batpackinfo.bms_protectL = val & 0xFF;

            //最高单体电压
            paramvalue = devjson['battery_max_cell_voltage'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.max_voltage = bmsinfo.value;
            //最低单体电压
            paramvalue = devjson['battery_min_cell_voltage'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.min_voltage = bmsinfo.value;
            //最高电芯温度
            paramvalue = devjson['battery_max_cell_temperature'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.max_temperature = bmsinfo.value;
            //最低电芯温度
            paramvalue = devjson['battery_min_cell_temperature'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.min_temperature = bmsinfo.value;
            //剩余放电时间
            paramvalue = devjson['battery_remaining_discharge_time'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.dchg_timeuse = bmsinfo.value.toInt();

            //最高单体电压序号
            paramvalue = devjson['battery_max_cell_voltage_index'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.max_volindex = bmsinfo.value.toInt();
            //最低单体电压序号
            paramvalue = devjson['battery_min_cell_voltage_index'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.min_volindex = bmsinfo.value.toInt();
            //最高电芯温度序号
            paramvalue = devjson['battery_max_cell_temperature_index'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.max_tempindex = bmsinfo.value.toInt();
            //最低电芯温度序号
            paramvalue = devjson['battery_min_cell_temperature_index'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.min_tempeindex = bmsinfo.value.toInt();
            //soc
            paramvalue = devjson['battery_charge_state'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.soc = bmsinfo.value;

            final paramrec = await apiService.getparamlist(_currentDeviceId!);
            final apiparamRes = ApiResponse.fromJson(paramrec);
            final devparamjson = apiparamRes.data;
            //循环次数
            paramvalue = devparamjson['battery_cycle_count'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.cycle = bmsinfo.value.toInt();
            //电芯数量
            paramvalue = devparamjson['numberOfIndividualBatteries'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.cellnum = bmsinfo.value.toInt();
            //电芯温度数量
            paramvalue = devparamjson['temperatureQuantity'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.celltempnum = bmsinfo.value.toInt();
            //电池类型
            paramvalue = devparamjson['battery_type'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            String batType = switch (bmsinfo.value.toInt()) {
              70 => "LFP",
              86 => "NCM/NCA",
              102 => "SIB",
              _ => "--"
            };
            batpackinfo.bat_type = batType;
            //电池总容量
            paramvalue = devparamjson['battery_full_capacity'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.totalcapaciry = bmsinfo.value / 1000;
            //电池剩余容量
            paramvalue = devparamjson['battery_remaining_capacity'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.remaincap =
                (batpackinfo.totalcapaciry * batpackinfo.soc / 100);
            //batpackinfo.remaincap = bmsinfo.value;

            //单体电压
            batpackinfo.cellvols = [];
            for (int i = 0; i < batpackinfo.cellnum; i++) {
              paramvalue = devjson[
                  'battery_cell_voltage_${(i + 1).toString().padLeft(3, '0')}'];
              bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
              int index = i + 1;
              Batinfo batinfo = Batinfo(
                  "cell${index.toString().padLeft(2, '0')}", bmsinfo.value);
              index == batpackinfo.max_volindex
                  ? batinfo.max = true
                  : batinfo.max = false;
              index == batpackinfo.min_volindex
                  ? batinfo.min = true
                  : batinfo.min = false;
              batpackinfo.cellvols.add(batinfo);
            }
            //电芯温度
            batpackinfo.celltemps = [];
            for (int i = 0; i < batpackinfo.celltempnum; i++) {
              try {
                paramvalue = devjson[
                    'battery_temperature_${(i + 1).toString().padLeft(3, '0')}'];
                bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
              } catch (e) {
                bmsinfo = BatPackbmsinfo(nameDispaly: "", valueDisplay: "");
              }

              int index = i + 1;
              Batinfo batinfo = Batinfo(
                  index.toString().padLeft(2, '0'), bmsinfo.valueDisplay);
              index == batpackinfo.max_tempindex
                  ? batinfo.max = true
                  : batinfo.max = false;
              index == batpackinfo.min_tempeindex
                  ? batinfo.min = true
                  : batinfo.min = false;
              batpackinfo.celltemps.add(batinfo);
            }
          } else {
            setState(() {
              _isConnected = false;
            });
          }
          notifier.updateBmsinfo(batpackinfo);
        } else {
          /************蓝牙连接*************/
          final notifier = ref.watch(bleStateProvider.notifier);
          final writechar = ref.read(bleStateProvider).characteristic;
          final recchar = ref.read(bleStateProvider).reccharacteristic;
          if (writechar == null || recchar == null) {
            devname = "--";
            return;
          }
          //设备名称
          devname = writechar.device.advName;
          Batpackinfo batpackinfo = new Batpackinfo();
          // 监听蓝牙连接
          if (writechar.device.isConnected == false) {
            print("蓝牙断开");
            devname = "--";
            notifier.updateBmsinfo(batpackinfo);
            return;
          } else {
            //电池类型查询
            List<int> data = [
              BmsCmd.cmdAddress,
              0x03,
              0x9C,
              0XA5,
              0X00,
              0X03,
              0X3A,
              0X3C
            ];
            List<int>? recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              String batType = switch (recvBytes[4]) {
                70 => "LFP",
                86 => "NCM/NCA",
                102 => "SIB",
                _ => "--"
              };
              batpackinfo.bat_type = batType;

              var rec = recvBytes.skip(5).take(2).toList();
              int recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.cells = recvalue;
              }

              rec = recvBytes.skip(7).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.temps = recvalue;
              }
            }
            await Future.delayed(const Duration(milliseconds: 100));
            //电池容量查询
            data = [
              BmsCmd.cmdAddress,
              0x03,
              0x9E,
              0X99,
              0X00,
              0X11,
              0X7B,
              0X85
            ];
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              var rec = recvBytes.skip(3).take(4).toList();
              int recvalue = fourBytesToInt(rec);
              if (recvalue > 0) {
                batpackinfo.totalcapaciry = recvalue.toDouble();
              }

              rec = recvBytes.skip(11).take(4).toList();
              recvalue = fourBytesToInt(rec);
              if (recvalue > 0) {
                batpackinfo.remaincap = recvalue.toDouble();
              }

              rec = recvBytes.skip(35).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.cycle = recvalue;
              }
            }
            ;
            await Future.delayed(const Duration(milliseconds: 100));
            //累加电压查询
            data = [
              BmsCmd.cmdAddress,
              0x04,
              0x75,
              0X31,
              0X00,
              0X1E,
              0X3A,
              0X45
            ];
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              var rec = recvBytes.skip(3).take(2).toList();
              int recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.voltage = recvalue.toDouble() / 100;
              }

              rec = recvBytes.skip(5).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.collectvol = recvalue.toDouble() / 100;
              }

              rec = recvBytes.skip(7).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.loadvol = recvalue.toDouble() / 100;
              }

              rec = recvBytes.skip(9).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.current = recvalue.toDouble() / 100;
              }

              rec = recvBytes.skip(11).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.soc = (recvalue / 10).toDouble();
              }

              rec = recvBytes.skip(17).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.soh = (recvalue / 10).toDouble();
              }

              rec = recvBytes.skip(19).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.power = recvalue.toDouble();
              }

              rec = recvBytes.skip(21).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.dchg_timeuse = recvalue;
              }

              rec = recvBytes.skip(33).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.max_voltage = recvalue.toDouble();
              }

              rec = recvBytes.skip(37).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.min_voltage = recvalue.toDouble();
              }

              rec = recvBytes.skip(43).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.max_temperature =
                    ((recvalue - 2730) / 10).toDouble();
              }
              rec = recvBytes.skip(47).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.min_temperature =
                    ((recvalue - 2730) / 10).toDouble();
              }
            }

            await Future.delayed(const Duration(milliseconds: 100));
            //电池状态查询
            data = [
              BmsCmd.cmdAddress,
              0x04,
              0x75,
              0X95,
              0X00,
              0X0F,
              0XBB,
              0XAA
            ];
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              var rec = recvBytes.skip(3).take(2).toList();
              int recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.bms_alarmL = rec[0];
                batpackinfo.bms_alarmH = rec[1];
              }

              rec = recvBytes.skip(5).take(2).toList();
              recvalue = twoBytesToIntBigEndian(rec);
              if (recvalue > 0) {
                batpackinfo.bms_protectL = rec[0];
                batpackinfo.bms_protectH = rec[1];
              }
            }

            await Future.delayed(const Duration(milliseconds: 100));
            //电芯电压查询
            data = [
              BmsCmd.cmdAddress,
              0x04,
              0x79,
              0X19,
              0X00,
              batpackinfo.cells
            ];
            List<int> crc = calculateCRC16(data);
            data.addAll(crc);
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              batpackinfo.cellvols = [];
              for (int i = 0; i < batpackinfo.cells; i++) {
                var rec = recvBytes.skip(3 + i * 2).take(2).toList();
                int recvalue = twoBytesToIntBigEndian(rec);
                int index = i + 1;
                Batinfo batinfo = Batinfo("cell$index", recvalue);
                batpackinfo.cellvols.add(batinfo);
              }
            }

            await Future.delayed(const Duration(milliseconds: 100));
            //电芯温度查询
            data = [
              BmsCmd.cmdAddress,
              0x04,
              0x7D,
              0X01,
              0X00,
              batpackinfo.temps
            ];
            crc = calculateCRC16(data);
            data.addAll(crc);
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              batpackinfo.celltemps = [];
              for (int i = 0; i < batpackinfo.temps; i++) {
                var rec = recvBytes.skip(3 + i * 2).take(2).toList();
                int recvalue = twoBytesToIntBigEndian(rec);
                int index = i + 1;
                Batinfo batinfo =
                    Batinfo("$index", ((recvalue - 2730) / 10).toDouble());
                batpackinfo.celltemps.add(batinfo);
              }
            }

            //版本
            data = [BmsCmd.cmdAddress, 0x04, 0x75, 0XF9, 0X00, 0X20];
            crc = calculateCRC16(data);
            data.addAll(crc);
            recvBytes = await writeAndRead(sendBytes: data);
            if (recvBytes != null &&
                recvBytes.length >= 5 &&
                recvBytes[0] == BmsCmd.cmdAddress) {
              var rec = recvBytes.skip(3).take(16).toList();
              String str = utf8.decode(rec);
              batpackinfo.hardversion = str;
              rec = recvBytes.skip(35).take(16).toList();
              str = utf8.decode(rec);
              batpackinfo.softversion = str;
            }

            notifier.updateBmsinfo(batpackinfo);
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      } catch (e) {
        LoggerDebugUtil.e('batMinitorCheck异常', e);
      }
    });
  }

  Future<void> bmsMinitorCheck() async {
    await _comLock.run(() async {
      // 这里面同一时间只会进入一次
      try {
        setState(() {
          devname = GlobalData.currentDeviceName ?? "--";
        });

        final notifier = ref.watch(bleStateProvider.notifier);
        if (GlobalData.DeviceConnectType == 1) {
          refreshnum++;
          if (refreshnum > 20) {
            refreshnum = 0;
            await notifier.refreshToken();
          }
        }

        bool connected = await notifier.refreshBatpackinfo();
        if (connected == false && GlobalData.currentDeviceId != null) {
          TopSnackBar.show(
            context,
            S.of(context).deviceoffline,
            backgroundColor: AppColor.warn,
            icon: Icons.check_circle,
            duration: Duration(seconds: 2),
          );
        }
      } catch (e) {
        LoggerDebugUtil.e('bmsMinitorCheck异常', e);
      }
    });
  }

  //读取设备列表
  Future readDeviceList() async {
    _loadDevices();
    _openDrawer();
  }

  //加载设备列表
  Future _loadDevices() async {
    if (_isLoadingDevice) return; // 防止重复点击
    setState(() {
      _isLoadingDevice = true;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final rec = await apiService.getdevicelist();
      final apiRes = ApiResponse.fromJson(rec);
      final devlistjson = apiRes.data['list'];
      final res = devlistjson
          .map<DeviceItem>(
              (e) => DeviceItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _deviceList = res;
      if (_deviceList.isEmpty) {
        _currentDeviceId = null;
        GlobalData.currentDeviceId = null;
        GlobalData.currentDeviceName = null;
        GlobalData.currentDtuId = null;
      }
    } catch (e) {
      print('readDeviceList ex->$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevice = false;
        });
      }
    }
  }

  //加载设备参数
  Future _loadConfigs() async {
    try {
      if (_isLoadingDevice) return; // 防止重复点击
      setState(() {
        _isLoadingDevice = true;
      });
      final apiService = ref.read(apiServiceProvider);
      final paramrec =
          await apiService.getparamlist(GlobalData.currentDeviceId!);
      final apiparamRes = ApiResponse.fromJson(paramrec);
      if (apiparamRes.code == 0 &&
          apiparamRes.data != null &&
          apiparamRes.data.isEmpty) {
        final rec = await apiService.getparambatch(GlobalData.currentDeviceId!);
        final apiRes = ApiResponse.fromJson(rec);
        final batchid = apiRes.data['id'];
        if (batchid != null && batchid.toString().length > 0) {
          int batchId = int.tryParse(batchid.toString()) ?? 0;
          final rec2 = await apiService.getparambatchdetials(batchId);
          final apiRes2 = ApiResponse.fromJson(rec2);
          TopSnackBar.show(
            context,
            S.of(context).deviceinittip,
            backgroundColor: AppColor.info,
            icon: Icons.check_circle,
            duration: Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      print('readDeviceList ex->$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevice = false;
        });
      }
    }
  }

  ///报错设备信息
  Future<void> saveDevice(DeviceItem dev) async {
    setState(() {
      _currentDeviceId = dev.id;
      devname = dev.name;
      GlobalData.currentDeviceId = dev.id;
      GlobalData.currentDeviceName = dev.name;
      GlobalData.currentDtuId = dev.dtuDtuid;
    });

    String jsonStr = json.encode(dev.toJson());
    SecureStorageUtil.save('device', jsonStr);
    await _loadConfigs();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStateProvider);
    final isConnected = ref.watch(bleStateProvider.select((s) =>
        s.characteristic != null && s.characteristic!.device.isConnected));
    final batpackinfo =
        ref.watch(bleStateProvider.select((s) => s.batpackinfo));
    List<DeviceInfoModel> mainStatus = [
      {
        "id": 0,
        "label": S.of(context).totalVol,
        "value": batpackinfo.voltage.toString() + "V",
        "icon": {"type": AppIcon.battery_black, "color": AppColor.primary}
      },
      {
        "id": 1,
        "label": S.of(context).cur,
        "value": batpackinfo.current.toString() + "mA",
        "icon": {
          "type": AppIcon.battery_positive,
          "color": AppColor.sinotaYellow
        }
      },
      {
        "id": 2,
        "label": S.of(context).power,
        "value": batpackinfo.power.toString() + "W",
        "icon": {"type": AppIcon.batteries, "color": AppColor.sinotaBlue}
      },
      {
        "id": 3,
        "label": S.of(context).cycleCount,
        "value": batpackinfo.cycle.toString() + S.of(context).times,
        "icon": {"type": AppIcon.autorenew, "color": AppColor.sinotaBlue}
      },
      {
        "id": 4,
        "label": S.of(context).cellMaxVal,
        "value": batpackinfo.max_voltage.toString() + "mV",
        "icon": {
          "type": FontAwesomeIcons.batteryFull,
          "color": AppColor.success
        }
      },
      {
        "id": 5,
        "label": S.of(context).cellMinVal,
        "value": batpackinfo.min_voltage.toString() + "mV",
        "icon": {
          "type": FontAwesomeIcons.batteryQuarter,
          "color": AppColor.error
        }
      },
      {
        "id": 6,
        "label": S.of(context).maxTemp,
        "value": batpackinfo.max_temperature.toString() + "°C",
        "icon": {
          "type": FontAwesomeIcons.temperatureHigh,
          "color": AppColor.success
        }
      },
      {
        "id": 7,
        "label": S.of(context).minTemp,
        "value": batpackinfo.min_temperature.toString() + "°C",
        "icon": {
          "type": FontAwesomeIcons.temperatureLow,
          "color": AppColor.error
        }
      },
      {
        "id": 8,
        "label": 'SoH',
        "value": batpackinfo.soh.toString() + "%",
        "icon": {"type": FontAwesomeIcons.heartPulse, "color": AppColor.info}
      },
    ].map((data) => DeviceInfoModel.fromJson(data)).toList();

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: customTitleText(S.of(context).title),
          centerTitle: true,
          backgroundColor: Colors.transparent, // AppBar 透明
          elevation: 0, // 移除底部阴影，否则会有灰色分层
          leadingWidth: 48,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //SizedBox(width: 10),
              if (GlobalData.DeviceConnectType == 1)
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    IconFont.devlist,
                    color: _isConnected ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () async {
                    readDeviceList();
                  },
                )
            ],
          ),
          actions: [
            if (GlobalData.DeviceConnectType == 0)
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  IconFont.bluetooth,
                  color: isConnected ? Colors.blue : Colors.grey,
                ),
                onPressed: () async {
                  //context.pushNamed(AppRouter.wificonfigfind);
                  context.pushNamed(AppRouter.bluetooth);
                },
              )
          ],
        ),
        key: _scaffoldKey,
        drawer: Drawer(
            backgroundColor: AppColor.backgroud,
            elevation: 16,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 12, left: 5, right: 5),
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12), // 竖条和文字之间间距
                            customText('${S.of(context).deviceList}',
                                style: TextStyles.textStyle16),
                            Spacer(),
                            _isLoadingDevice
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                :
                                // 右侧刷新图标
                                IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 30, minHeight: 30),
                                    icon: const Icon(
                                      Icons.refresh,
                                      size: 26,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      // 刷新设备列表逻辑
                                      _loadDevices();
                                    },
                                  ),
                          ],
                        ),
                      ),
                      // ==========动态渲染设备列表==========
                      ..._deviceList.map((dev) {
                        final bool isSelect =
                            dev.id == GlobalData.currentDeviceId;
                        return ListTile(
                          leading: Icon(
                            Icons.devices,
                            color: dev.isOnline ? Colors.green : Colors.grey,
                          ),
                          title: customText('${dev.name}',
                              style: TextStyles.textStyle14), //Text(dev.name),
                          subtitle: customText('${dev.dtuDtuid}',
                              style: TextStyles.textStyle14),
                          selected: isSelect, // ✅选中高亮
                          trailing: isSelect
                              ? const Icon(Icons.check_circle,
                                  size: 18, color: Colors.green) // 选中显示对勾
                              : null,
                          onTap: () async {
                            if (dev.isOnline) {
                              await saveDevice(dev);
                              _closeDrawer();
                              bmsMinitorCheck();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(S.of(context).deviceoffline)),
                              );
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
                SafeArea(
                    child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(40, 8, 40, 10),
                  color: Colors.transparent,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final bool? res =
                          await context.pushNamed<bool>(AppRouter.adddev);
                      if (res == true) {
                        _loadDevices();
                      }
                      //context.pushNamed(AppRouter.adddev);
                      // 跳转添加设备页
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDevicePage()));
                    },
                    icon: const Icon(Icons.add),
                    label: Text(S.of(context).adddevice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isConnected ? AppColor.error : Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )),
              ],
            )),
        body: CustomBackground(
            child: ListView(
          padding: EdgeInsets.only(bottom: 12),
          children: <Widget>[
            GFCard(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: AppColor.backgroud,
                margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 160.0,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  customText(
                                      '${S.of(context).deviceName}: ${devname}',
                                      style: TextStyles.textStyle14),
                                  //SizedBox(height: 10),
                                  // 自适应宽度（不扩展）
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      customText(
                                          '${S.of(context).totalBattery}: ${batpackinfo.totalcapaciry}AH',
                                          style: TextStyles.textStyle14),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      customText(
                                          '${S.of(context).remainBattery}: ${batpackinfo.remaincap}AH',
                                          style: TextStyles.textStyle14),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      customText(
                                          //batpackinfo.dchg_timeuse.toString() + "min"
                                          '${S.of(context).remainDischargeTime}: ${batpackinfo.dchg_timeuse}min',
                                          style: TextStyles.textStyle14),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      customText(
                                          //batpackinfo.dchg_timeuse.toString() + "min"
                                          '${S.of(context).remainchargeTime}: ${batpackinfo.chg_timeuse}min',
                                          style: TextStyles.textStyle14),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 150.0,
                            height: 150.0,
                            child: LiquidCircularProgressIndicator(
                              value: (batpackinfo.soc) / 100,
                              valueColor: AlwaysStoppedAnimation(Colors.green),
                              backgroundColor: Colors.black,
                              borderColor: Colors.green,
                              borderWidth: 2.0,
                              direction: Axis.vertical,
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  customText(batpackinfo.soc.toString() + "%",
                                      style: TextStyles.titleStyle),
                                  customText('SOC',
                                      style: TextStyles.textStyle14),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  customText(batpackinfo.workstate,
                                      style: TextStyles.textStyle14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ])),
            InkWell(
              onTap: () async {
                if (userState.role == 1) {
                  context.pushNamed(AppRouter.runningstate);
                }
              },
              child: Stack(
                children: [
                  GFCard(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      color: AppColor.backgroud,
                      margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
                      content: GridView.count(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        crossAxisSpacing: 0,
                        children: mainStatus.map((model) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              customIcon(context,
                                  icon: model.icon?.type ?? AppIcon.bluetooth,
                                  iconColor: model.icon?.color,
                                  isTwitterIcon: false,
                                  size: 26),
                              SizedBox(height: 4),
                              customText(model.label,
                                  style: TextStyles.subtitleStyle),
                              SizedBox(height: 2),
                              customText(model.value.toString(),
                                  style: TextStyles.textStyle14),
                            ],
                          );
                        }).toList(),
                      )),
                  // 运行状态
                  if (userState.role > 0)
                    Positioned(
                        top: 20,
                        left: 20,
                        child: SizedBox(
                          width: 20,
                          height: 13,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Icon(
                              IconFont.runstate,
                              color: Color.fromARGB(255, 161, 189, 22),
                            ),
                          ),
                        )),
                ],
              ),
            ),
            AlarmInfoPage(),
            BatteryCellPage(
              cellvols: batpackinfo.cellvols,
              celltemps: batpackinfo.celltemps,
              balance: batpackinfo.bms_balance1,
            ),
            BmsRunningStatePage(),
          ],
        )));
  }
}
