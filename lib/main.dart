import 'dart:math' as math; // clamp用

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'common.dart';
import 'login.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        marbleAnimationControllerProvider.overrideWithValue(_controller),
      ],
      child: MaterialApp(
        title: 'Raster.ai',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black54),
        ),
        home: const GetStartedPage(),
      ),
    );
  }
}

class GetStartedPage extends ConsumerWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面サイズから短辺を取得
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    // 大きすぎないように clamp して制限する例:
    final double mainTitleSize = math.min(80, shortestSide * 0.20); // 大タイトル
    final double subTitleSize = math.min(24, shortestSide * 0.06); // 小タイトル
    final double buttonTextSize = math.min(30, shortestSide * 0.08); // ボタンテキスト

    return CommonScaffold(
      appBar: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 大タイトル
            Text(
              "Raster.ai",
              style: TextStyle(
                color: Colors.white,
                fontSize: mainTitleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // 小タイトル
            Text(
              "シンプルなプロンプトからはじめて、思い通りの画像を生成しよう。",
              style: TextStyle(fontSize: subTitleSize),
              textAlign: TextAlign.center, // 中央寄せするなら
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginSignupPage()),
                );
              },
              child: Text("はじめる", style: TextStyle(fontSize: buttonTextSize)),
            ),
          ],
        ),
      ),
    );
  }
}
