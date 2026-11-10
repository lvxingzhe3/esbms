import 'dart:math';
import 'package:flutter/material.dart';

class VerticalBatteryWidget extends StatefulWidget {
  final double soc; // 0-100
  final String state;
  final double width;
  final double height;

  const VerticalBatteryWidget(
      {super.key,
      required this.soc,
      this.width = 60,
      this.height = 120,
      this.state = "静置"});

  @override
  State<VerticalBatteryWidget> createState() => _VerticalBatteryWidgetState();
}

class _VerticalBatteryWidgetState extends State<VerticalBatteryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBatteryColor(double soc) {
    if (soc > 50) return Colors.green;
    if (soc > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final safeSoc = widget.soc;
    final batstate = widget.state;
    final color = _getBatteryColor(safeSoc);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 电池顶部凸起
        Container(
          width: widget.width * 0.4,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
        ),
        // 电池主体
        Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 波纹电量填充
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(
                        widget.width - 8,
                        widget.height - 8,
                      ),
                      painter: _WaveBatteryPainter(
                        soc: safeSoc,
                        waveValue: _waveAnimation.value,
                        color: color,
                      ),
                    );
                  },
                ),
                // 中间显示百分比
                //替换Stack里面的文字部分
                Center(
                  child: Text(
                    "$safeSoc%",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10), // 距离底部10像素
                    child: Text(
                      batstate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveBatteryPainter extends CustomPainter {
  final double soc;
  final double waveValue;
  final Color color;

  _WaveBatteryPainter({
    required this.soc,
    required this.waveValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    // 电量高度比例
    final batteryHeight = height * (soc / 100);

    // 裁剪区域，限制在电池内部
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));

    // 底层填充
    Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    Path fillPath = Path()
      ..moveTo(0, height)
      ..lineTo(0, height - batteryHeight)
      ..lineTo(width, height - batteryHeight)
      ..lineTo(width, height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // 波纹层
    Paint wavePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    Path wavePath = Path();
    double waveAmplitude = 1; // 波纹幅度
    double waveFrequency = 0.1; // 波纹频率

    wavePath.moveTo(0, height);

    for (double x = 0; x <= width; x++) {
      double y = height -
          batteryHeight +
          waveAmplitude * sin(x * waveFrequency + waveValue);
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(width, height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveBatteryPainter oldDelegate) {
    return oldDelegate.soc != soc ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.color != color;
  }
}
