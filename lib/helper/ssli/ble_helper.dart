import 'dart:convert';
import 'dart:io';
//import 'package:bluetooth_manager/bluetooth_manager.dart';
//import 'package:bluetooth_manager/models/bluetooth_models.dart' as bleMan;
import 'package:bms_app/helper/ssli/aes_helper.dart';
import 'package:bms_app/helper/ssli/udp_helper.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bms_app/helper/ssli/eutil.dart';
import 'package:bms_app/helper/ssli/wifi_config.dart';
import 'package:synchronized/synchronized.dart';
import 'dart:async';

class BleHelper {
  static BleHelper? _instance;
  // 私有的命名构造函数
  BleHelper._internal();
  static BleHelper getInstance() {
    if (_instance == null) {
      _instance = BleHelper._internal();
    }
    return _instance!;
  }

  final int STATE_UNCONNECT = 0;
  final int STATE_CONNECTINT = 1;
  List<int>? _aesKeyBytes;
  // FlutterBluePlus flutterBlue= FlutterBluePlus.instance;
  BleHelperState connectState = BleHelperState.unconnect;

  Timer? scanTimer;
  StreamSubscription? bleScanListen;

  StreamSubscription<BluetoothAdapterState>? bleStateListen;
  Function(BleHelperEvent event)? _callback;
  // set callback(Function(BleHelperEvent event)? callback){_callback=callback;}
  // BluetoothState oldState= BluetoothState.unknown;

  bool _bleStateOn = true;
  void doInit({Function(BleHelperEvent event)? callback}) {
    _callback = callback;
    bleStateListen?.cancel();
    // 监听蓝牙适配器状态
    bleStateListen =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (_callback != null) {
        if (state == BluetoothAdapterState.on) {
          _bleStateOn = true;
          _callback!(BleHelperEvent(type: "state", data: "ok"));
        } else {
          _bleStateOn = false;
          _callback!(BleHelperEvent(type: "state", data: "nok"));
        }
      }
    });
    doStartScanProcess();
  }

  Future<void> stateListen() async {
    await for (BluetoothAdapterState state in FlutterBluePlus.adapterState) {
      if (_callback != null) {
        if (state == BluetoothAdapterState.on) {
          _callback!(BleHelperEvent(type: "state", data: "ok"));
        } else {
          _callback!(BleHelperEvent(type: "state", data: "nok"));
        }
      }
    }
  }

  void doStop() async {
    bleStateListen?.cancel();
    await doDisconnect();
    await doStopScan();
  }

  void doStopWithoutDisconnect() async {
    bleStateListen?.cancel();
    // await doDisconnect();
    await doStopScan();
  }

  Future<void> scanListen() async {
    await for (List<ScanResult> results in FlutterBluePlus.scanResults) {
      for (ScanResult r in results) {
        if (_callback != null) {
          _callback!(BleHelperEvent(
              type: "scan",
              data: BleDevice(
                  name: r.device.platformName,
                  rssi: r.rssi,
                  device: r.device,
                  data: r.advertisementData)));
        }
      }
    }
  }

  void doStartScanProcess() {
    scanPaused = false;
    bleScanListen?.cancel();
    scanListen();
    // bleScanListen= flutterBlue.scanResults.listen((results) {
    //   // do something with scan results
    //   for (ScanResult r in results) {
    //     if (_callback!=null){
    //       _callback!(BleHelperEvent(type: "scan", data: BleDevice(name: r.device.name, rssi: r.rssi, device: r.device, data: r.advertisementData)));
    //     }
    //   }
    // });
    if (scanTimer == null) {
      doScan(8);
      scanTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        doScan(8);
      });
    }
  }

  void doStopScanProcess() {
    scanTimer?.cancel();
    scanTimer = null;
  }

  bool scanPaused = true;
  void doScan(int sec) {
    if (scanPaused == true) return;
    if (_bleStateOn == true) {
      print("doScan");
      FlutterBluePlus.startScan(timeout: Duration(seconds: sec));
    }
  }

  Future<void> doStopScan() async {
    doStopScanProcess();
    bleScanListen?.cancel();
    await FlutterBluePlus.stopScan();
  }

  Future<void> doPauseScan() async {
    scanPaused = true;
    await FlutterBluePlus.stopScan();
  }

  void doResumeScan() {
    scanPaused = false;
  }

  void mtuRequest() async {
    try {
      var mtu = await _dtuCfgConn!.bleDevice!.mtu.first;
      if (Platform.isAndroid) {
        await _dtuCfgConn!.bleDevice!.requestMtu(240);
        mtu = await _dtuCfgConn!.bleDevice!.mtu.first;
      }
      bleMtu = mtu.toInt();
      print("bleMtu:" + bleMtu.toString());
    } on Exception {}
  }

  // BluetoothDevice? _devConn;
  DtuCfg? _dtuCfgConn;
  String UUID_SERVICE = '0000fee7-0000-1000-8000-00805f9b34fb';
  String UUID_READ = '0000fed6-0000-1000-8000-00805f9b34fb';
  String UUID_WRITE = '0000fed5-0000-1000-8000-00805f9b34fb';
  BluetoothCharacteristic? character_write;

  int? bleMtu;
  StreamSubscription<BluetoothConnectionState>? bleDeviceListen;
  StreamSubscription? recvListen;

  String doConnect(DtuCfg? dtuCfg) {
    if (dtuCfg == null || dtuCfg.bleEnable == 0 || dtuCfg.bleDevice == null)
      return "disconn";
    if (connectState == BleHelperState.connected && dtuCfg == _dtuCfgConn)
      return "connect";
    if (connectState == BleHelperState.unconnect) {
      doPauseScan();
      bleMtu = null;
      connectState = BleHelperState.connecting;
      _dtuCfgConn = dtuCfg;
      if (_dtuCfgConn!.bleDevice != null) {
        bleDeviceListen?.cancel();
        bleDeviceListen =
            _dtuCfgConn!.bleDevice!.connectionState.listen((state) async {
          print("state:$state");
          if (state == BluetoothConnectionState.connected) {
            // var mtu= await _dtuCfgConn!.bleDevice!.mtu.first;
            // if (Platform.isAndroid){
            //   await _dtuCfgConn!.bleDevice!.requestMtu(512);
            //   mtu= await _dtuCfgConn!.bleDevice!.mtu.first;
            // }
            // bleMtu= mtu.toInt();
            // print("bleMtu:"+bleMtu.toString());
            // mtuRequest();
            List<BluetoothService>? services;
            try {
              services = await _dtuCfgConn!.bleDevice!.discoverServices();
            } catch (e) {
              print("e:$e");
            }
            if (services != null) {
              bool readReady = false, writeReady = false;
              services.forEach((service) {
                if (service.uuid.str128 == UUID_SERVICE) {
                  print("service:" + service.uuid.str128);
                  service.characteristics.forEach((character) async {
                    print("character:" + character.uuid.str128);
                    if (character.uuid.str128.compareTo(UUID_READ) == 0) {
                      readReady = true;
                      character.setNotifyValue(true);
                      List<int> recvPack = [];
                      recvListen = character.lastValueStream.listen((value) {
                        print("bleMtu:${bleMtu}");
                        print("recv:${value.length}");
                        if (value.length > 21 && value.length > (bleMtu ?? 0))
                          bleMtu = value.length;
                        print("bleMtu:${bleMtu}");
                        print(value.toHexString());
                        if (value.length >= 3 &&
                            value[0] >= 1 &&
                            value[0] <= value[1]) {
                          if (value[0] == 1) {
                            recvPack = [];
                          }
                          if (value[2] == value.length - 3) {
                            for (int i = 3; i < value.length; i++) {
                              recvPack.add(value[i]);
                            }
                            print("1 recvPack:" + recvPack.toHexString());
                          } else {
                            print("v2=" +
                                value[2].toString() +
                                ",len=" +
                                value.length.toString());
                          }
                          if (value[0] == value[1]) {
                            if (_callback != null) {
                              print(
                                  "recvPack.toHexString():${recvPack.toHexString()}");
                              _callback!(BleHelperEvent(
                                  type: "recv",
                                  data: String.fromCharCodes(recvPack)));
                            }
                          }
                        }
                      });
                    }
                    if (character.uuid.str128.compareTo(UUID_WRITE) == 0) {
                      character_write = character;
                      writeReady = true;
                    }
                  });
                }
              });
              if (readReady == true && writeReady == true) {
                // mtuRequest();
                Future.delayed(Duration(milliseconds: 100), () {
                  connectState = BleHelperState.connected;
                  if (_callback != null) {
                    _callback!(BleHelperEvent(type: "connect", data: null));
                  }
                });
              }
            }
          } else if (state == BluetoothConnectionState.disconnected) {
            // 重连
            print("re-connect");
            if (_callback != null) {
              _callback!(BleHelperEvent(type: "disconn", data: null));
            }
            connectState = BleHelperState.unconnect;
            recvListen?.cancel();
            _doConnect();
            if (_callback != null) {
              _callback!(BleHelperEvent(type: "connecting", data: null));
            }
          }
        });
      }
    } else {
      print("connecting:" + connectState.toString());
      doDisconnect();
      _dtuCfgConn = dtuCfg;
    }
    return "connecting";
  }

  void _doConnect() {
    Future.delayed(Duration(seconds: 1), () {
      _dtuCfgConn?.bleDevice
          ?.connect(
            autoConnect: false,
            timeout: const Duration(seconds: 20),
            license: License.nonprofit, // <- 加上这一行
          )
          .catchError((e) {});
    });
  }

  Future<void> doDisconnect() async {
    doResumeScan();
    var tmp = _dtuCfgConn;
    _dtuCfgConn = null;
    await tmp?.bleDevice?.disconnect();
    _isSending = false; //避免doSend函数被卡死
    connectState = BleHelperState.unconnect;
    recvListen?.cancel();
  }

  var lock = new Lock();
  List<List<int>> doFrags(List<int> packIn) {
    List<int> pack = [];
    pack.addAll(packIn);
    List<List<int>> list = [];
    int mtu = (bleMtu ?? 21) - 3;
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

  Future<bool> doSendBytes(List<int> sendData) async {
    print("doSend 1");
    String str = "";
    for (int i = 0; i < sendData.length; i++) {
      str = str + sendData[i].toRadixString(16).padLeft(2, "0") + " ";
    }
    print("data:" + str);
    if (connectState == BleHelperState.connected) {
      print("doSend 2");
      if (character_write != null) {
        print("doSend 3");
        List<List<int>> frags = doFrags(sendData);
        print("doSend 4:" + frags.length.toString());
        for (int i = 0; i < frags.length; i++) {
          List<int> frag = frags[i];
          str = "";
          for (int i = 0; i < frag.length; i++) {
            str = str + frag[i].toRadixString(16).padLeft(2, "0") + " ";
          }
          print("frag:" + str);
          Future<bool> timeOut =
              Future<bool>.delayed(const Duration(seconds: 2), () {
            return false;
          });
          Future<bool> characterWrite =
              Future<bool>.delayed(Duration.zero, () async {
            try {
              await character_write!.write(frag);
              return true;
            } catch (e) {
              print("e:$e");
              return false;
            }
          });
          bool value = await Future.any([timeOut, characterWrite]);
          // print("value:$value");
          if (!value) break;
        }
        return true;
      }
    }
    return false;
  }

  Future<bool> doSendBytes2(
      BluetoothCharacteristic wchar, List<int> sendData) async {
    String str = "";
    print("data:" + str);
    //if (connectState == BleHelperState.connected)
    {
      print("doSend 2");
      if (wchar != null) {
        print("doSend 3");
        List<List<int>> frags = doFrags(sendData);
        print("doSend 4:" + frags.length.toString());
        for (int i = 0; i < frags.length; i++) {
          List<int> frag = frags[i];
          str = "";
          for (int i = 0; i < frag.length; i++) {
            str = str + frag[i].toRadixString(16).padLeft(2, "0") + " ";
          }
          print("frag:" + str);
          Future<bool> timeOut =
              Future<bool>.delayed(const Duration(seconds: 2), () {
            return false;
          });
          Future<bool> characterWrite =
              Future<bool>.delayed(Duration.zero, () async {
            try {
              await wchar!.write(frag);
              return true;
            } catch (e) {
              print("e:$e");
              return false;
            }
          });
          bool value = await Future.any([timeOut, characterWrite]);
          // print("value:$value");
          if (!value) break;
        }
        return true;
      }
    }
    return false;
  }

  Future<bool> doSendAndRead(
      BluetoothCharacteristic wchar, List<int> sendData) async {
    try {
      String str = "";
      List<List<int>> frags = doFrags(sendData);
      for (int i = 0; i < frags.length; i++) {
        List<int> frag = frags[i];
        for (int i = 0; i < frag.length; i++) {
          str = "$str${frag[i].toRadixString(16).padLeft(2, "0")} ";
        }
        Future<bool> timeOut =
            Future<bool>.delayed(const Duration(seconds: 2), () {
          return false;
        });
        Future<bool> characterWrite =
            Future<bool>.delayed(Duration.zero, () async {
          await wchar.write(frag);
          return true;
        });
        bool value = await Future.any([timeOut, characterWrite]);
        if (!value) break;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> doSendBytesDirectly(List<int> sendData) async {
    print("doSend 1");
    String str = "";
    for (int i = 0; i < sendData.length; i++) {
      str = str + sendData[i].toRadixString(16).padLeft(2, "0") + " ";
    }
    print("data:" + str);
    if (connectState == BleHelperState.connected) {
      print("doSend 2");
      if (character_write != null) {
        print("doSend 3");
        List<List<int>> frags = [sendData]; //doFrags(sendData);
        print("doSend 4:" + frags.length.toString());
        for (int i = 0; i < frags.length; i++) {
          List<int> frag = frags[i];
          str = "";
          for (int i = 0; i < frag.length; i++) {
            str = str + frag[i].toRadixString(16).padLeft(2, "0") + " ";
          }
          print("frag:" + str);
          // await lock.synchronized(() async {
          try {
            await character_write!.write(frag);
          } on Exception {}
          // });
        }
        return true;
      }
    }
    return false;
  }

  bool _isSending = false;
  Future<bool> doSend(String str, {bool directly = false}) async {
    int times = 0;
    while (_isSending == true) {
      await Future.delayed(Duration(milliseconds: 100));
      times++;
      if (times > 10) return false;
    }
    _isSending = true;
    List<int> bytes = str.codeUnits;
    bool state;
    if (directly) {
      state = await doSendBytesDirectly(bytes);
    } else {
      state = await doSendBytes(bytes);
    }
    _isSending = false;
    return state;
  }

  Future<bool> doSend2(List<int> bytes) async {
    int times = 0;
    while (_isSending == true) {
      await Future.delayed(Duration(milliseconds: 100));
      times++;
      if (times > 10) return false;
    }
    _isSending = true;
    bool state;
    state = await doSendBytes(bytes);
    _isSending = false;
    return state;
  }

  Future<bool> doSendByte(List<int> bytes) async {
    int times = 0;
    while (_isSending == true) {
      await Future.delayed(Duration(milliseconds: 100));
      times++;
      if (times > 10) return false;
    }
    _isSending = true;
    bool state;
    state = await devSendBytes(bytes);
    _isSending = false;
    return state;
  }

  Future<bool> devSendBytes(List<int> sendData) async {
    if (character_write != null) {
      List<List<int>> frags = doFrags2(sendData);
      for (int i = 0; i < frags.length; i++) {
        List<int> frag = frags[i];
        Future<bool> timeOut =
            Future<bool>.delayed(const Duration(seconds: 5), () {
          return false;
        });
        Future<bool> characterWrite =
            Future<bool>.delayed(Duration.zero, () async {
          try {
            await character_write!.write(frag);
            return true;
          } catch (e) {
            print("character_write exception:$e");
            return false;
          }
        });
        bool value = await Future.any([timeOut, characterWrite]);
        // print("value:$value");
        if (!value) print("character_write failed");
        if (!value) break;
      }
      return true;
    }

    return false;
  }

  List<List<int>> doFrags2(List<int> packIn) {
    List<int> pack = [];
    pack.addAll(packIn);
    List<List<int>> list = [];
    int mtu = 237; //240 - 3;
    int idx = 1;
    // print(pack.toString());
    while (pack.length > mtu) {
      List<int> frag = [idx ~/ 256, idx % 256, mtu];
      List<int> tmp = pack.getRange(0, mtu).toList();
      // print(tmp.toString());
      for (int i = 0; i < tmp.length; i++) frag.add(tmp[i]);
      list.add(frag);
      // print("1 pack len="+pack.length.toString()+",mtu="+mtu.toString());
      pack.removeRange(0, mtu);
      // print("2 pack len="+pack.length.toString());
      idx++;
    }
    if (pack.length > 0) {
      List<int> frag = [idx ~/ 256, idx % 256, pack.length];
      for (int i = 0; i < pack.length; i++) frag.add(pack[i]);
      list.add(frag);
    }
    // int fragNum= list.length;
    // for (int i=0; i<list.length; i++){
    //   list[i][1]= fragNum;
    // }
    return list;
  }

  //发送数据
  Future<Map<String, dynamic>?> doSendAndWait(
      Map<String, dynamic> cmd, String dtuId,
      {int tryTimes = 0, int timeout = 3000}) async {
    try {
      String? encrypted = cmdEncrypt(cmd, dtuId);
      if (encrypted != null) {
        while (tryTimes >= 0) {
          bool state = await BleHelper.getInstance().doSend(encrypted);
          print("doSend finished");
          tryTimes--;
        }
      }
    } catch (e) {
      print("doSendAndWait exception:$e");
    }

    return null;
  }

  //重启设备
  Future<bool> resetDevice() async {
    List<int> bytes = [
      1,
      1,
      12,
      82,
      101,
      108,
      100,
      51,
      72,
      102,
      50,
      67,
      102,
      103,
      53
    ];
    String str = "";
    bytes.forEach((element) {
      str = str + String.fromCharCode(element);
    });
    bool state = await BleHelper.getInstance().doSend(str, directly: true);
    return state;
  }

  //加密
  String? cmdEncrypt(Map<String, dynamic> map, String dtuId) {
    if (_aesKeyBytes == null) {
      String tmp = dtuId + "SEC_"; //Prof.instance.prefixSSID;
      var content = Utf8Encoder().convert(tmp);
      _aesKeyBytes = md5.convert(content).bytes;
    }
    try {
      String str = jsonEncode(map);
      String? md5 = AesHelper.doEncrypt128CBC(str, keyByts: _aesKeyBytes!);
      return md5;
    } on Exception catch (e) {
      print("cmdEncrypt exception:$e");
    }
    return null;
  }

  //解码
  String? cmdDecrypt(String str, String dtuId) {
    if (_aesKeyBytes == null) {
      String tmp = dtuId + "SEC_"; //Prof.instance.prefixSSID;
      var content = Utf8Encoder().convert(tmp);
      _aesKeyBytes = md5.convert(content).bytes;
    }
    try {
      String? res = AesHelper.doDecrypt128CBC(str, keyBytes: _aesKeyBytes!);
      return res;
    } on Exception catch (e) {
      print("cmdDecrypt exception:$e");
    }
    return null;
  }
}

enum BleHelperState { unconnect, connecting, connected }

class BleHelperEvent {
  String type;
  var data;
  BleHelperEvent({required this.type, this.data});
}

class BleDevice {
  String name;
  int rssi;
  AdvertisementData data;
  BluetoothDevice device;
  BleDevice(
      {required this.name,
      required this.rssi,
      required this.device,
      required this.data});
}
