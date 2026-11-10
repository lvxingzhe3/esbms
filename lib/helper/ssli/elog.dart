import 'dart:io';

import 'package:bms_app/helper/ssli/prof.dart';
import 'package:common_utils/common_utils.dart';

class ELog {
  static int ELogLevelInfo = 1;
  static int ELogLevelDebug = 2;
  static int ELogLevelFault = 3;

  static int showLevel = ELogLevelInfo;
  static void i(String str, {String flag = ""}) {
    if (showLevel <= ELogLevelInfo) {
      print("[Info][" + flag + "]" + str);
    }
  }

  static void d(String str, {String flag = ""}) {
    if (showLevel <= ELogLevelDebug) {
      LogUtil.d("[Debug][" + flag + "]" + str);
    }
  }

  static Future<void> f(String str, {String flag = ""}) async {
    if (showLevel <= ELogLevelFault) {
      String fp = "[Fault][" + flag + "]" + str;
      print(fp);
      try {
        String fl = "";
        if (flag.isEmpty) {
          fl = fp + "\n";
        } else {
          fl = "[Fault][" + flag + "]\n" + str + "\n\n";
        }
        String? addr = await Prof.instance.getELogAddr();
        if (addr != null) {
          RawDatagramSocket udp =
              await RawDatagramSocket.bind(InternetAddress.anyIPv4, 20099);
          udp.broadcastEnabled = true;
          udp.send((fl).codeUnits, InternetAddress(addr), 20098);
          udp.close();
        }
      } on Exception {}
    }
  }
}
