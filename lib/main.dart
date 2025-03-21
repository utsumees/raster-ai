import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raster.ai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black54),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const GetStartedPage(),
    );
  }
}

class GetStartedPage extends ConsumerStatefulWidget {
  const GetStartedPage({super.key});

  @override
  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends ConsumerState<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // アニメーション用コントローラー (20秒周期でループ)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // ループ時間を長くする
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return MarbleBackground(animationValue: _controller.value);
          },
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Raster.ai"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("シンプルなプロンプトからはじめて、思い通りの画像を生成しよう。"),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.red, width: 2),
                        left: BorderSide(color: Colors.blue, width: 2),
                        right: BorderSide(color: Colors.yellow, width: 2),
                        bottom: BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text("Button"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MarbleBackground extends StatelessWidget {
  final double animationValue;

  const MarbleBackground({super.key, required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: MarblePainter(animationValue: animationValue),
    );
  }
}

class MarblePainter extends CustomPainter {
  final double animationValue;

  MarblePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // ループが正確に繋がるように shift を調整
    final double shift = (animationValue * size.width * 3) % (size.width * 3);

    // 開始位置と終了位置を正確に設定
    final Offset startPoint = Offset(-shift, -shift);
    final Offset endPoint = Offset(
      size.width * 3 - shift,
      size.height * 3 - shift,
    );

    final paint =
        Paint()
          ..shader = ui.Gradient.linear(
            startPoint,
            endPoint,
            [
              Colors.blue.shade200,
              Colors.purple.shade100,
              Colors.pink.shade200,
              Colors.yellow.shade100,
              Colors.blue.shade200, // 最初の色を最後にも配置し、スムーズなループを作る
            ],
            [0.0, 0.25, 0.5, 0.75, 1.0], // 均等に配置
            TileMode.repeated, // ループをシームレスに
          );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
