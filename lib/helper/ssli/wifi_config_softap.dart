import 'dart:convert';
import 'dart:io';
import 'package:bms_app/helper/ssli/aes_helper.dart';
import 'package:bms_app/helper/ssli/eutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:crypto/crypto.dart';
import 'package:udp/udp.dart';

class WifiConfigSoftAP {
  static WifiConfigSoftAP? _instance;
  WifiConfigSoftAP._internal();
  // WifiConfigSoftAP({required String ssid, required String key}):this._ssid=ssid, this._key=key;
  static WifiConfigSoftAP get instance {
    if (_instance == null) {
      _instance = WifiConfigSoftAP._internal();
    }
    return _instance!;
  }

  Future<void> doInit({required String dtuId, required String prefix}) async {
    if (_udp != null) {
      _udp!.close();
    }
    String tmp = dtuId + prefix;
    var content = Utf8Encoder().convert(tmp);
    _aesKeyBytes = md5.convert(content).bytes;
    String _aesKey = _aesKeyBytes!.toHexString().replaceAll(" ", "");
    print("string aesKey:" + _aesKey!);
    _udp = await UDP.bind(Endpoint.any(port: Port(58898)));
  }

  void doStop() {
    if (_udp != null) {
      _udp!.close();
      _udp = null;
    }
  }

  void doCancel() {
    _isCancel = true;
    doStop();
  }

  String? cmdEncrypt(Map<String, dynamic> map) {
    if (_aesKeyBytes == null) return null;
    try {
      String str = jsonEncode(map);
      String? md5 = AesHelper.doEncrypt128CBC(str, keyByts: _aesKeyBytes!);
      return md5;
    } on Exception catch (e) {
      print("wifiConfigSoftap error:" + e.toString());
    }
    return null;
  }

  Map<String, dynamic>? cmdDecrypt(String str) {
    if (_aesKeyBytes == null) return null;
    try {
      String? plainTxt =
          AesHelper.doDecrypt128CBC(str, keyBytes: _aesKeyBytes!);
      if (plainTxt != null) {
        Map<String, dynamic> map = jsonDecode(plainTxt);
        return map;
      }
    } on Exception catch (e) {
      print("wifiConfigSoftap error:" + e.toString());
    }
    return null;
  }

  void doSend(Map<String, dynamic> cmd) {
    if (_udp != null) {
      String? encrypted = cmdEncrypt(cmd);
      if (encrypted != null) {
        _udp!.send(
            encrypted.codeUnits,
            Endpoint.unicast(InternetAddress("10.10.100.254"),
                port: Port(58899)));
      }
    }
  }

  Future<Map<String, dynamic>?> doRecv(int mSec, {int? waitCid}) async {
    if (_udp == null) return null;
    Stream stream = _udp!.asStream(timeout: Duration(milliseconds: mSec));
    Map<String, dynamic>? rpl;
    stream.listen((datagram) {
      if (datagram != null) {
        String recv = String.fromCharCodes(datagram!.protocoData);
        Map<String, dynamic>? rplTmp = cmdDecrypt(recv);
        if (rplTmp != null && rplTmp['RC'] == 0) {
          if (waitCid == null || rplTmp['CID'] == waitCid) {
            rpl = rplTmp;
          }
        }
      }
    });
    while (rpl == null && mSec > 0) {
      await Future.delayed(Duration(milliseconds: 100));
      mSec -= 100;
      if (_isCancel) break;
    }
    return rpl;
  }

  Future<Map<String, dynamic>?> doSendAndWait(
      Map<String, dynamic> cmd, int waitCid,
      {int tryTimes = 0, int timeout = 1000}) async {
    while (tryTimes >= 0) {
      doSend(cmd);
      if (_isCancel) break;
      Map<String, dynamic>? rpl = await doRecv(timeout, waitCid: waitCid);
      if (rpl != null) {
        return rpl;
      }
      tryTimes--;
      if (_isCancel) break;
    }
    return null;
  }

  UDP? _udp;
  List<int>? _aesKeyBytes;
  bool _isCancel = false;

  Future<List<ModelSSID>?> doGetSSIDList() async {
    if (_udp == null) {
      return null;
    }
    List<ModelSSID> list = [];
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30003}, 30004, tryTimes: 3);
    if (rpl != null) {
      List<dynamic> plList = rpl['PL'];
      if (plList != null && plList.length > 0) {
        for (int i = 0; i < plList.length; i++) {
          ModelSSID? tmp = ModelSSID.fromMap(plList[i]);
          if (tmp != null) {
            list.add(tmp);
          }
        }
      }
    }
    return list;
  }

  // {"SV":"xxx","HV":"xxx"}
  Future<Map<String, dynamic>?> doGetVer() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30001}, 30002, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"SSID":"xxx","Key":"xxx"}
  Future<Map<String, dynamic>?> doGetWiFiConfig() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30009}, 30010, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"DHCP":0/1,"IP":"xxx","Subnet":"xxx","GW":"xxx","DNS":"xxx"}
  Future<Map<String, dynamic>?> doGetNetConfig() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30011}, 30012, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"ApKey":"xxx","HPort":xxx,"HUser":"xxx","HPwd":"xxx","Ping":"xxx"}
  Future<Map<String, dynamic>?> doGetDiagConfig() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30013}, 30014, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"UART":"115200,8,N,1"}
  Future<Map<String, dynamic>?> doGetUartConfig() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30015}, 30016, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"WConn":0/1,"R":r, "SConn":0/1, "RSSI":"-xx"}
  // r: 0-正常连接; 1-连接中; 2-AP不存在; 3-密码错误; 4-其他连接错误
  // SConn: 服务器连接状态
  // AP信号强度
  Future<Map<String, dynamic>?> doGetWiFiDiagnose() async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait({"CID": 30020}, 30021, tryTimes: 3);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"Server":"xxx","IP":"xxx","Subnet":"xxx","GW":"xxx","DNS":"xxx","SConn":0/1,"Ping":0/1}
  Future<Map<String, dynamic>?> doGetNetDiagnose({String? pingAdd}) async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic> cmd = {"CID": 30022};
    int timeout = 1000;
    if (pingAdd != null) {
      cmd['Ping'] = pingAdd;
      timeout = 5000;
    }
    Map<String, dynamic>? rpl =
        await doSendAndWait(cmd, 30023, tryTimes: 3, timeout: timeout);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  // {"Rsp":"xxx"}
  Future<Map<String, dynamic>?> doGetUartDiagnose(
      {required String uartCmd}) async {
    if (_udp == null) {
      return null;
    }
    Map<String, dynamic> cmd = {
      "CID": 30024,
      "PL": {"Req": uartCmd}
    };
    int timeout = 3000;
    Map<String, dynamic>? rpl =
        await doSendAndWait(cmd, 30025, tryTimes: 3, timeout: timeout);
    if (rpl != null) {
      return rpl['PL'];
    }
    return null;
  }

  Future<bool> doSetWiFiConfig(
      {required String ssid, required String key}) async {
    if (_udp == null) {
      return false;
    }
    Map<String, dynamic> cmd = {
      "CID": 30005,
      "PL": {"SSID": ssid, "Key": key}
    };
    Map<String, dynamic>? rpl = await doSendAndWait(cmd, 30006, tryTimes: 3);
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
    if (_udp == null) {
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
    Map<String, dynamic> cmd = {"CID": 30005, "PL": PL};
    Map<String, dynamic>? rpl = await doSendAndWait(cmd, 30006, tryTimes: 3);
    if (rpl != null) {
      if (rpl["RC"] == 0) return true;
    }
    return false;
  }

  // {"SV":"xxx","HV":"xxx"}
  Future<Map<String, dynamic>?> doWaitIND({int? sec}) async {
    if (_udp == null) {
      return null;
    }
    int timeout = sec ?? 10; // 10 sec by default
    while (timeout > 0) {
      Map<String, dynamic>? rpl = await doRecv(1000, waitCid: 30030);
      if (rpl != null) {
        return rpl['PL'];
      }
      timeout--;
    }
    return null;
  }

  Stream<WiFiConfigMsg> streamWiFiConfig(
      {required String ssid, required String key}) async* {
    print("Start SoftAP config::ssid=" + ssid + ",key=" + key);
    _isCancel = false;
    int now = DateTime.now().millisecondsSinceEpoch;
    bool state = await doSetWiFiConfig(ssid: ssid, key: key);
    if (_isCancel) {
      yield WiFiConfigMsg(5);
      return;
    }
    if (state == false) {
      yield WiFiConfigMsg(0, code: 100);
      return;
    }
    yield WiFiConfigMsg(1); // "STEP1:config ok";
    int ms = DateTime.now().millisecondsSinceEpoch - now;
    bool wconn = false, sconn = false;
    bool isTimeout = true;
    int rssi = -100;
    while (ms < 60 * 1000) {
      // 60 seconds
      Map<String, dynamic>? rpl = await doGetWiFiDiagnose();
      if (rpl != null) {
        if (rpl.containsKey("WConn")) {
          if (rpl['WConn'] == 1) {
            if (wconn == false) {
              yield WiFiConfigMsg(3, code: 0); // "STEP3:wifi connected";
              wconn = true;
            }
            if (rpl.containsKey("RSSI") && rpl['RSSI'] > rssi) {
              rssi = rpl['RSSI'];
              yield WiFiConfigMsg(3,
                  code: 0,
                  rssi: rssi); // "STEP3:wifi connected,RSSI"+rssi.toString();
            }
          } else if (rpl['WConn'] == 0 && rpl.containsKey("R")) {
            yield WiFiConfigMsg(2, code: rpl['R']);
            if (rpl['R'] >= 2 && rpl['R'] <= 4) {
              isTimeout = false;
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
      if (_isCancel) {
        break;
      }
      await Future.delayed(Duration(seconds: 2));
      ms = DateTime.now().millisecondsSinceEpoch - now;
    }
    if (sconn == false) {
      if (_isCancel)
        yield WiFiConfigMsg(5);
      else if (isTimeout == true)
        yield WiFiConfigMsg(4, code: 401); // "STEP4:timeout";
      else
        yield WiFiConfigMsg(4, code: 402); //  "STEP4:failed";
    }
  }

  String wordFromCode(BuildContext context, int code) {
    if (code == 1) {
      return "wifi connecting";
    } else if (code == 2) {
      return "AP not exist";
    } else if (code == 3) {
      return "key error";
    } else if (code == 4) {
      return "other error";
    } else if (code == 400) {
      return "success";
    } else if (code == 401) {
      return "timeout";
    } else if (code == 402) {
      return "failed";
    } else if (code == 100) {
      return "send cmd failed";
    } else {
      return "";
    }
  }
}

class WiFiConfigMsg {
  int step;
  int? code;
  int? rssi;

  WiFiConfigMsg(this.step, {this.code, this.rssi});
}

class ModelSSID {
  String ssid;
  bool secu;

  ModelSSID({required this.ssid, required this.secu});
  static ModelSSID? fromMap(Map<String, dynamic> map) {
    if (map.containsKey("SSID") &&
        map.containsKey("Secu") &&
        map['SSID'] != "") {
      return ModelSSID(
          ssid: map['SSID'], secu: map['Secu'] == 1 ? true : false);
    } else {
      return null;
    }
  }
}
