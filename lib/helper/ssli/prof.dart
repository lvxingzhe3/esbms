import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:sise_solar/ui/page/page_ota_upgrade.dart';
//import '../ui/ui_config.dart';
//import 'elog.dart';
import 'eutil.dart';

class Prof {
  static Prof? _instance;
  Prof._internal();
  static Prof get instance {
    _instance ??= Prof._internal();
    return _instance!;
  }

  String prefixSSID = "SSL_";
  // String lang= "zh";
  bool tryLogin = true;
  bool savePwd = true;
  bool loginWithoutPassword = false;
  String? tmpAccount;
  String? tmpPwdMD5;
  String? tmpCountryCode;
  String? passWord;
  String? targetAccount;
  String? targetUserId;
  bool accountUpdated = false;
  bool isPwd = false;
  List<String> topDevList = [];
  // 版本提醒的标识
  String verisonRemind = "version_remind";
  // 更新手机号或者email  需优化
  String? textNotifiction;
  // 更换邮箱 1，更换手机号 0
  int? styleNotifiction;
  bool? isShowPhysic;
  Map<String, Map<String, dynamic>?> rplDataDrawers = {};
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); //全局context
  bool isIpad = false;
  List<String> languages = [
    "德语",
    "英语",
    "西班牙语 ",
    "法语",
    "意大利语",
    "荷兰语",
    "俄语",
    "泰语",
    "阿拉伯语",
    "中文(简体)",
    "中文(繁体)",
  ];
  Iterable<Locale>? supportedLocales;
  Map<Locale, String> localeDisplayNames = {
    const Locale.fromSubtags(languageCode: "de"): "Deutsch",
    const Locale.fromSubtags(languageCode: "en"): "English",
    const Locale.fromSubtags(languageCode: "es"): "Española",
    const Locale.fromSubtags(languageCode: "fr"): "Français",
    const Locale.fromSubtags(languageCode: "it"): "Italiano",
    const Locale.fromSubtags(languageCode: "nl"): "Néerlandais",
    const Locale.fromSubtags(languageCode: "ru"): "Русский",
    const Locale.fromSubtags(languageCode: "th"): "ไทย",
    const Locale.fromSubtags(languageCode: "ar"): "العربية",
    const Locale.fromSubtags(languageCode: "pl"): "Polski",
    const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hans"): "中文(简体)",
    const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant"): "中文(繁体)",
  };
  Map<String, String> languageDisplayNames = {
    "de": "Deutsch",
    "en": "English",
    "es": "Española",
    "fr": "Français",
    "it": "Italiano",
    "nl": "Néerlandais",
    "ru": "Русский",
    "th": "ไทย",
    "ar": "العربية",
    "pl": "Polski",
    "zh_Hans": "中文(简体)",
    "zh_Hant": "中文(繁体)",
  };
  Map<Locale, int> rank = {
    const Locale.fromSubtags(languageCode: "de"): 1,
    const Locale.fromSubtags(languageCode: "en"): 2,
    const Locale.fromSubtags(languageCode: "es"): 3,
    const Locale.fromSubtags(languageCode: "fr"): 4,
    const Locale.fromSubtags(languageCode: "it"): 5,
    const Locale.fromSubtags(languageCode: "nl"): 6,
    const Locale.fromSubtags(languageCode: "ru"): 7,
    const Locale.fromSubtags(languageCode: "th"): 8,
    const Locale.fromSubtags(languageCode: "ar"): 9,
    const Locale.fromSubtags(languageCode: "pl"): 10,
    const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hans"): 11,
    const Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant"): 12,
  };
  SharedPreferences? sharedPreferences;
  bool isOTAUpgrading = false;
  final String keyString = "LCBQ4VWF2VUPNSVA";
  final String ivString = "8PFVENVVON889KCQ";
  Encrypter? encrypter; // 用于加密解密OTA升级功能保存到本地的文件
  Map<String, dynamic> OTAUpgradeVariable = {};

  Future<void> doInit() async {
    encrypter = Encrypter(AES(Key.fromUtf8(keyString), mode: AESMode.cbc));
    SharedPreferences sp = await SharedPreferences.getInstance();
    sharedPreferences = sp;
    tmpAccount = sp.getString("account");
    tmpPwdMD5 = sp.getString("pwd");
    passWord = sp.getString("pswd");
    String? tmp = sp.getString("topDevList");
    if (tmp != null && tmp.isNotEmpty) {
      topDevList = tmp.split(",");
    }

    isShowPhysic = sp.getBool("showPhysic");
    if (Platform.isIOS) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      await deviceInfo.iosInfo.then((iosInfo) {
        print(
            'Running on ${iosInfo.utsname.machine}'); // e.g. "Running on iPad14,5"
        if (iosInfo.utsname.machine.toLowerCase().contains("ipad"))
          isIpad = true;
      });
    }
  }

  int findInDevList(String devId) {
    for (int i = 0; i < topDevList.length; i++) {
      if (devId == topDevList[i]) {
        return i;
      }
    }
    return -1;
  }

  Future<void> addTopDevList(String devId) async {
    if (findInDevList(devId) < 0) {
      topDevList.add(devId);
      SharedPreferences sp = await SharedPreferences.getInstance();
      String str = topDevList.join(",");
      sp.setString("topDevList", str);
    }
  }

  Future<void> deleteTopDevList(String devId) async {
    int index = findInDevList(devId);
    if (index >= 0) {
      topDevList.removeAt(index);
      SharedPreferences sp = await SharedPreferences.getInstance();
      String str = topDevList.join(",");
      sp.setString("topDevList", str);
    }
  }

  Future<void> saveUserPwd({String? userName}) async {
    if (userName != null && userName.isNotEmpty) {
      tmpAccount = userName;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? _account = sp.getString("account");
    String? _pwdMd5 = sp.getString("pwd");
    String? _passWord = sp.getString("pswd");
    //ELog.i("temp account:${tmpAccount}, pwd:${tmpPwdMD5}", flag: "save");
    if (_account == tmpAccount &&
        _pwdMd5 == tmpPwdMD5 &&
        _passWord == passWord) {
      return;
    } else {
      sp.setString("account", tmpAccount ?? "");
      sp.setString("pwd", tmpPwdMD5 ?? "");
      sp.setString("pswd", passWord ?? "");
    }
  }

  Future<void> saveUserPwdNew({String? userName}) async {
    if (userName != null && userName.isNotEmpty) {
      tmpAccount = userName;
    }

    SharedPreferences sp = await SharedPreferences.getInstance();

    // 获取当前存储的账号列表（如果有的话）
    String? storedData = sp.getString('accounts');
    List<Map<String, String>> accounts = [];

    // 如果已有存储的账号数据，则解析 JSON 字符串为 List
    if (storedData != null && storedData.isNotEmpty) {
      // 使用 jsonDecode 来解析数据，确保它是一个 List<dynamic> 类型
      List<dynamic> decodedData = jsonDecode(storedData);

      // 将 decodedData 转换为 List<Map<String, String>>
      accounts = decodedData.map((account) {
        return Map<String, String>.from(account as Map<String, dynamic>);
      }).toList();
    }

    // 创建新账号信息
    Map<String, String> newAccount = {
      'account': tmpAccount ?? '',
      'pwdMd5': tmpPwdMD5 ?? '',
      'passWord': passWord ?? ''
    };

    // 如果账号列表中已经存在 tmpAccount，则将其移到列表的最后
    int accountIndex =
        accounts.indexWhere((account) => account['account'] == tmpAccount);

    if (accountIndex != -1) {
      // 如果账号已经存在，移到最后
      Map<String, String> existingAccount = accounts.removeAt(accountIndex);
      accounts.add(existingAccount);
    } else {
      // 如果账号不存在，直接添加到列表
      // 如果账号数超过 5 个，删除最旧的一个（最前面的）
      if (accounts.length >= 5) {
        accounts.removeAt(0);
      }
      accounts.add(newAccount);
    }

    // 将更新后的账号列表转回 JSON 字符串
    String updatedData = jsonEncode(accounts);

    // 保存更新后的数据
    await sp.setString('accounts', updatedData);
  }

  Future<void> saveThemeIndex() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("themeIndex", 4);
  }

  Future<void> clearUserPwd() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove("account");
    // sp.remove("pwd");
  }

  Future<int?> getPrivacy() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? privacy = sp.getInt("privacy");
    return privacy;
  }

  Future<void> setPrivacy(int privacy) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.getInt("privacy") != privacy) {
      sp.setInt("privacy", privacy);
    }
  }

  void setTmpUserPwd(String user, String pwd, {String? countryCode}) {
    // if (EUtil.isNumeric(user)){
    //   tmpAccount= "T"+user;
    // }else{
    tmpAccount = user;
    // }
    tmpCountryCode = countryCode;
    passWord = pwd;
    var content = Utf8Encoder().convert(pwd);
    var b = md5.convert(content).bytes;
    tmpPwdMD5 = b.toHexString().replaceAll(" ", "");
    accountUpdated = true;
  }

  Future<String?> getKeyBySSID(String ssid) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? str = sp.getString("wifi_config");
    if (str != null) {
      Map<String, dynamic> map = jsonDecode(str);
      print("ssid=" + ssid);
      return map[ssid];
    } else {
      return null;
    }
  }

  Future<List<String>> getSSIDList() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? str = sp.getString("wifi_config");
    List<String> list = [];
    if (str != null) {
      // print("Prof::getSSIDList:"+str);
      try {
        Map<String, dynamic> map = jsonDecode(str);
        for (int i = 0; i < map.keys.length; i++) {
          list.add(map.keys.elementAt(i));
        }
      } on Exception {}
    }
    // print("Prof::getSSIDList:"+list.toString());
    return list;
  }

  String? defaultSSIDConfig;
  Future<void> addSSIDandKey(String ssid, String key) async {
    print("Prof::addSSIDandKey:" + ssid + "," + key);
    defaultSSIDConfig = ssid;
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? str = sp.getString("wifi_config");
    Map<String, dynamic> map = {};
    if (str != null) {
      try {
        map = jsonDecode(str);
      } on Exception {}
    }
    if (map.containsKey(ssid) && map[ssid] == key) {
      return;
    } else {
      map[ssid] = key;
      String json = jsonEncode(map);
      // print("Prof::addSSIDandKey:"+json);
      await sp.setString("wifi_config", json);
    }
  }

  Future<void> cleanSSIDandKey() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove("wifi_config");
  }

  Future<void> removeSSIDandKey(String ssid) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? str = sp.getString("wifi_config");
    Map<String, dynamic> map = {};
    if (str != null) {
      try {
        map = jsonDecode(str);
      } on Exception {}
    }
    if (map.containsKey(ssid)) {
      map.remove(ssid);
      String json = jsonEncode(map);
      await sp.setString("wifi_config", json);
    }
  }

  Future<void> setELogAddr(String addr) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("elog_addr", addr);
  }

  Future<String?> getELogAddr() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return await sp.getString("elog_addr");
  }

  bool isSoftAP(String? ssid) {
    if (ssid == null) return false;
    if (ssid.indexOf(Prof.instance.prefixSSID) == 0 &&
        ssid.length - Prof.instance.prefixSSID.length == 20) {
      // print("_isSoftAP:true");
      return true;
    } else {
      // print("_isSoftAP:false");
      return false;
    }
  }

  Future<void> setShowPhysic(bool tf) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool("showPhysic", tf);
    isShowPhysic = tf;
  }

  Future<void> setBleKey(String dtuId, String key) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("${dtuId}BleKey", key);
    await sp.setInt(
        "${dtuId}BleKeySetTime", DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getBleKey(String dtuId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? t = await sp.getInt("${dtuId}BleKeySetTime");
    if (t != null) {
      //超时3天就删除保存的密码
      print(
          "(DateTime.now().millisecondsSinceEpoch - t):${(DateTime.now().millisecondsSinceEpoch - t)}");
      if ((DateTime.now().millisecondsSinceEpoch - t) >
          (3 * 24 * 60 * 60 * 1000)) await deleteBleKey(dtuId);
    }
    return await sp.getString("${dtuId}BleKey");
  }

  Future<void> deleteBleKey(String dtuId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove("${dtuId}BleKey");
    await sp.remove("${dtuId}BleKeySetTime");
  }

  void sortSupportedLocales() {
    if (supportedLocales == null) return;
    print("before sort:$supportedLocales");
    List<Locale> list = supportedLocales!.toList();
    list.sort((Locale A, Locale B) {
      int a = rank[A] ?? 99;
      int b = rank[B] ?? 99;
      return a.compareTo(b);
    });
    supportedLocales = list;
    print("after sort:$supportedLocales");
  }

  List<String>? getVisitedDtuId() {
    return sharedPreferences?.getStringList("visitedDtuId");
  }

  void addVisitedDtuId(String dtuId) {
    List<String>? list = sharedPreferences?.getStringList("visitedDtuId");
    list ??= [];
    if (list.contains(dtuId)) return;
    list.add(dtuId);
    sharedPreferences?.setStringList("visitedDtuId", list);
  }

  List<int> encryptBytes(List<int> bytes) {
    encrypter ??= Encrypter(AES(Key.fromUtf8(keyString), mode: AESMode.cbc));
    Encrypted encrypted =
        encrypter!.encryptBytes(bytes, iv: IV.fromUtf8(ivString));
    return encrypted.bytes.toList();
  }

  List<int> decryptBytes(List<int> bytes) {
    encrypter ??= Encrypter(AES(Key.fromUtf8(keyString), mode: AESMode.cbc));
    return encrypter!.decryptBytes(Encrypted(Uint8List.fromList(bytes)),
        iv: IV.fromUtf8(ivString));
  }
}
