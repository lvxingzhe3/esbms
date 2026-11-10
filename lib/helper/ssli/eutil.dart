import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:pinyin/pinyin.dart';

extension UtilString on String {
  int? parseInt() {
    return int.parse(this);
  }

  double? parseDouble() {
    return double.parse(this);
  }

  List<int> fromHexString() {
    List<String> splits = this.split(" ");
    List<int> list = [];
    splits.forEach((element) {
      list.add(element.parseInt() ?? 0);
    });
    return list;
  }

  List<int> toListInt() {
    return utf8.encode(this);
  }

  String insert(String str, int pos) {
    if (pos < 0) {
      pos = this.length + pos;
    }
    if (pos > 0) {
      if (pos < this.length) {
        return this.substring(0, pos) + str + this.substring(pos);
      } else {
        return this + str;
      }
    } else {
      return str + this;
    }
  }

  bool isStartWith(String str) {
    int idx = this.indexOf(str);
    if (idx == 0)
      return true;
    else
      return false;
  }

  Uint8List toUint8List() {
    var ret = new Uint8List(this.length);
    for (var i = 0; i < this.length; i++) {
      ret[i] = this.codeUnitAt(i);
    }
    return ret;
  }
}

extension UtilInt on int {
  String toHexString(padding, width) {
    return this.toRadixString(16).padLeft(width, padding);
  }

  String toPadding(padding, width) {
    return this.toString().padLeft(width, padding);
  }
}

extension UtilList on List<int> {
  String toHexString() {
    String str = "";
    this.forEach((element) {
      str += element.toHexString('0', 2) + " ";
    });
    return str;
  }

  String? toCharString() {
    try {
      return utf8.decode(this);
    } catch (e) {}
    return null;
  }

  Uint8List toUint8List() {
    return Uint8List.fromList(this);
  }
}

class EUtil {
  static Uint8List uuid(int len) {
    Uint8List b = Uint8List(len);
    for (int i = 0; i < len; i++) {
      b[i] = Random().nextInt(255);
    }
    return b;
  }

  static bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  static String phoneNumFormat(String phoneNum) {
    if (phoneNum.length == 11) {
      return phoneNum.substring(0, 3) +
          " " +
          phoneNum.substring(3, 7) +
          " " +
          phoneNum.substring(7, phoneNum.length);
    } else {
      return phoneNum;
    }
  }

  static String removePlusSign(String code) {
    return code.startsWith('+') ? code.substring(1) : code;
  }

  static String checkNewPwd(String pwd, String pwdCfm, BuildContext context) {
    if (pwd != pwdCfm) {
      return 'Password input is inconsistent';
    }
    if (pwd.length < 6 || pwd.length > 32) {
      return 'Password contains 6 to 32 characters' /*"密码长度限制"*/;
    }
    return "";
  }

  static String dateTimeToString(DateTime dateTime) {
    String str = formatDate(
        dateTime, [yyyy, "-", mm, "-", dd, "T", HH, ":", nn, ":", ss]);
    String tz = formatDate(dateTime, [z]);
    if (tz.length == 4) {
      tz = "+" + tz.substring(0, 2) + ":" + tz.substring(2);
    } else if (tz.length == 5) {
      tz = tz.substring(0, 3) + ":" + tz.substring(3);
    }
    if (tz.isNotEmpty && tz[0] != '+') tz = '+' + tz;
    // return str+tz;
    Duration timeZoneOffset = dateTime.timeZoneOffset;

    // 获取小时和分钟的偏移量
    int hours = timeZoneOffset.inHours;
    int minutes = timeZoneOffset.inMinutes.remainder(60);

    // 根据偏移量是否为正数或负数生成符号
    String sign = hours >= 0 ? "+" : "-";

    // 格式化小时和分钟，补充前置零
    String formattedHours = hours.abs().toString().padLeft(2, '0');
    String formattedMinutes = minutes.abs().toString().padLeft(2, '0');

    String timeZoneString = "$sign$formattedHours:$formattedMinutes";

    print('时区偏移量字符串:$timeZoneString');
    return str + timeZoneString;
  }

  static DateTime? toLocalDateTime(String? time) {
    if (time == null) return null;
    DateTime dateTime = DateTime.parse(time);
    dateTime = dateTime.toLocal();
    return dateTime;
  }

  static String colorToHtml(Color color) {
    return "#${color.value.toRadixString(16).padLeft(8, '0')}";
  }

  static bool chinaPhoneNumber(String input) {
    if (input == null || input.isEmpty) return false;
    //手机正则验证
    String regexPhoneNumber =
        "^((13[0-9])|(15[^4])|(166)|(17[0-8])|(18[0-9])|(19[1,8-9])|(147,145))\\d{8}\$";
    return RegExp(regexPhoneNumber).hasMatch(input);
  }

  static bool email(String input) {
    if (input == null || input.isEmpty) return false;

    // 邮箱正则
    String regexEmail = "^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*\$";
    return RegExp(regexEmail).hasMatch(input);
  }

  static String md5ToString(String string) {
    var content = Utf8Encoder().convert(string);
    var b = md5.convert(content).bytes;
    return b.toHexString().replaceAll(" ", "");
  }

  static String getShowPictureText(String input, int count) {
    input = input.trim();
    String result = '';

    // 处理中文
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(input)) {
      // 提取前两个汉字的拼音首字母
      for (int i = 0; i < input.length && result.length < count; i++) {
        String char = input[i];
        if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(char)) {
          String pinyin = PinyinHelper.getShortPinyin(char);
          if (pinyin.isNotEmpty) {
            result += pinyin[0].toUpperCase();
          }
        }
      }
    } else {
      // 其他语言
      if (input.contains(' ')) {
        List<String> words = input.split(' ');

        for (String word in words) {
          if (result.length < count) {
            result += word[0].toUpperCase();
          }
          if (result.length >= count) {
            break;
          }
        }
      } else {
        // 如果没有空格，直接取前两个字母
        for (int i = 0; i < input.length && result.length < count; i++) {
          result += input[i].toUpperCase();
        }
      }
    }

    return result.length > count ? result.substring(0, count) : result;
  }

  static bool isNumericInt(String s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  static bool isIpAddress(String ip) {
    List<String> splits = ip.split(".");
    if (splits.length == 4) {
      for (int i = 0; i < 4; i++) {
        if (isNumericInt(splits[i])) {
          int itmp = int.parse(splits[i]);
          if (itmp >= 0 && itmp <= 255) {
            continue;
          }
        }
        return false;
      }
    } else {
      return false;
    }
    return true;
  }
}
