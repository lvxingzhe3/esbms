import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/ssli/ble_helper.dart';
import 'package:bms_app/helper/topsnackbar.dart';
import 'package:bms_app/ui/page/wifi/my_scaffold.dart';
import 'package:bms_app/ui/page/wifi/page_wifi_config.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:sise_solar/ui/page/ble_add_dev/page_near_dtu_config.dart';
//import 'package:sise_solar/ui/page/wifi_config/page_diagnose.dart';
//import 'package:sise_solar/ui/page/wifi_config/page_dtu_config_help.dart';
//import 'package:sise_solar/ui/page/wifi_config/page_wifi_config.dart';
import 'package:wifi_iot/wifi_iot.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:bms_app/helper/ssli/prof.dart';
import 'package:bms_app/helper/ssli/wifi_config.dart';
//import '../../ui_config.dart';
//import '../../widget_helper.dart';
import 'dart:io';
import 'package:bms_app/generated/l10n.dart' as lan;

class PageWConfigFind extends StatefulWidget {
  final String? _dtuId;
  final bool? _near;
  const PageWConfigFind({super.key, dtuId, near = false})
      : _dtuId = dtuId,
        _near = near;

  @override
  State<PageWConfigFind> createState() => _PageWConfigFindState();
}

class _PageWConfigFindState extends State<PageWConfigFind>
    with WidgetsBindingObserver {
  String _radarState = "stop";
  List<_FindDevice> deviceList = [];
  _FlyingCard? _flyingCard;
  String? ssidRouter;
  bool connectModel = false;
  Timer? wifiStateTimer;
  String? _apConnectedDtuId;
  BuildContext? buildContext;
  List<double> maxHeight = [0.0];
  //是否wifi模块
  bool _isSoftAP(String? ssid) {
    if (ssid == null) return false;
    if (ssid.indexOf(Prof.instance.prefixSSID) == 0 &&
        ssid.length - Prof.instance.prefixSSID.length == 20) {
      return true;
    } else {
      return false;
    }
  }

  bool _timeCancel = false;
  // wifi检查
  Future<void> wifi_check() async {
    while (_timeCancel == false) {
      await Future.delayed(const Duration(seconds: 2));
      if (await WiFiForIoTPlugin.isConnected()) {
        String? tmp = await WiFiForIoTPlugin.getSSID();
        if (tmp != null && !_isSoftAP(tmp)) {
          ssidRouter = tmp;
        }
        if (_isSoftAP(tmp)) {
          //获取dtuId
          String dtuId = tmp!.substring(Prof.instance.prefixSSID.length);
          if (widget._dtuId == null ||
              (widget._dtuId != null && widget._dtuId == dtuId)) {
            if (_apConnectedDtuId != dtuId) {
              print("ap dtuid:" + dtuId);
              _apConnectedDtuId = dtuId;
              WiFiConfig.instance.apConnected(dtuId);
              _FindDevice? _dev = findList(dtuId);
              if (_dev == null) {
                _dev = _FindDevice(dtuId, "", "", false, null);
                _dev.apConnected = true;
                if (widget._dtuId != null && widget._dtuId == dtuId)
                  _dev.forDiagnose = true;
                _flyingCard?.addDevice(_dev);
              }
              _flyingCard?.apConnected(dtuId);
            }
          }
        } else if (_apConnectedDtuId != null) {
          _apConnectedDtuId = null;
          _flyingCard?.apConnected(null);
        }
      } else {
        _apConnectedDtuId = null;
        _flyingCard?.apConnected(null);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("-didChangeAppLifecycleState-" + state.toString());
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假    设它们可能在任何时候暂停。
        print('这是冷启动');
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见
        print('这是resumed');
        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        print('这是paused');
        break;
      case AppLifecycleState.detached: // APP结束时调用
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    print("WConfigFind initState");
    _radarState = "start";
    // Wi-Fi配网时需要这个权限（否则读取不到Wi-Fi信息）
    Future.delayed(Duration.zero, () async {
      var status;
      // 先检查定位总开关是否开启
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("定位服务总开关关闭");
      }

      status = await Geolocator.checkPermission();
      print("当前定位权限：$status");

      if (status == LocationPermission.whileInUse ||
          status == LocationPermission.always) {
        // 已经授权，可以获取位置
        checkLocationService2();
      } else if (status == LocationPermission.denied) {
        // 可以发起申请
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          checkLocationService2();
        } else if (permission == LocationPermission.deniedForever) {
          // 用户永久拒绝，无法再次弹窗，跳转设置
          await Geolocator.openAppSettings();
        }
      } else if (status == LocationPermission.deniedForever) {
        // 永久拒绝，直接跳设置
        await Geolocator.openAppSettings();
      }
      /*
      status = await Permission.location.status;
      if (status == PermissionStatus.granted) {
        checkLocationService2();
      } else {
        //未授权则发起一次申请
        print("location permission status:$status");
        await Permission.location.request();
        status = await Permission.location.status;
      }
      */
      if (!(status == LocationPermission.whileInUse ||
          status == LocationPermission.always)) {
        if (!mounted) return false;
        if (Platform.isAndroid) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: AppColor.backgroud,
                  title: Text(
                    lan.S.of(context).no_location_permission /*"没有定位权限"*/,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(lan.S.of(context).not_yet)),
                    TextButton(
                        onPressed: () {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.settings);
                          Navigator.of(context).pop();
                        },
                        child: Text(lan.S.of(context).go_open)),
                  ],
                );
              });
          if (!mounted) return false;
          Navigator.of(context).pop();
          return false;
        }
      }
      if (!mounted) return false;
      if (status != PermissionStatus.permanentlyDenied &&
          status != PermissionStatus.denied) {
        WidgetsBinding.instance.addObserver(this);
        //检查WIFI
        wifi_check();
        //初始化
        WiFiConfig.instance
            .doInit(diagnose: widget._dtuId != null, dtuId: widget._dtuId);
        //监听蓝牙状态
        WiFiConfig.instance.streamBleState().listen((state) {
          if (state == false) {
            print("请打开手机蓝牙!");
          }
        });
        //搜索设备
        WiFiConfig.instance.streamSearchDevice().listen((event) {
          print("WConfigFind initState112" + '$event');
          if (event == "ble") {
            _deviceAdd();
          } else if (event.indexOf("ap") == 0) {
            _deviceAdd();
          }
        });
      }
    });
  }

  bool _deviceAddWorking = false;
  Future<void> _deviceAdd() async {
    if (_deviceAddWorking == true) return;
    _deviceAddWorking = true;
    List<DtuCfg> founded = WiFiConfig.instance.foundDtus;
    int foundLen = founded.length;
    while (founded.length > deviceList.length) {
      print("_deviceAdd while");
      for (int i = 0; i < founded.length; i++) {
        print("_deviceAdd for i=" + i.toString());
        DtuCfg dtuCfg = founded[i];
        _FindDevice? dev = findList(dtuCfg.dtuId);
        if (deviceList.length == 5 && mounted) setState(() {});
        if (widget._dtuId != null && widget._dtuId == dtuCfg.dtuId ||
            widget._dtuId == null) {
          if (dev == null) {
            _FindDevice _newDevice = _FindDevice(dtuCfg.dtuId, "", "",
                dtuCfg.bleEnable == 1 ? true : false, dtuCfg.rssi);
            if (dtuCfg.ipAddress != null) {
              _newDevice.staConnected = true;
            }
            if (widget._dtuId != null && widget._dtuId == dtuCfg.dtuId)
              _newDevice.forDiagnose = true;
            if (dtuCfg.state != null && dtuCfg.state! > 3)
              _newDevice.is4G = true;
            deviceList.add(_newDevice);
            if (_flyingCard != null) {
              // if(widget._isWifi){
              //   if(!_newDevice.is4G){
              //     _flyingCard!.addDevice(_newDevice);
              //   }
              // }else{
              //   _flyingCard!.addDevice(_newDevice);
              // }
              if (_newDevice.is4G) {
                if (widget._dtuId != null || widget._near == true)
                  _flyingCard!.addDevice(_newDevice);
              } else {
                _flyingCard!.addDevice(_newDevice);
              }
              await Future.delayed(Duration(milliseconds: 300));
            }
          } else {
            if (dev.rssi != null && dev.rssi! < dtuCfg.rssi) {
              if (_flyingCard != null) {
                if (dev.is4G) {
                  if (widget._dtuId != null || widget._near == true)
                    _flyingCard!.update(dev);
                } else {
                  _flyingCard!.update(dev);
                }
              }
            }
          }
        }
      }
      founded = WiFiConfig.instance.foundDtus;
      if (foundLen == founded.length) {
        break;
      } else {
        foundLen = founded.length;
      }
    }
    print("_deviceAdd while end");
    _deviceAddWorking = false;
  }

  _FindDevice? findList(String dtuId) {
    for (int i = 0; i < deviceList.length; i++) {
      if (deviceList[i].dtuId == dtuId) {
        return deviceList[i];
      }
    }
    return null;
  }

  @override
  void dispose() {
    print("WConfigFind dispose");
    // wifiStateTimer?.cancel();
    _timeCancel = true;
    WidgetsBinding.instance.removeObserver(this);
    WiFiConfig.instance.doStop();
    super.dispose();
  }

  List<Widget> showStack() {
    List<Widget> list = [];
    list.add(
      Container(
        width: double.infinity,
        height: double.infinity,
        child: _SearchingRadar(
          state: _radarState,
        ),
      ),
    );
    if (_flyingCard != null) {
      list.add(_flyingCard!);
    }
    return list;
  }

  void doUpdate() {
    WiFiConfig.instance.foundDtus.clear();
    deviceList.clear();
    _apConnectedDtuId = null;
    if (mounted) setState(() {});
  }

  ///==========================
  Future<void> checkLocationService2() async {
    print("checkLocationService invoked");
    if (Platform.isAndroid) {
      bool serviceEnabled = true;
      try {
        await Geolocator.getCurrentPosition(
            forceAndroidLocationManager: true); //有些手机会在此卡住很久
      } catch (e) {
        serviceEnabled = false;
      }
      print("serviceEnabled:${serviceEnabled}");
      if (!serviceEnabled) {
        await _showPermissionLocationDeniedDialog();
      }
    } else if (Platform.isIOS) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showPermissionLocationDeniedDialog();
      }
    }
  }

  Future<void> _showPermissionLocationDeniedDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // 禁止左滑手势关闭对话框，直接返回false
            return false;
          },
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min, // 设置为min
              children: [
                Image.asset(
                  true //中文
                      ? 'assets/images/location_zh.jpg'
                      : 'assets/images/location_en.jpg', // 本地图片路径
                  fit: BoxFit.cover, // 图片填充方式
                  height: 200,
                  alignment: Alignment.topCenter,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  lan.S.of(context).need_location_services /*"需开启系统定位服务开关"*/,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  lan.S.of(context).find_nearby_devices /*"查找周边设备"*/,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            contentPadding:
                EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0), // 调整内容内边距
            actions: <Widget>[
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 主轴居中
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // 关闭对话框并返回上一个页面
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(horizontal: 24.0), // 调整水平内边距
                          ),
                        ),
                        child: Text(lan.S.of(context).cancel /*"取消"*/),
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 关闭对话框并跳转到系统设置中的定位服务设置页面
                          Navigator.of(context).pop();
                          AppSettings.openAppSettings(
                              type: AppSettingsType.location);
                          Navigator.of(context).pop();
                        },
                        child: Text(lan.S.of(context).go_open /*"去开启"*/),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Center(
                    child: Text(
                      "请以实际页面为准",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
    return;
  }

  ///==========================

  @override
  Widget build(BuildContext context) {
    buildContext = context;
    return MyScaffold(
      appBar: AppBar(
        title: GlobalData.DeviceConnectType == 0
            ? customTitleText(lan.S.of(context).deviceList)
            : customTitleText(lan.S.of(context).bluewifi),
        centerTitle: true,
        backgroundColor: Colors.transparent, // AppBar 透明
        elevation: 0, // 移除底部阴影，否则会有灰色分层
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // print("height:"+constraints.maxHeight.toStringAsFixed(2));
          maxHeight[0] = constraints.maxHeight;
          _flyingCard ??= _FlyingCard(
            height: maxHeight,
            width: constraints.maxWidth,
            doUpdate: () {
              doUpdate();
            },
            isDoAnimate: deviceList.length <= 5 ? true : false,
            near: widget._near,
          );
          return Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: showStack(),
              ));
        },
      ),
    );
  }
}

class _FlyingCard extends StatefulWidget {
  String? _lastSSID;
  List<double> _height;
  double _width;
  bool isDoAnimate;
  Function() _doUpdate;
  bool? _near;
  _FlyingCard(
      {super.key,
      required height,
      required width,
      lastSSID,
      required Function() doUpdate,
      required this.isDoAnimate,
      required near})
      : this._height = height,
        this._width = width,
        this._lastSSID = lastSSID,
        this._doUpdate = doUpdate,
        this._near = near;
  _FlyingCardState _state = _FlyingCardState();

  void addDevice(_FindDevice _dev) {
    _state.addDevice(_dev);
  }

  void apConnected(String? dtuId) {
    _state.apConnected(dtuId);
  }

  void update(_FindDevice _dev) {
    _state.update(_dev);
  }

  @override
  State<_FlyingCard> createState() => _state;
}

class _FlyingCardState extends State<_FlyingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;
  List<_FindDevice> _devices = [];
  String? _msg;

  void addDevice(_FindDevice _dev) {
    print("addDevice:" +
        widget._height[0].toStringAsFixed(2) +
        "," +
        widget._width.toStringAsFixed(2));
    double _end = 10.0 + (10 + 90) * _devices.length;
    _dev.nowPos = widget._height[0] - 110;
    _dev.desPos = _end;
    _devices.add(_dev);
  }

  bool apConnected(String? dtuId) {
    bool find = false;
    for (int i = 0; i < _devices.length; i++) {
      _FindDevice dev = _devices[i];
      if (dtuId != null && dev.dtuId == dtuId) {
        dev.apConnected = true;
        find = true;
      } else {
        dev.apConnected = false;
      }
    }
    if (mounted) setState(() {});
    return find;
  }

  void update(_FindDevice device) {
    for (int i = 0; i < _devices.length; i++) {
      _FindDevice dev = _devices[i];
      if (dev.dtuId == device.dtuId) {
        dev.rssi = device.rssi;
        dev.staConnected = device.staConnected;
        dev.is4G = device.is4G;
        break;
      }
    }
    if (mounted) setState(() {});
  }

  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isDoAnimate) return;
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: 1).animate(_ctrl)
      ..addListener(() {
        if (_animation.value - _oldValue > 0.003 ||
            _animation.value < _oldValue) {
          // print("animation value="+_animation.value.toStringAsFixed(2));
          _oldValue = _animation.value;
          for (int i = 0; i < _devices.length; i++) {
            _FindDevice dev = _devices[i];
            double tmp = dev.nowPos - 10;
            if (tmp < dev.desPos) {
              tmp = dev.desPos;
            }
            dev.nowPos = tmp;
          }
          if (mounted) setState(() {});
        }
      });
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget showCard(_FindDevice dev) {
    return _devices.length <= 5
        ? buildBody(dev)
        : Padding(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
            child: buildBody(dev),
          );
  }

  Widget buildBody(_FindDevice dev) {
    String rssi = (dev.bleEnable
        ? (dev.rssi == null ? "--" : dev.rssi.toString())
        : (dev.apConnected || dev.staConnected)
            ? "--"
            : (dev.rssi == null ? "--" : dev.rssi.toString()));
    String svg = "assets/信号0.svg";
    try {
      int x = int.parse(rssi);
      if (x <= -100) svg = "assets/信号0.svg";
      if (-100 < x && x <= -88) svg = "assets/信号1.svg";
      if (-88 < x && x <= -77) svg = "assets/信号2.svg";
      if (-77 < x && x <= -55) svg = "assets/信号3.svg";
      if (-55 < x) svg = "assets/信号4.svg";
    } catch (e) {
      rssi = "--";
    }
    return Container(
      width: widget._width,
      /* height: 90, */ color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          if (dev.forDiagnose == false) {
            /*
            if (GlobalData.DeviceConnectType == 0) {
              BleHelper.getInstance().doStop();
              Future.delayed(Duration(milliseconds: 100));
              WiFiConfig.instance
                  .streamSetDtuIdWithBleConnect(dev.dtuId)
                  .listen((event) {
                if (mounted) {
                  setState(() async {
                    if (event == "connect") {
                      //GlobalData.currentDeviceName = dev.devSN;
                      GlobalData.currentDtuId = dev.dtuId;
                      /*
                      String? encrypted = BleHelper.getInstance()
                          .cmdEncrypt(cmd, GlobalData.currentDtuId!);
                          */
                      String cmd = "8888";
                      await BleHelper.getInstance().doSendAndWait({
                        "CID": 30024,
                        "PL": {
                          "Req": cmd,
                        }
                      }, GlobalData.currentDtuId!);
                      Navigator.pop(context);
                    } else if (event == "disconn") {
                      TopSnackBar.show(
                        context,
                        S.of(context).bloothconntedfail,
                        backgroundColor: AppColor.warn,
                        icon: Icons.check_circle,
                        duration: Duration(seconds: 2),
                      );
                    } else if (event == "fault") {
                      TopSnackBar.show(
                        context,
                        S.of(context).bloothconntedfail,
                        backgroundColor: AppColor.warn,
                        icon: Icons.check_circle,
                        duration: Duration(seconds: 2),
                      );
                    } else if (event == "connecting") {}
                  });
                }
              });
            } 
            */
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return PageWiFiConfig(
                dtuId: dev.dtuId,
                wifiConnected:
                    (dev.staConnected || dev.apConnected) ? true : false,
                lastConnected: widget._lastSSID,
                is4G: dev.is4G,
              );
            })).then((value) {
              if (value == true) {
                Navigator.of(context).pop();
              } else {
                _devices.clear();
                widget._doUpdate();
              }
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Card(
            shadowColor: Colors.transparent,
            color: const Color.fromARGB(255, 2, 21, 53).withValues(alpha: 0.8),
            child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: Icon(
                          Icons.devices,
                          size: 30,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    /*
                    SvgPicture.asset(
                      "assets/fronus/shebei21.svg",
                      height: 60,
                      width: 60,
                      color: Colors.white54,
                    ),
                    */
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "ID: ",
                              ),
                              Text(
                                dev.dtuId,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                dev.bleEnable
                                    ? "Bluetooth"
                                    : (dev.apConnected || dev.staConnected)
                                        ? "WiFi connected"
                                        : "unconnected",
                              ),
                            ],
                          ),
                          (rssi == "--")
                              ? Text("信号强度：" + "--")
                              : SvgPicture.asset(
                                  svg,
                                  height: 24,
                                )
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 28,
                      color: Colors.white30,
                    )
                  ],
                )),
          ),
        ),
      ),
    );
  }

  List<Widget> showDevices() {
    List<Widget> list = [];
    for (int i = 0; i < _devices.length; i++) {
      _FindDevice dev = _devices[i];
      // print("index="+i.toString()+",ani value="+dev.nowPos.toStringAsFixed(2));
      list.add(_devices.length <= 5
          ? Positioned(
              top: dev.nowPos, left: 10, right: 10, child: showCard(dev))
          : showCard(dev));
    }
    /*
    list.add(_devices.length <= 5
        ? Positioned(bottom: 30, left: 10, right: 10, child: showBody())
        : showBody());
        */
    return list;
  }

  Widget showBody() {
    return Container(
      width: widget._width,
      color: Colors.transparent,
      child: Column(
        children: widget._near == false
            ? [
                Text(_msg ?? "正在搜索设备......"),
                Text(
                  "如果设备不支持蓝牙，请通过Wi-Fi",
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text(S.of(context).info_not_support_ble_1/*"如果设备不支持蓝牙，请通过Wi-Fi"*/, style: SSLi.textStyleLittleWithColor("whitec0"),),
                    // SizedBox(width: 5,),
                    SizedBox(
                      height: 28,
                      child: TextButton(
                        onPressed: () {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.wifi);
                        },
                        child: Text(
                          lan.S.of(context).connect /*"连接"*/,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "数采器AP。",
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Text("数采器AP名称为: "),
              ]
            : [
                Text(
                  _msg ?? lan.S.of(context).cancel /*"正在搜索设备......"*/,
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget._width,
      height: widget._height[0],
      color: Colors.transparent,
      child: _devices.length <= 5
          ? Stack(children: showDevices())
          : ListView(children: showDevices()),
    );
  }
}

class _SearchingRadar extends StatefulWidget {
  String _state;
  _SearchingRadar({super.key, String state = "stop"}) : this._state = state;

  @override
  State<_SearchingRadar> createState() => _SearchingRadarState();
}

class _SearchingRadarState extends State<_SearchingRadar>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  // String _searchingState= "start";

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _ctrl!.repeat();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SearchingRadarPaint(_ctrl!, widget._state),
    );
  }
}

class _SearchingRadarPaint extends CustomPainter {
  Animation<double> animation;
  String state;
  _SearchingRadarPaint(this.animation, this.state) : super(repaint: animation);

  List<_RadarPoint> _radars = [];

  double _oldAnimValue = 0.0;
  void getRadars(double animValue) {
    if (state == "start") {
      // print(""+animValue.toStringAsFixed(2));
      if (animValue - _oldAnimValue > 0.03 || animValue < _oldAnimValue) {
        if (animValue < _oldAnimValue) {
          _radars.add(_RadarPoint(0.0, 0.5));
        }
        _oldAnimValue = animValue;
        // print("_radars num:"+_radars.length.toString());
        for (int i = 0; i < _radars.length; i++) {
          _RadarPoint p = _radars[i];
          p.radius += 5;
          p.opacity -= 0.003;
        }
      }
    } else if (state == "stop") {
      _radars.clear();
    } else if (state == "pause") {}
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print("paint");
    getRadars(animation.value);
    canvas.translate(size.width / 2, 0);
    for (int i = 0; i < _radars.length; i++) {
      _RadarPoint p = _radars[i];
      if (p.opacity > 0) {
        Paint paint = Paint()
          ..color = const Color(0xff40a0ff).withOpacity(p.opacity)
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;
        Path path = Path()
          ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: p.radius));
        canvas.drawPath(path, paint);
      } else {
        _radars.removeAt(i);
        i--;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SearchingRadarPaint oldDelegate) =>
      oldDelegate.animation != animation;
}

class _RadarPoint {
  double radius;
  double opacity;
  _RadarPoint(this.radius, this.opacity);
}

class _FindDevice {
  String dtuId;
  bool bleEnable;
  bool apConnected = false; // 手机主动连接，
  bool staConnected = false; // 模块连接手机热点
  int? rssi;
  bool forDiagnose = false;
  bool is4G = false;

  String devSN;
  String devType;
  double nowPos = 0;
  double desPos = 0;

  _FindDevice(this.dtuId, this.devSN, this.devType, this.bleEnable, this.rssi);
}
