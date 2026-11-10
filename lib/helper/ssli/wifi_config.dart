import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bms_app/helper/ssli/eutil.dart';
import 'package:bms_app/helper/ssli/prof.dart';
import 'package:bms_app/helper/ssli/udp_helper.dart';
import 'package:bms_app/helper/ssli/wifi_config_softap.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'aes_helper.dart';
import 'ble_helper.dart';
import 'elog.dart';
import 'package:bms_app/generated/l10n.dart' as lan;

class WiFiConfig {
  static WiFiConfig? _instance;
  // 私有的命名构造函数
  WiFiConfig._internal();
  static WiFiConfig get instance {
    if (_instance == null) {
      _instance = WiFiConfig._internal();
    }
    return _instance!;
  }

  /////////////////////////////////
  List<int>? _aesKeyBytes;
  String? _actDeviceIp;
  int requestMark = 0;

  void addFoundDtu(String dtuId, BluetoothDevice bluetoothDevice) {
    foundDtus.add(DtuCfg(
        dtuId: dtuId, bleEnable: 1, rssi: 64, bleDevice: bluetoothDevice));
  }

  void doSetActionDtuId(String dtuId) {
    DtuCfg? dtu = _findByDtuId(dtuId);
    if (dtu == null) {
      return;
    }
    _setActionDtuId(dtu.dtuId, ip: dtu.ipAddress);
  }

  // String _actDtuId;
  void _setActionDtuId(String dtuId, {String? ip}) {
    // _actDtuId= dtuId;
    _actDeviceIp = ip ?? "10.10.100.254";
    String tmp = dtuId + "SEC_"; //Prof.instance.prefixSSID;
    var content = Utf8Encoder().convert(tmp);
    _aesKeyBytes = md5.convert(content).bytes;
    String _aesKey = _aesKeyBytes!.toHexString().replaceAll(" ", "");
    print("string aesKey:" + _aesKey!);
  }

  String? _cmdEncrypt(Map<String, dynamic> map) {
    print("_cmdEncrypt:1");
    if (_aesKeyBytes == null) return null;
    print("_cmdEncrypt:2");
    try {
      String str = jsonEncode(map);
      print(formatDate(DateTime.now(),
              [yyyy, "-", mm, "-", dd, "-", HH, ":", nn, ":", ss, z]) +
          "send:" +
          str);
      String? md5 = AesHelper.doEncrypt128CBC(str, keyByts: _aesKeyBytes!);
      return md5;
    } on Exception catch (e) {
      ELog.d("wifiConfigSoftap error:" + e.toString());
    }
    return null;
  }

  Map<String, dynamic>? _cmdDecrypt(String str) {
    if (_aesKeyBytes == null) return null;
    try {
      String? plainTxt =
          AesHelper.doDecrypt128CBC(str, keyBytes: _aesKeyBytes!);
      if (plainTxt != null) {
        log("recvd:" + plainTxt + ",len=" + plainTxt.length.toString());
        Map<String, dynamic> map = jsonDecode(plainTxt);
        return map;
      }
    } on Exception catch (e) {
      ELog.d("wifiConfigSoftap error:" + e.toString());
    }
    return null;
  }

  int? _cmdWaitCid;
  Map<String, dynamic>? _cmdReply;
  StreamController<Map<String, dynamic>> receiveStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  void _didRecved(String rpl, {bool isBle = true}) {
    try {
      Map<String, dynamic>? rplTmp = _cmdDecrypt(rpl);
      if (rplTmp != null /* && rplTmp['RC']==0*/) {
        print("_cmdWaitCid=" + _cmdWaitCid.toString());
        if (receiveStreamController.hasListener)
          receiveStreamController.add(rplTmp);
        if (_cmdWaitCid != null || rplTmp['CID'] == _cmdWaitCid) {
          _cmdReply = rplTmp;
          _cmdWaitCid = null;
        }
      } else {
        if (rplTmp == null) {
          print("rplTmp=null");
        } else {
          print("rplTmp=" + rplTmp['RC'].toString());
        }
      }
    } on Exception catch (e) {
      ELog.i("excption::" + e.toString());
      ELog.i("rpl:" + rpl);
    }
  }

  Future<Map<String, dynamic>?> _waitRpl(int timeout) async {
    while (timeout >= 0) {
      if (_cmdReply != null) {
        Map<String, dynamic> tmp = _cmdReply!;
        _cmdReply = null;
        return tmp;
      }
      await Future.delayed(Duration(milliseconds: 100));
      timeout -= 100;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _doSendAndWait(
      Map<String, dynamic> cmd, int waitCid,
      {int tryTimes = 0, int timeout = 3000}) async {
    // int tmpTimeout= timeout;
    // while (_cmdWaitCid!=null){
    //   await Future.delayed(Duration(milliseconds: 500));
    //   tmpTimeout-=500;
    //   if (tmpTimeout<0){
    //     return null;
    //   }
    // }
    String? encrypted = _cmdEncrypt(cmd);
    if (encrypted != null) {
      _cmdReply = null;
      _cmdWaitCid = waitCid;
      while (tryTimes >= 0) {
        bool state = await BleHelper.getInstance().doSend(encrypted);
        print("doSend finished");
        if (state == false) {
          await UdpHelper.getInstance()
              .doSend(encrypted, ip: _actDeviceIp ?? "10.10.100.254");
        }
        Map<String, dynamic>? rpl = await _waitRpl(timeout);
        print("_waitRpl finished");
        if (rpl != null) {
          return rpl;
        }
        tryTimes--;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _doSendAndWait2(List<int> bytes, int waitCid,
      {int tryTimes = 0, int timeout = 3000}) async {
    if (true) {
      _cmdReply = null;
      _cmdWaitCid = waitCid;
      while (tryTimes >= 0) {
        bool state = await BleHelper.getInstance().doSend2(bytes);
        print("doSend finished");
        // if (state==false){
        //   await UdpHelper.getInstance().doSend(encrypted, ip: _actDeviceIp??"10.10.100.254");
        // }
        Map<String, dynamic>? rpl = await _waitRpl(timeout);
        print("_waitRpl finished");
        if (rpl != null) {
          return rpl;
        }
        tryTimes--;
      }
    }
    return null;
  }

  bool _inSsidList(List<ModelSSID> list, String ssid) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].ssid == ssid) {
        return true;
      }
    }
    return false;
  }

  Future<List<ModelSSID>?> doGetSSIDList() async {
    if (!_started || requestMark == 3) {
      requestMark = 0;
      return null;
    }
    print("doGetSSIDList");
    List<ModelSSID> list = [];
    requestMark++;
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30003}, 30004, tryTimes: 3, timeout: 8000);
    if (rpl != null) {
      requestMark = 0;
      List<dynamic> plList = rpl['PL'];
      if (plList != null && plList.length > 0) {
        for (int i = 0; i < plList.length; i++) {
          ModelSSID? tmp = ModelSSID.fromMap(plList[i]);
          if (tmp != null &&
              !_inSsidList(list, tmp.ssid) &&
              !tmp.ssid.contains("?")) {
            list.add(tmp);
          }
        }
      }
    } else {
      doGetSSIDList();
    }
    return list;
  }

  // {"SV":"xxx","HV":"xxx"}
  Future<Map<String, dynamic>?> doGetVer() async {
    if (!_started) {
      return null;
    }
    print("started");
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30001}, 30002, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"SSID":"xxx","Key":"xxx"}
  Future<Map<String, dynamic>?> doGetWiFiConfig() async {
    if (!_started || !_isDiagnose) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30009}, 30010, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"DHCP":0/1,"IP":"xxx","Subnet":"xxx","GW":"xxx","DNS":"xxx"}
  Future<Map<String, dynamic>?> doGetNetConfig() async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30011}, 30012, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"ApKey":"xxx","HPort":xxx,"HUser":"xxx","HPwd":"xxx","Ping":"xxx"}
  Future<Map<String, dynamic>?> doGetDiagConfig() async {
    if (!_started || !_isDiagnose) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30013}, 30014, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"UART":"115200,8,N,1"}
  Future<Map<String, dynamic>?> doGetUartConfig() async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30015}, 30016, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"WConn":0/1,"R":r, "SConn":0/1, "RSSI":"-xx", 'UConn':0/1/2}
  // r: 0-正常连接; 1-连接中; 2-AP不存在; 3-密码错误; 4-其他连接错误
  // SConn: 服务器连接状态
  // AP信号强度
  Future<Map<String, dynamic>?> doGetWiFiDiagnose() async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30020}, 30021, tryTimes: 3, timeout: 5000);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> doGetDeviceDiagnose() async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait({"CID": 30024}, 30025, tryTimes: 3, timeout: 7000);
    if (rpl != null) {
      return rpl;
    }
    return null;
  }

  // {"Server":"xxx","IP":"xxx","Subnet":"xxx","GW":"xxx","DNS":"xxx","SConn":0/1,"Ping":0/1}
  Future<Map<String, dynamic>?> doGetNetDiagnose({String? pingAdd}) async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic> cmd = {"CID": 30022};
    int timeout = 3000;
    if (pingAdd != null) {
      cmd['Ping'] = pingAdd;
      timeout = 5000;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait(cmd, 30023, tryTimes: 3, timeout: timeout);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"Rsp":"xxx"}
  Future<Map<String, dynamic>?> doGetUartDiagnose({
    required String uartCmd,
    required int baudRate,
    required int dataBit,
    required String parityBit,
    required int stopBit,
    String? cmdType,
    String? cmdNo,
  }) async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic> cmd = {
      "CID": 30024,
      "PL": {
        "Req": uartCmd,
        "Uart": {
          "BaudRate": baudRate,
          "DataBit": dataBit,
          "ParityBit": parityBit,
          "StopBit": stopBit
        }
      }
    };
    if (cmdType != null) cmd["PL"]["CmdType"] = cmdType;
    if (cmdNo != null) cmd["PL"]["CmdNo"] = cmdNo;
    int timeout = 8000;
    Map<String, dynamic>? rpl =
        await _doSendAndWait(cmd, 30025, tryTimes: 0, timeout: timeout);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  Future<bool> doSetWiFiConfig(
      {required String ssid, required String key}) async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> cmd = {
      "CID": 30005,
      "PL": {"SSID": ssid, "Key": key}
    };
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30006, tryTimes: 3);
    if (rpl != null) {
      if (rpl["RC"] == 0) return true;
    }
    return false;
  }

  Future<bool> doSetModelConfig(
      {bool? DHCP,
      String? IP,
      String? Subnet,
      String? GW,
      String? DNS,
      String? ApKey,
      int? HPort,
      String? HUser,
      String? HPwd,
      String? UART}) async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> PL = {};
    if (DHCP != null) PL['DHCP'] = DHCP ? 1 : 0;
    if (IP != null) PL['IP'] = IP;
    if (Subnet != null) PL['Subnet'] = Subnet;
    if (GW != null) PL['GW'] = GW;
    if (DNS != null) PL['DNS'] = DNS;
    if (ApKey != null) PL['ApKey'] = ApKey;
    if (HPort != null) PL['HPort'] = HPort;
    if (HUser != null) PL['HUser'] = HUser;
    if (HPwd != null) PL['HPwd'] = HPwd;
    if (UART != null) PL['UART'] = UART;
    if (PL.length > 0) {
      Map<String, dynamic> cmd = {"CID": 30005, "PL": PL};
      Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30006, tryTimes: 3);
      if (rpl != null) {
        if (rpl["RC"] == 0) return true;
      }
      return false;
    } else {
      return true;
    }
  }

  Future<bool?> doCheckBleKeyEnable() async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> cmd = {"CID": 30017};
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30018, tryTimes: 3);
    if (rpl != null) {
      if (rpl["RC"] == 9000) return null; //返回null表示需要验证密码
      if (rpl["RC"] == 0 && rpl["PL"]?["BleKeyEn"] == 1) return true;
    }
    return false;
  }

  Future<bool> doSetBleKey(bool enable, {String? key}) async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> pl = {};
    pl["BleKeyEn"] = enable ? 1 : 0;
    if (enable == true && key != null) {
      pl["ApKey"] = key;
    }
    Map<String, dynamic> cmd = {"CID": 30005, "PL": pl};
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30006, tryTimes: 0);
    if (rpl != null) {
      if (rpl["RC"] == 0) return true;
    }
    return false;
  }

  Future<bool> doVerifyBleKey(String key) async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> cmd = {
      "CID": 30050,
      "PL": {"BleKey": key}
    };
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30051, tryTimes: 0);
    if (rpl != null) {
      if (rpl["RC"] == 0) return true;
    }
    return false;
  }

  Future<bool> resetDevice() async {
    if (!_started) {
      return false;
    }
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

  Future<bool> doSetAPN(String apn, String apnUser, String apnPasswd) async {
    if (!_started) {
      return false;
    }
    Map<String, dynamic> pl = {
      "APN": apn,
      "APNUser": apnUser,
      "APNPasswd": apnPasswd
    };
    Map<String, dynamic> cmd = {"CID": 30005, "PL": pl};
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30006, tryTimes: 0);
    if (rpl != null) {
      if (rpl["RC"] == 0) return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> transferFile(
      int type, int size, String crc, int seqNum) async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic> pl = {
      "Type": type, // 2表示脚本文件，3表示设备(逆变器)升级文件
      "Size": size,
      "CRC": crc,
      "seqNum": seqNum
    };
    Map<String, dynamic> cmd = {"CID": 30060, "PL": pl};
    Map<String, dynamic>? rpl = await _doSendAndWait(cmd, 30061, tryTimes: 1);
    if (rpl != null) {
      return rpl;
    }
    return null;
  }

  Future<Map<String, dynamic>?> transferFileBytes(List<int> bytes) async {
    if (!_started) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await _doSendAndWait2(bytes, 30061, tryTimes: 0, timeout: 5000);
    if (rpl != null) {
      return rpl;
    }
    return null;
  }

  // {"SV":"xxx","HV":"xxx", "DTUID":"xxx"}
  // Future<Map<String,dynamic>?> doWaitIND({int? sec}) async {
  //   if (!_started){return null;}
  //   int timeout= sec??10;        // 10 sec by default
  //   while (timeout>0){
  //     Map<String,dynamic>? rpl= await _didRecv(1000, waitCid: 30030);
  //     if (rpl!=null){
  //       return rpl['PL'];
  //     }
  //     timeout--;
  //   }
  //   return null;
  // }

  Future<bool> _doSendWiFiConfig(String ssid, String key) async {
    int start = DateTime.now().millisecondsSinceEpoch;
    // 如果连接断开，BLE程序控制自动会重连，wifi需要手动重连
    // 此时，Wi-Fi配置命令需要重复执行，间隔3秒，超时时间18秒
    while (true) {
      bool state = await doSetWiFiConfig(ssid: ssid, key: key);
      if (state == true) {
        return true;
      }
      if (_isWiFiConfigCanceled) {
        return false;
      }
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - start > 18 * 1000) {
        return false;
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  bool _isWiFiConfigCanceled = true;
  bool _wifiConfigTimeoutOutside = false;
  bool _WiFiConfigOngoing = false;
  bool get WiFiConfigOngoing => _WiFiConfigOngoing;
  Stream<WiFiConfigMsg> streamWiFiConfig(
      {required String ssid, required String key}) async* {
    print("_WiFiConfigOngoing=" + _WiFiConfigOngoing.toString());
    if (_WiFiConfigOngoing == true) return;
    _WiFiConfigOngoing = true;
    print("Start SoftAP config::ssid=" + ssid + ",key=" + key);
    _isWiFiConfigCanceled = false;
    _wifiConfigTimeoutOutside = false;
    int now = DateTime.now().millisecondsSinceEpoch;
    bool state = await _doSendWiFiConfig(ssid, key);
    await Future.delayed(Duration(seconds: 5)); // 等待模块联网
    if (_isWiFiConfigCanceled || _wifiConfigTimeoutOutside) {
      yield WiFiConfigMsg(5, code: _wifiConfigTimeoutOutside ? 501 : 500);
      _WiFiConfigOngoing = false;
      print("SoftAP config cancel 1");
      return;
    }
    if (state == false) {
      yield WiFiConfigMsg(0, code: -1);
      _WiFiConfigOngoing = false;
      print("SoftAP config cancel 2");
      return;
    }
    yield WiFiConfigMsg(1, code: 100); // "STEP1:config ok";
    int ms = DateTime.now().millisecondsSinceEpoch - now;
    bool wconn = false, sconn = false;
    bool isTimeout = true;
    int rssi = -100;
    int? msHconn1 = null;
    // 配网总超时时间60秒，每2秒请求一次状态，
    // 中间如有断链，BLE会自动重连，Wi-Fi需要手动重连
    while (ms < 90 * 1000) {
      // 1.5minute
      print("SoftAP config loop:ms=" + ms.toString());
      Map<String, dynamic>? rpl = await doGetWiFiDiagnose();
      if (rpl != null) {
        String rplSsid = rpl['SSID'];
        if (rplSsid != ssid) {
          await _doSendWiFiConfig(ssid, key);
          await Future.delayed(Duration(seconds: 2));
          ms = DateTime.now().millisecondsSinceEpoch - now;
          continue;
        }
        if (rpl.containsKey("WConn")) {
          if (rpl['WConn'] == 1) {
            if (wconn == false) {
              yield WiFiConfigMsg(3, code: 300); // "STEP3:wifi connected";
              wconn = true;
            }
            if (rpl.containsKey("RSSI") && rpl['RSSI'] is String) {
              int? r_rssi = int.tryParse(rpl['RSSI']);
              if (r_rssi != null && r_rssi > rssi) {
                rssi = r_rssi!;
                yield WiFiConfigMsg(3,
                    code: 300,
                    rssi: rssi); // "STEP3:wifi connected,RSSI"+rssi.toString();
              }
            }
          } else if (rpl['WConn'] == 0 && rpl.containsKey("R")) {
            yield WiFiConfigMsg(2, code: rpl['R']);
            if (rpl['R'] >= 2 && rpl['R'] <= 4) {
              isTimeout = false;
              break;
            }
          }
        }
        if (rpl.containsKey("HSConn")) {
          if (rpl['HSConn'] == 1) {
            if (msHconn1 == null) {
              msHconn1 = DateTime.now().millisecondsSinceEpoch;
              yield WiFiConfigMsg(3, code: 300);
            } else if (DateTime.now().millisecondsSinceEpoch - msHconn1 >
                5000) {
              break;
            }
          }
        }
        if (rpl.containsKey("SConn")) {
          if (rpl['SConn'] == 1) {
            sconn = true;
            yield WiFiConfigMsg(4, code: 400); //  "STEP4:server connected";
            isTimeout = false;
            break;
          }
        }
      }
      if (_isWiFiConfigCanceled || _wifiConfigTimeoutOutside) {
        break;
      }
      await Future.delayed(Duration(seconds: 2));
      ms = DateTime.now().millisecondsSinceEpoch - now;
    }
    print("SoftAP config after while");
    if (msHconn1 != null) {
      yield WiFiConfigMsg(4, code: 403); //  "STEP4:Hconn=1";
    } else if (sconn == false) {
      if (_isWiFiConfigCanceled)
        yield WiFiConfigMsg(5, code: _wifiConfigTimeoutOutside ? 501 : 500);
      else if (isTimeout == true)
        yield WiFiConfigMsg(4, code: 401); // "STEP4:timeout";
      else
        yield WiFiConfigMsg(4, code: 402); //  "STEP4:failed";
    }
    print("SoftAP config finished");
    _WiFiConfigOngoing = false;
  }

  void cancelWiFiConfig({timeout = false}) {
    print("cancelWiFiConfig invoked");
    _isWiFiConfigCanceled = true;
    _wifiConfigTimeoutOutside = timeout;
    if (timeout == true) {
      _WiFiConfigOngoing = false;
    }
  }

  String wordFromCode(BuildContext context, int code) {
    if (code == 1) {
      return lan.S.of(context).batteryType; //"正在Wi-Fi连接";//"wifi connecting";
    } else if (code == 2) {
      return lan.S.of(context).router_not_exist; //"路由器不存在";//"AP not exist";
    } else if (code == 3) {
      return lan.S.of(context).error_router_key; //"路由器密码错误";//"key error";
    } else if (code == 4) {
      return lan.S
          .of(context)
          .error_router_connect; //"路由器连接错误";//"other error";
    } else if (code == 100) {
      return lan.S
          .of(context)
          .ongoing_router_connect; //"命令下发完成,正在连接路由器";//"other error";
    } else if (code == 300) {
      return ""; //lan.S.of(context).ongoing_cloud_connect;//"路由器连接成功,正在连接云服务";//"other error";
    } else if (code == 400) {
      return lan.S.of(context).config_success; //"配置完成";//"success";
    } else if (code == 401) {
      return lan.S.of(context).config_timeout; //"配置超时";//"timeout";
    } else if (code == 402) {
      return ""; //"配置失败";//"failed";
    } else if (code == -1) {
      return lan.S.of(context).error_send_cmd; //"发送配置命令失败";//"send cmd failed";
    } else if (code == 403) {
      return ""; //lan.S.of(context).info_cloud_not_connect;//"未连接云服务,请确认逆变器已经上电,或者联系供应商。";//"cloud connecting";
    } else {
      return "";
    }
  }

  /////////////////////////////////
  String? _isIndicate(String str) {
    try {
      Map<String, dynamic> map = jsonDecode(str);
      int? cid = map['CID'];
      String? dtuid = map['DTUID'];
      if (cid != null && cid == 30030 && dtuid != null) {
        return dtuid;
      }
    } on Exception {}
    return null;
  }

  bool _isDiagnose = false;
  String? _diagnoseDtuId;
  void doInit({bool diagnose = false, dtuId, type = 'qita'}) async {
    if (diagnose == true && dtuId != null) {
      _diagnoseDtuId = dtuId;
      _isDiagnose = true;
    } else {
      _isDiagnose = false;
    }
    _started = true;
    BleHelper.getInstance().doInit(callback: (BleHelperEvent event) {
      if (event.type == "recv") {
        // event.data is String
        _didRecved(event.data, isBle: true);
      } else if (event.type == "state") {
        if (event.data == "ok") {
          // print("ble state on");
          _bleStateOn = true;
        } else {
          // print("ble state off");
          _bleStateOn = false;
        }
      } else if (event.type == "scan") {
        if (event.data is BleDevice) {
          BleDevice bleDev = event.data;
          // print("ble scan:"+bleDev.name);
          _bleScaned(bleDev.name, bleDev.rssi, bleDev.device, type);
        }
      } else if (event.type == "connect" ||
          event.type == "disconn" ||
          event.type == "connecting") {
        _bleConnectState = event.type;
      }
    });
    String? ip = await WiFiForIoTPlugin.getIP();
    if (ip != null && ip != "0.0.0.0")
      UdpHelper.getInstance().doInit(callback: (UdpHelperEvent event) {
        // event.data is String
        if (event.type == "recv") {
          String? tmp = _isIndicate(event.data);
          if (tmp != null && event.ip != null) {
            DtuCfg? dtu = _apFound(tmp, event.ip);
            if (dtu != null) {
              if (!_isDiagnose || _isDiagnose && dtu.dtuId == _diagnoseDtuId) {
                _foundReason = "ap:" + dtu.dtuId;
              }
            }
          } else {
            _didRecved(event.data, isBle: false);
          }
        }
      });
  }

  void doStop() {
    _started = false;
    BleHelper.getInstance().doStop();
    UdpHelper.getInstance().doStop();
    // stop streams
    doStopSearchDevice();
    doBleStopConnect();

    _isWiFiConfigCanceled = true;
    _WiFiConfigOngoing = false;
  }

  bool _started = false;
  bool _bleStateOn = false;
  Stream<bool> streamBleState() async* {
    _bleStateOn = true;
    bool oldStateOn = _bleStateOn;
    yield _bleStateOn;
    while (_started == true) {
      if (oldStateOn != _bleStateOn) {
        oldStateOn = _bleStateOn;
        if (_bleStateOn == false) {
          await Future.delayed(Duration(seconds: 1));
          if (_bleStateOn == false) {
            yield _bleStateOn;
          }
        }
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  bool _bleConnecting = false;
  String _bleConnectState = "disconn";
  Stream<String> streamSetDtuIdWithBleConnect(String dtuId) async* {
    Prof.instance.addVisitedDtuId(dtuId);
    if (_isDiagnose == true && dtuId != _diagnoseDtuId) {
      yield "fault";
      return;
    }
    DtuCfg? dtu = _findByDtuId(dtuId);
    if (dtu == null) {
      yield "fault";
      return;
    }
    _setActionDtuId(dtu.dtuId, ip: dtu.ipAddress);
    if (dtu.bleEnable == 1 && dtu.bleDevice != null) {
      // ble 连接
      _bleConnecting = true;
      String oldBleConnectState = BleHelper.getInstance().doConnect(dtu);
      int reconnectTimes = 0;
      while (_bleConnecting == true) {
        if (_bleConnectState != oldBleConnectState) {
          oldBleConnectState = _bleConnectState;
          if (_bleConnectState == "connect") {
            reconnectTimes = 0;
            yield "connect";
          } else if (_bleConnectState == "disconn") {
            reconnectTimes++;
          } else if (_bleConnectState == "connecting") {
            yield "connecting";
          }
          if (reconnectTimes >= 5) {
            dtu.bleEnable = -1;
            _bleConnecting = false;
            yield "disconn";
          }
        }
        await Future.delayed(Duration(milliseconds: 300));
      }
    } else {
      // wifi 连接
      yield "connect";
    }
  }

  void doBleStopConnect() {
    _bleConnecting = false;
    _bleConnectState = "disconn";
    BleHelper.getInstance().doDisconnect();
  }

  List<DtuCfg> foundDtus = [];
  String? _foundReason; // "ble", "ap:xxxxxx" (xxxxx=dtuid)
  bool _searching = false;
  Stream<String> streamSearchDevice() async* {
    foundDtus.clear();
    _searching = true;
    while (_searching == true) {
      if (_foundReason != null) {
        String tmp = _foundReason!;
        yield tmp;
        _foundReason = null;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  void doStopSearchDevice() {
    _searching = false;
  }

  DtuCfg? _apFound(String dtuid, String? ip) {
    for (int i = 0; i < foundDtus.length; i++) {
      DtuCfg dtu = foundDtus[i];
      if (dtu.dtuId == dtuid) {
        dtu.ipAddress = ip;
        return dtu;
      }
    }
    DtuCfg dtu = DtuCfg(dtuId: dtuid, ipAddress: ip);
    foundDtus.add(dtu);
    return dtu;
  }

  DtuCfg? apConnected(String dtuid) {
    for (int i = 0; i < foundDtus.length; i++) {
      DtuCfg dtu = foundDtus[i];
      if (dtu.dtuId == dtuid) {
        dtu.ipAddress = "10.10.100.254";
        return dtu;
      }
    }
    DtuCfg dtu = DtuCfg(dtuId: dtuid, ipAddress: "10.10.100.254");
    foundDtus.add(dtu);
    return dtu;
  }

  void _bleScaned(String scanedName, int rssi, BluetoothDevice bleDev, type) {
    String prefix = Prof.instance.prefixSSID;
    if (scanedName.indexOf(prefix!) < 0) {
      return;
    }
    var state;
    if (type == 'chazhuo') {
      int codeUnit = scanedName.codeUnitAt(prefix.length); // 获取字符的 Unicode 码点
      state = String.fromCharCode(codeUnit); // 将 Unicode 码点转换为字符
    } else {
      state = scanedName.codeUnitAt(prefix.length) - 0x30;
    }
    String b64 = scanedName.substring(prefix.length + 1);
    List<int> ilist = base64.decode(b64).toList();
    String dtuId = hex.encode(ilist);
    if (!_isDiagnose && (type == 'chazhuo' ? state != 'K' : state != 2) ||
        _isDiagnose && _diagnoseDtuId == dtuId) {
      // 未连接服务器 或 为诊断设备
      if (!_isDiagnose || _isDiagnose && dtuId == _diagnoseDtuId) {
        DtuCfg? dtu = _findByDtuId(dtuId);
        if (dtu == null) {
          // print("_bleScaned:new dtu="+dtuId);
          dtu = DtuCfg(
              dtuId: dtuId,
              bleEnable: 1,
              rssi: rssi,
              bleDevice: bleDev,
              state: state);
          foundDtus.add(dtu);
          _foundReason = "ble";
        } else {
          // print("_bleScaned:1 dtu="+dtuId);
          if (dtu.bleEnable == 0) {
            dtu.bleEnable = 1;
            dtu.rssi = rssi;
            _foundReason = "ble";
          }
          if (dtu.bleDevice != bleDev) {
            dtu.bleDevice = bleDev;
            dtu.bleEnable = 1;
          }
          dtu.state = state;
        }
      }
    }
  }

  DtuCfg? _findByDtuId(String dtuId) {
    for (int i = 0; i < foundDtus.length; i++) {
      DtuCfg dtu = foundDtus[i];
      if (dtu.dtuId == dtuId) {
        return dtu;
      }
    }
    return null;
  }

  BluetoothDevice? findBleDeviceByDtuId(String dtuId) {
    for (int i = 0; i < foundDtus.length; i++) {
      DtuCfg dtu = foundDtus[i];
      if (dtu.dtuId == dtuId) {
        return dtu.bleDevice;
      }
    }
    return null;
  }
}

class DtuCfg {
  String dtuId;
  int bleEnable; // 0:ble not support; 1:support ble; -1:support ble but ble cannot connect
  int rssi;
  var state; //0 1 2 3 A B C D 的ascii码 减去 0 的ascii码

  String? ipAddress;
  BluetoothDevice? bleDevice;
  DtuCfg(
      {required this.dtuId,
      this.bleEnable = 0,
      this.rssi = -100,
      this.state,
      this.bleDevice,
      this.ipAddress});
}
