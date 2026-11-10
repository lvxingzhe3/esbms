import 'dart:async';
import 'dart:convert';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/asyncLock.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/helper/ssli/ble_helper.dart';
import 'package:bms_app/model/batpackinfo.dart';
import 'package:bms_app/model/bmscmd.dart';
import 'package:bms_app/model/paramitem.dart';
import 'package:bms_app/network/api_extend.dart';
import 'package:bms_app/network/dio_provider.dart';
import 'package:bms_app/utils/loggerdebug_util.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:convert/convert.dart';

// 不可变状态：对外暴露可监听的字段
class BleStateData {
  final Batpackinfo batpackinfo;
  final BluetoothCharacteristic? characteristic;
  final BluetoothCharacteristic? reccharacteristic;

  const BleStateData({
    required this.batpackinfo,
    this.characteristic,
    this.reccharacteristic,
  });

  BleStateData copyWith({
    Batpackinfo? batpackinfo,
    BluetoothCharacteristic? characteristic,
    BluetoothCharacteristic? reccharacteristic,
  }) {
    return BleStateData(
      batpackinfo: batpackinfo ?? this.batpackinfo,
      characteristic: characteristic ?? this.characteristic,
      reccharacteristic: reccharacteristic ?? this.reccharacteristic,
    );
  }
}

// Riverpod Provider
final bleStateProvider =
    NotifierProvider<BleNotifier, BleStateData>(BleNotifier.new);

// Notifier：管理副作用与状态
class BleNotifier extends Notifier<BleStateData> {
  BluetoothCharacteristic? _notifychar; //
  StreamSubscription<List<int>>? _valueSubscription; // 内部订阅
  final AsyncLock _comLock = AsyncLock();
  bool _alarmFlag = false; //告警标志
  @override
  BleStateData build() {
    // 自动清理
    ref.onDispose(() async {
      await _valueSubscription?.cancel();
      _valueSubscription = null;
      _notifychar = null;
    });
    return BleStateData(batpackinfo: Batpackinfo());
  }

  Future<bool> refreshBatpackinfo() async {
    bool result = false;
    await _comLock.run(() async {
      // 这里面同一时间只会进入一次
      Batpackinfo batpackinfo = Batpackinfo();
      try {
        String devname = "--";
        if (GlobalData.DeviceConnectType == 1) {
          devname = GlobalData.currentDeviceName ?? "--";
          /************WIFI连接*************/
          if (GlobalData.currentDeviceId != null &&
              GlobalData.currentDeviceId!.isNotEmpty) {
            var apiService = ref.read(apiServiceProvider);
            var rec =
                await apiService.getdeviceBmsInfo(GlobalData.currentDeviceId!);
            var apiRes = ApiResponse.fromJson(rec);
            if (apiRes.data == null) {
              result = false;
              return;
            }
            batpackinfo.isConnected = true;

            var devjson = apiRes.data['fields'];
            bool alarmstate = false;
            //故障状态
            dynamic paramvalue = devjson['fault_status'];
            BatPackbmsinfo bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }
            batpackinfo.bms_abnormal = bmsinfo.value.toInt();

            //保护状态
            paramvalue = devjson['protection_status'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }
            batpackinfo.bms_protect = bmsinfo.value.toInt();

            //告警状态
            paramvalue = devjson['alarm_status'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            if (bmsinfo.value.toInt() > 0) {
              alarmstate = true;
            }
            batpackinfo.bms_alarm = bmsinfo.value.toInt();

            paramvalue = devjson['bms_status'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.bms_state = bmsinfo.value.toInt();

            if (devjson is Map) {
              final Map<String, dynamic> data =
                  Map<String, dynamic>.from(devjson);
              data.removeWhere(
                  (key, value) => GlobalData.secretParamList.contains(key));
              devjson = data;
            }
            _alarmFlag = alarmstate;
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

            /*
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
            */

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
            //剩余充电时间
            paramvalue = devjson['battery_remaining_charge_time'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.chg_timeuse = bmsinfo.value.toInt();

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
            //soh
            paramvalue = devjson['battery_health_state'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.soh = bmsinfo.value;

            //电池状态
            var keyjson = BatPackbmsinfo.fromJson(devjson["battery_state"]);
            batpackinfo.workstate = keyjson.valueDisplay;

            final paramrec =
                await apiService.getparamlist(GlobalData.currentDeviceId!);
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
            //batpackinfo.remaincap = bmsinfo.value.toInt();

            //单体电压
            batpackinfo.cellvols = [];
            for (int i = 0; i < batpackinfo.cellnum; i++) {
              paramvalue = devjson[
                  'battery_cell_voltage_${(i + 1).toString().padLeft(3, '0')}'];
              bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
              int index = i + 1;
              Batinfo batinfo = Batinfo(
                  index.toString().padLeft(2, '0'), bmsinfo.value / 1000);
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

            paramvalue = devjson['cell_balance_status_1'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.bms_balance1 = bmsinfo.value.toInt();

            paramvalue = devjson['software_version'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.softversion = bmsinfo.valueDisplay;

            paramvalue = devjson['hardware_version'];
            bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
            batpackinfo.hardversion = bmsinfo.valueDisplay;

            rec = await apiService.readparam(
                GlobalData.currentDeviceId!, "battery_remaining_capacity");
            apiRes = ApiResponse.fromJson(rec);
            if (apiRes.code == 0 && apiRes.data != null) {
              bmsinfo = BatPackbmsinfo.fromJson(apiRes.data);
              batpackinfo.remaincap = bmsinfo.value / 1000;
              batpackinfo.remaincap =
                  double.parse(batpackinfo.remaincap.toStringAsFixed(2));
            }

            final paramgrouprec = await apiService
                .getstatuslistgroup(GlobalData.currentDeviceId!);
            final apiparamgroupRes = ApiResponse.fromJson(paramgrouprec);
            final List<dynamic> groups =
                apiparamgroupRes.data["attributesGroups"] ?? [];
            final targetgroup = groups.firstWhere(
                (group) => group['key'] == 'battery_health_state',
                orElse: () => null);

            final attributes = targetgroup["attributes"] ?? [];
            final List<Map<String, String>> groupparams =
                attributes.map<Map<String, String>>((attr) {
              return {
                'key': attr['key']?.toString() ?? '',
                'name': attr['name']?.toString() ?? '',
              };
            }).toList();
            List<ParamItem> basicParams = [];
            for (var param in groupparams) {
              final key = param['key'];
              if (devjson.containsKey(key)) {
                dynamic paramvalue = devjson[key];
                var bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
                basicParams.add(ParamItem(
                  key: key!,
                  name: param['name'] ?? '',
                  value: bmsinfo.valueDisplay,
                  unit: bmsinfo.unit,
                ));
              }
            }
            batpackinfo.basicParams = basicParams;

            final stategroup = groups.firstWhere(
                (group) => group['key'] == 'battery_general_state',
                orElse: () => null);
            final stateAttributes = stategroup["attributes"] ?? [];
            final List<Map<String, String>> stateGroupParams =
                stateAttributes.map<Map<String, String>>((attr) {
              return {
                'key': attr['key']?.toString() ?? '',
                'name': attr['name']?.toString() ?? '',
              };
            }).toList();
            List<ParamItem> bmsstateParams = [];
            for (var param in stateGroupParams) {
              final key = param['key'];
              if (devjson.containsKey(key)) {
                dynamic paramvalue = devjson[key];
                var bmsinfo = BatPackbmsinfo.fromJson(paramvalue);
                bmsstateParams.add(ParamItem(
                  key: key!,
                  name: param['name'] ?? '',
                  value: bmsinfo.valueDisplay,
                  unit: bmsinfo.unit,
                ));
              }
            }
            batpackinfo.bmsstateParams = bmsstateParams;
          } else {
            batpackinfo.isConnected = false;
          }

          updateBmsinfo(batpackinfo);
        } else {
          /************蓝牙连接*************/
          /*
          if (BleHelper.getInstance().character_write != null) {
            String cmd = "112233";
            await BleHelper.getInstance().doSendAndWait({
              "CID": 30024,
              "PL": {
                "Req": cmd,
              }
            }, GlobalData.currentDtuId!);
          }
          */

          final writechar = state.characteristic;
          final recchar = state.reccharacteristic;
          if (writechar == null || recchar == null) {
            devname = "--";
            return;
          }

          //设备名称
          devname = writechar.device.advName;
          if (writechar.device.isConnected) {
            if (GlobalData.currentDtuId == null) {
              GlobalData.currentDtuId == await WiFiForIoTPlugin.getSSID();
            }
            if (GlobalData.currentDtuId == null) {
              String prefix = "SSL_";
              String b64 =
                  writechar.device.advName.substring(prefix.length + 1);
              List<int> ilist = base64.decode(b64).toList();
              String dtuId = hex.encode(ilist);
              GlobalData.currentDtuId = dtuId;
              // "92778608290538403832";
            }
            //电池类型查询
            List<int> data = [
              BmsCmd.cmdAddress,
              0x1d,
              0x12,
              0XA6,
            ];
            String base64Str = base64.encode(data);
            bool res = await BleHelper.getInstance().doSendByte(data);
            //电池类型查询
            String value = "1d12A5";
            Map<String, dynamic> cmd = {
              "CID": 30024,
              "PL": {"Req": value}
            };
            String? encrypted = BleHelper.getInstance()
                .cmdEncrypt(cmd, GlobalData.currentDtuId!);
            List<int> cmdbytes = encrypted!.codeUnits;

            await BleHelper.getInstance().doSendBytes2(writechar, cmdbytes);

            var rec = await sllWriteAndRead(sendBytes: data);
            print(rec);
          }

          /*
          // 监听蓝牙连接
          if (writechar.device.isConnected == false) {
            print("蓝牙断开");
            devname = "--";
            notifier.updateBmsinfo(batpackinfo);
            return;
          } else {
            batpackinfo.isConnected = true;
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
                    Batinfo("temp$index", ((recvalue - 2730) / 10).toDouble());
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
          */
        }
      } catch (e) {
        LoggerDebugUtil.e('batMinitorCheck异常', e);
      } finally {
        result = batpackinfo.isConnected;
      }
    });
    return result;
  }

  ///刷新token
  Future<void> refreshToken() async {
    try {
      var apiService = ref.read(apiServiceProvider);
      var rec = await apiService.refreshToken();
      var apiRes = ApiResponse.fromJson(rec);
      if (apiRes.code == 0 && apiRes.data != null) {
        String token = apiRes.data['accessToken'] as String;
        String refreshToken = apiRes.data['refreshToken'] as String;
        if (token.isNotEmpty) {
          GlobalData.apiAccessToken = token;
          GlobalData.apiRefreshToken = refreshToken;
        }
      }
    } finally {}
  }

  List<List<int>> doFrags(List<int> packIn) {
    List<int> pack = [];
    pack.addAll(packIn);
    List<List<int>> list = [];
    int mtu = 22 - 3;
    int idx = 1;
    // print(pack.toString());
    while (pack.length > mtu) {
      List<int> frag = [idx, 0, mtu];
      List<int> tmp = pack.getRange(0, mtu).toList();
      print(tmp.toString());
      for (int i = 0; i < tmp.length; i++) frag.add(tmp[i]);
      list.add(frag);
      // print("1 pack len="+pack.length.toString()+",mtu="+mtu.toString());
      pack.removeRange(0, mtu);
      // print("2 pack len="+pack.length.toString());
      idx++;
    }
    if (pack.length > 0) {
      List<int> frag = [idx, 0, pack.length];
      for (int i = 0; i < pack.length; i++) frag.add(pack[i]);
      list.add(frag);
    }
    int fragNum = list.length;
    for (int i = 0; i < list.length; i++) {
      list[i][1] = fragNum;
    }
    return list;
  }

  ///蓝牙发送并返回
  Future<List<int>?> writeAndRead({
    required List<int> sendBytes,
    int timeoutMs = 500,
  }) async {
    final writeChar = state.characteristic;
    final recChar = state.reccharacteristic;
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
    await writeChar.write(sendBytes, withoutResponse: false);
    return await completer.future;
  }

  String listToHex(List<int> list) {
    return list.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  ///蓝牙发送并返回
  Future<List<int>?> sllWriteAndRead({
    required List<int> sendBytes,
    int timeoutMs = 500,
  }) async {
    try {
      final writeChar = state.characteristic;
      final recChar = state.reccharacteristic;
      if (writeChar == null || recChar == null) return null;
      if (GlobalData.currentDtuId == null) {
        String prefix = "SSL_";
        String b64 = writeChar.device.advName.substring(prefix.length + 1);
        List<int> ilist = base64.decode(b64).toList();
        String dtuId = hex.encode(ilist);
        GlobalData.currentDtuId = dtuId;
      }
      String value = listToHex(sendBytes);
      Map<String, dynamic> cmd = {
        "CID": 30024,
        "PL": {"Req": value}
      };
      String? encrypted =
          BleHelper.getInstance().cmdEncrypt(cmd, GlobalData.currentDtuId!);
      List<int> cmdbytes = encrypted!.codeUnits;

      List<List<int>> frags = doFrags(cmdbytes);
      if (frags.isNotEmpty) {
        //List<int> sendData = frags[0];
        final completer = Completer<List<int>>();
        late StreamSubscription sub;
        sub = recChar.onValueReceived.listen((data) {
          completer.complete(data);
          sub.cancel();
          List<int> recdata = data.sublist(3);
          String str = utf8.decode(recdata);
          var decStr =
              BleHelper.getInstance().cmdDecrypt(str, GlobalData.currentDtuId!);
          if (decStr != null && decStr.isNotEmpty) {
            final map = json.decode(decStr) as Map<String, dynamic>;
            String rsp = map['PL']['Rsp'];
            if (rsp.isNotEmpty) {
              var arr = hexToList(rsp);
            }
            print(decStr);
          }
        });
        // 超时
        Future.delayed(Duration(milliseconds: timeoutMs), () {
          if (!completer.isCompleted) {
            sub.cancel();
            print('writeAndRead timeout error');
            return null;
          }
        });
        for (int i = 0; i < frags.length; i++) {
          List<int> frag = frags[i];
          // 下发命令
          await writeChar.write(frag, withoutResponse: false);
        }

        return await completer.future;
      }
    } catch (e) {
      return null;
    }
  }

  //更新batpackinfo
  void updateBmsinfo(Batpackinfo batinfo) {
    state = state.copyWith(batpackinfo: batinfo);
  }

  // 初始化/设置蓝牙 Characteristic
  Future<void> setCharacteristic(
    BluetoothCharacteristic? characteristic,
    BluetoothCharacteristic? readchar, [
    BluetoothDevice? device,
  ]) async {
    _notifychar = readchar;
    state = state.copyWith(
        characteristic: characteristic, reccharacteristic: readchar);

    if (characteristic != null) {
      //|| !readchar.properties.notify
      if (readchar == null) return;

      // 蓝牙数据接收
      final subscription = await asyncValueListener();
      // 蓝牙设备断开时停止监听
      device?.cancelWhenDisconnected(subscription);
      await Future.delayed(Duration(milliseconds: 100));
      // 设置 characteristic 通知
      await _notifychar!.setNotifyValue(true);
    } else {
      // 重置
      await _valueSubscription?.cancel();
      _valueSubscription = null;
      state = state.copyWith(
        characteristic: null,
        batpackinfo: Batpackinfo(),
      );
    }
  }

  // 解析 json 数据
  void decodeJson(
    List<int> value, [
    Function(BleValueStatus, List<int>)? callback,
  ]) {
    try {
      callback?.call(BleValueStatus.Receiving, value);
      if (value.isEmpty) return;
    } catch (e) {
      print(e);
      callback?.call(BleValueStatus.Error, value);
      return;
    }
  }

  // 监听蓝牙 value
  Future<StreamSubscription<List<int>>> asyncValueListener([
    Function(BleValueStatus, List<int>)? callback,
  ]) async {
    final subscription = _notifychar!.onValueReceived.listen((value) {
      decodeJson(value, callback);
      List<int> data = value.sublist(3);
      String str = utf8.decode(data);
      var decStr =
          BleHelper.getInstance().cmdDecrypt(str, GlobalData.currentDtuId!);
      if (decStr != null && decStr.isNotEmpty) {
        final map = json.decode(decStr) as Map<String, dynamic>;
        String rsp = map['PL']['Rsp'];
        if (rsp.isNotEmpty) {
          var arr = hexToList(rsp);
        }
        print(decStr);
      }

      /*
     
      // 发送蓝牙全局事件
      eventBus.fire(
        BleDataEvent(
          data: value,
          deviceId: _notifychar!.device.remoteId.toString(), 
        ),
      );
      */
    });
    _valueSubscription = subscription;
    return subscription;
  }
}

enum BleValueStatus { Error, Started, Ended, Receiving }
