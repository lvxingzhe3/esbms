import 'package:bms_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool _scanned = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      // 开启自动缩放，二维码比较小时自动放大，大幅提升识别率！重点
      autoStart: true,
      // 识别速度：normal正常；noDuplicates 过滤重复识别（推荐）
      detectionSpeed: DetectionSpeed.noDuplicates,
      // 只识别二维码，减少其他图像干扰，提升识别速度
      formats: [BarcodeFormat.qrCode],
      // 相机分辨率 720p，平衡性能与清晰度
      cameraResolution: const Size(1280, 720),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(S.of(context).scanqrcode),
        // 强制显示返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(null),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, MobileScannerState state, child) {
              final iconData = state.torchState == TorchState.on
                  ? Icons.flashlight_on
                  : Icons.flashlight_off;
              return IconButton(
                icon: Icon(iconData),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (BarcodeCapture capture) {
                if (_scanned) return;
                final String? scanResult = capture.barcodes.first.rawValue;
                if (scanResult != null && scanResult.isNotEmpty) {
                  _scanned = true;
                  var res = scanResult.split(',');
                  String returnStr = res.length > 1 ? res[0] : scanResult;
                  context.pop(returnStr);
                }
              },
            ),
            // 扫码方框
            const Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
