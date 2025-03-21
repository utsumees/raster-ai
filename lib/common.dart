import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Marble background animation controller (Riverpod StateNotifier)
final marbleAnimationControllerProvider = Provider<AnimationController>((ref) {
  throw UnimplementedError(
    'Must be overridden in a ProviderScope with AnimationController',
  );
});

class CommonScaffold extends ConsumerWidget {
  final Widget child;
  final bool appBar;

  const CommonScaffold({super.key, required this.child, this.appBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var appBarWidget =
        appBar
            ? AppBar(
              title: const Text("Raster.ai"),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
            : null;
    final controller = ref.watch(marbleAnimationControllerProvider);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return MarbleBackground(animationValue: controller.value);
          },
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBarWidget,
          body: SafeArea(child: child),
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
    final double shift = (animationValue * size.width * 3) % (size.width * 3);

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
              Colors.blue.shade200,
            ],
            [0.0, 0.25, 0.5, 0.75, 1.0],
            TileMode.repeated,
          );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
