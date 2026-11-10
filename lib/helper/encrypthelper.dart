import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';


// 字符串 → base64
String toBase64(String str) {
  List<int> bytes = utf8.encode(str);
  return base64.encode(bytes);
}

// base64 → 字符串
String fromBase64(String b64Str) {
  List<int> bytes = base64.decode(b64Str);
  return utf8.decode(bytes);
}

/// MD5 哈希，返回32位小写16进制字符串
String md5Encode(String str) {
  // utf8转字节
  final bytes = utf8.encode(str);
  final digest = md5.convert(bytes);
  return digest.toString();
}

// 大写版本
String md5EncodeUpper(String str) {
  return md5Encode(str).toUpperCase();
}

/// SHA256 普通哈希，返回小写64位16进制
String sha256Encode(String str) {
  final bytes = utf8.encode(str);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// HMAC‑SHA256
/// [data] 待签名原始字符串
/// [secret] 密钥
/// return 小写hex 64位字符串
String hmacSha256(String data, String secret) {
  final secretBytes = utf8.encode(secret);
  final dataBytes = utf8.encode(data);
  final hmac = Hmac(sha256, secretBytes);
  final digest = hmac.convert(dataBytes);
  return digest.toString();
}
//HMAC-SHA256原始字节md5加密
String hmacSha256toMd5(String data, String secret) {
  final secretBytes = utf8.encode(secret);
  final dataBytes = utf8.encode(data);
  final hmac = Hmac(sha256, secretBytes);
  final digest = hmac.convert(dataBytes).bytes;
  final md5digst=md5.convert(digest);
  return md5digst.toString();
}



/// 32位小写16进制随机字符串（常用nonce、token）
String getRandom32Hex() {
  final rand = Random.secure();
  final sb = StringBuffer();
  const hexChars = '0123456789abcdef';
  for (int i = 0; i < 32; i++) {
    sb.write(hexChars[rand.nextInt(hexChars.length)]);
  }
  return sb.toString();
}