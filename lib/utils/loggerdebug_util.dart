// logger_util.dart
import 'dart:developer' as developer;

class LoggerDebugUtil {
  // 是否开启日志，打包发布改成false即可一键关闭
  static const bool enableLog = true;

  static void d(String msg) {
    if (!enableLog) return;
    developer.log("[D] $msg");
  }

  static void i(String msg) {
    if (!enableLog) return;
    developer.log("[I] $msg");
  }

  static void w(String msg) {
    if (!enableLog) return;
    developer.log("[W] $msg");
  }

  static void e(String msg, [Object? error]) {
    if (!enableLog) return;
    developer.log("[E] $msg", error: error);
  }
}
