import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;
  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF141828), // 顶部深蓝黑
            Color(0xFF1A1F36), // 中间暗紫蓝
            Color(0xFF0F2440), // 底部暗青蓝
          ],
        ),
      ),
      child: child,
    );
  }
}