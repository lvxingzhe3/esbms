import 'dart:convert';
import 'package:bms_app/global.dart';
import 'package:bms_app/helper/datahelper.dart';
import 'package:bms_app/helper/encrypthelper.dart';
import 'package:bms_app/network/dio_client.dart';
import 'package:dio/dio.dart';

class ApiService {
  final DioClient _dioClient;
  ApiService(this._dioClient);
  String appId = "tb2osB4xy5";
  String appKey = "bRVq7kwfp3y0fYfG813y";

  /// 用户登录
  Future<Map<String, dynamic>> userLogin({
    String name = 'admin',
    String password = '123456',
    String language = 'en-US',
  }) async {
    try {
      //生成随机32位数
      String noneStr = getRandom32Hex(); //'e0ec0a6a323eb4be251707cdd7bbac7b';
      //密码md5加密
      String md5pass = md5Encode(password);
      //发送数据转json字符串
      final logindata = {"account": name, "password": md5pass};
      String logindatajson = jsonEncode(logindata);
      //发送json数据
      final shas56 = sha256Encode(logindatajson);
      Map<String, dynamic> tempheaders = {};
      tempheaders.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Body-Hash': shas56,
        'IOT-Open-Nonce': noneStr,
      });
      //拼接合并后的参数
      String mergeSort =
          tempheaders.entries.map((e) => '${e.key}=${e.value}').join('&');
      //对拼接后的字符串进行Base64
      String base64Str = toBase64(mergeSort);
      //对Base64字符串计算HMAC-SHA256,对HMAC-SHA256输出原始字节做MD5
      String signSource = hmacSha256toMd5(base64Str, appKey);
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Sign': signSource,
        'IOT-Open-Nonce': noneStr,
        'Accept-Language': language,
        //'Content-Type': Headers.jsonContentType
      });
      _dioClient.clearHeaders();
      //_dioClient.setHeaders(headers);
      final response = await _dioClient.post(
        '/login/account',
        data: logindata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      //生成随机32位数
      String noneStr = getRandom32Hex();
      //发送数据转json字符串
      final bodydata = {
        "accessToken": GlobalData.apiAccessToken,
        "refreshToken": GlobalData.apiRefreshToken
      };
      String bodydatajson = jsonEncode(bodydata);
      //发送json数据
      final shas56 = sha256Encode(bodydatajson);
      Map<String, dynamic> tempheaders = {};
      tempheaders.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Body-Hash': shas56,
        'IOT-Open-Nonce': noneStr,
      });
      //拼接合并后的参数
      String mergeSort =
          tempheaders.entries.map((e) => '${e.key}=${e.value}').join('&');
      //对拼接后的字符串进行Base64
      String base64Str = toBase64(mergeSort);
      //对Base64字符串计算HMAC-SHA256,对HMAC-SHA256输出原始字节做MD5
      String signSource = hmacSha256toMd5(base64Str, appKey);
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Sign': signSource,
        'IOT-Open-Nonce': noneStr,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final response = await _dioClient.post(
        '/login/refresh/access/token',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取设备列表
  Future<Map<String, dynamic>> getdevicelist() async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {
        "page": 1,
        "count": 100,
      };
      final response = await _dioClient.post(
        '/device/list',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取电站(公司)列表
  Future<Map<String, dynamic>> getstationlist() async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {
        "connectedGridType": 1,
        "page": 1,
        "count": 100,
      };
      final response = await _dioClient.post(
        '/station/list',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 添加单个设备
  Future<Map<String, dynamic>> adddevice(
      String devname, String dtuid, String stationId) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {
        'deviceName': devname,
        'dtuDtuid': dtuid,
        "isVirtualSerialNumber": true,
        "stationId": stationId
      };
      final response = await _dioClient.post(
        '/device/add/single',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 添加单个设备并创建电站
  Future<Map<String, dynamic>> adddeviceandstation(
      String devname,
      String dtuid,
      String stationname,
      String country,
      String latitude,
      String longitude) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final bodydata = {
        "deviceName": devname,
        "dtuDtuid": dtuid,
        "isVirtualSerialNumber": true,
        "station": {
          "name": stationname,
          "longitude": longitude,
          "latitude": latitude,
          "stationType": "2",
          "country": "中国",
          "installedCapacity": "100",
          "connectedGridType": "1",
          "installedAt": formatToIsoWithOffset(DateTime.now()),
          "currencyCode": "CNY",
          "timezone": "Asia/Shanghai"
        }
      };

      final response = await _dioClient.post(
        '/device/add/single/addStationTogether',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取设备bms数据
  Future<Map<String, dynamic>> getdevice(String dtuid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.get(
        '/device/details',
        queryParameters: {
          'deviceId': dtuid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取状态列表分组
  Future<Map<String, dynamic>> getstatuslistgroup(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.get(
        '/device/query/attribute/group',
        queryParameters: {'deviceId': deviceid, 'ategory': 1, 'renderIn': 4},
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取设备bms数据
  Future<Map<String, dynamic>> getdeviceBmsInfo(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.get(
        '/deviceState/simple/state/latest/v1',
        queryParameters: {
          'deviceId': deviceid,
          'dataSource': 1,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取参数列表分组
  Future<Map<String, dynamic>> getparamlistgroup(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.get(
        '/device/query/attribute/group',
        queryParameters: {
          'deviceId': deviceid,
          'category': 3,
          'renderIn': 65536
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取参数列表
  Future<Map<String, dynamic>> getparamlist(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {};
      final response = await _dioClient.post(
        '/remote/device/configs/cache/get',
        data: bodydata,
        queryParameters: {
          'deviceId': deviceid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 批量读取配置项
  Future<Map<String, dynamic>> getparambatch(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {};
      final response = await _dioClient.post(
        '/remote/device/configs/read',
        data: bodydata,
        queryParameters: {
          'deviceId': deviceid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 批量读取配置项详情
  Future<Map<String, dynamic>> getparambatchdetials(int batchid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final response = await _dioClient.get(
        '/remote/device/configs/read/details',
        queryParameters: {
          'batchReadId': batchid,
        },
        options: Options(headers: headers),
      );
      // 安全校验：保证是Map，不是null、不是List
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      // 返回格式不对，主动抛业务异常
      throw Exception("接口返回数据格式错误，非Map");
    } catch (e) {
      print("$e");
      rethrow;
    }
  }

  /// 读取单个参数
  Future<Map<String, dynamic>> readparam(String deviceid, String param) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {"key": param};
      final response = await _dioClient.post(
        '/remote/device/config/read',
        data: bodydata,
        queryParameters: {
          'deviceId': deviceid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 设置单个参数
  Future<Map<String, dynamic>> setparam(
      String deviceid, String param, String value) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {"key": param, "value": value};
      final response = await _dioClient.post(
        '/remote/device/config/write',
        data: bodydata,
        queryParameters: {
          'deviceId': deviceid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    } finally {
      // 清除请求头，避免影响其他请求
      _dioClient.clearHeaders();
    }
  }

  /// 获取最新告警
  Future<Map<String, dynamic>> getlatestalarm(String deviceid) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final bodydata = {
        "deviceSerialNumber": null,
        "certificateDtuID": deviceid,
        "page": 1,
        "count": 1
      };

      final response = await _dioClient.post(
        '/alarm/getLatestAlarm',
        data: bodydata,
        queryParameters: {
          'deviceId': deviceid,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 检查账户注册状态
  Future<Map<String, dynamic>> checkAccountRegister(String phone) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.get(
        '/user/account/check',
        queryParameters: {
          'account': phone,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取手机验证码
  Future<Map<String, dynamic>> getPhoneCode(
      String address, String areacode) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      //生成随机32位数
      String noneStr = getRandom32Hex();
      final bodydata = {
        "address": address,
        "intent": 1,
        //"countryTelephoneCode": areacode,
      };
      String datajson = jsonEncode(bodydata);
      //发送json数据
      final shas56 = sha256Encode(datajson);
      Map<String, dynamic> tempheaders = {};
      tempheaders.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Body-Hash': shas56,
        'IOT-Open-Nonce': noneStr,
      });
      //拼接合并后的参数
      String mergeSort =
          tempheaders.entries.map((e) => '${e.key}=${e.value}').join('&');
      //对拼接后的字符串进行Base64
      String base64Str = toBase64(mergeSort);
      //对Base64字符串计算HMAC-SHA256,对HMAC-SHA256输出原始字节做MD5
      String signSource = hmacSha256toMd5(base64Str, appKey);
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Sign': signSource,
        'IOT-Open-Nonce': noneStr,
        'Accept-Language': lang,
        'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.post(
        '/user/send/sms/captcha',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 手机注册
  Future<Map<String, dynamic>> registerByPhone(String account, String areacode,
      String phone, String captcha, String password, String verifycode) async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      String md5pass = md5Encode(password);
      final bodydata = {
        "authType": 0,
        "captchaId": captcha,
        "cellphone": phone,
        "account": account,
        "password": md5pass,
        "verifyCode": verifycode,
        "countryTelephoneCode": areacode,
      };
      String datajson = jsonEncode(bodydata);
      //发送json数据
      final shas56 = sha256Encode(datajson);
      //生成随机32位数
      String noneStr = getRandom32Hex();
      Map<String, dynamic> tempheaders = {};
      tempheaders.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Body-Hash': shas56,
        'IOT-Open-Nonce': noneStr,
      });
      //拼接合并后的参数
      String mergeSort =
          tempheaders.entries.map((e) => '${e.key}=${e.value}').join('&');
      //对拼接后的字符串进行Base64
      String base64Str = toBase64(mergeSort);
      //对Base64字符串计算HMAC-SHA256,对HMAC-SHA256输出原始字节做MD5
      String signSource = hmacSha256toMd5(base64Str, appKey);
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Open-AppID': appId,
        'IOT-Open-Sign': signSource,
        'IOT-Open-Nonce': noneStr,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });

      final response = await _dioClient.post(
        '/user/register/cellphone',
        data: bodydata,
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// 注销账户
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      String lang = 'zh-CN';
      if (GlobalData.language != null && GlobalData.language == "en") {
        lang = 'en-US';
      }
      Map<String, String> headers = {};
      headers.addAll({
        'IOT-Token': GlobalData.apiAccessToken,
        'Accept-Language': lang,
        //'Content-Type': Headers.jsonContentType
      });
      final response = await _dioClient.post(
        '/user/logout/account',
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    } finally {
      // 清除请求头，避免影响其他请求
      _dioClient.clearHeaders();
    }
  }

  /// GPS用户登录
  Future<Map<String, dynamic>> gpsuserLogin({
    String name = '038581676161',
    String password = '123456',
    String language = 'cn',
  }) async {
    try {
      _dioClient.setBaseUrl(1);
      _dioClient.clearHeaders();
      Map<String, String> headers = {};
      headers.addAll({'Content-Type': Headers.jsonContentType});
      final response = await _dioClient.getgps(
        '/GetDateServices.asmx/loginSystem',
        queryParameters: {
          'LoginName': name,
          'LoginPassword': password,
          'language': language,
          'LoginType': 'USER',
          'apply': 'APP',
        },
        //options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    } finally {
      _dioClient.setBaseUrl(0);
    }
  }

  /// 刷新 mds
  Future<void> refreshMds({
    required String mds,
  }) async {
    try {
      await _dioClient.get(
        '/Command.aspx',
        queryParameters: {
          'method': 'RefreshMds',
          'mds': mds,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取单个设备位置
  Future<Map<String, dynamic>> getDeviceLocation({
    required String mds,
    required String user_id,
    String mapType = 'BAIDU',
    String option = 'cn',
  }) async {
    try {
      _dioClient.setBaseUrl(1);
      final response = await _dioClient.getgps(
        '/GetDateServices.asmx/GetDate',
        queryParameters: {
          'method': 'getUserAndGpsInfoByIDsUtcNew',
          'mds': mds,
          'user_id': user_id,
          'mapType': mapType,
          'option': option,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    } finally {
      _dioClient.setBaseUrl(0);
    }
  }

  /// 获取 BMS 实时状态
  Future<Map<String, dynamic>> getBmsRealTimeStatus({
    required String mds,
    required String macid,
  }) async {
    try {
      final response = await _dioClient.get(
        '/GetDateServices.asmx/GetDate',
        queryParameters: {
          'method': 'BmsServerApi',
          'w': 'RealtimeStatus',
          'mds': mds,
          'macid': macid,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
