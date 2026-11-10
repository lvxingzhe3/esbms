import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageUtil {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// 保存字符串
  static Future<void> save(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print("secure save err: $e");
    }
  }

  /// 读取字符串
  static Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print("secure read err: $e");
      return null;
    }
  }

  /// 删除
  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  // 二进制字节数组存储（蓝牙字节，base64中转）
  static Future<void> saveBytes(String key, List<int> bytes) async {
    String base64Str = base64.encode(bytes);
    await save(key, base64Str);
  }

  static Future<List<int>?> getBytes(String key) async {
    String? str = await get(key);
    if (str == null) return null;
    return base64.decode(str);
  }
}
