import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 语言状态管理
final localeProvider = StateProvider<Locale>((ref) {
  // 默认中文，根据你项目修改
  return const Locale('zh');
});
