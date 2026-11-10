import 'package:flutter/material.dart';

class TopSnackBar {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.red,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    // 【核心修复】先安全移除旧弹窗：必须校验 mounted
    _safeRemoveEntry();

    // 兜底：context不存在/没有Overlay直接返回，防止crash
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _safeRemoveEntry();
                    onDismiss?.call();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _currentEntry = entry;

    // 自动关闭倒计时
    Future.delayed(duration, () {
      // 安全移除
      _safeRemoveEntry();
    });
  }

  /// 统一安全移除方法【重点】所有remove都走这里
  static void _safeRemoveEntry() {
    if (_currentEntry != null && _currentEntry!.mounted) {
      _currentEntry!.remove();
    }
    _currentEntry = null;
  }

  static void hide() {
    _safeRemoveEntry();
  }
}
