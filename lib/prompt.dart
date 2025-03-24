import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:raster_ai/pdca.dart';

import 'common.dart';

class PromptInputPage extends ConsumerStatefulWidget {
  const PromptInputPage({super.key});

  @override
  ConsumerState<PromptInputPage> createState() => _PromptPageState();
}

class _PromptPageState extends ConsumerState<PromptInputPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGeneratePressed() {
    final prompt = _controller.text.trim();
    if (prompt.isNotEmpty) {
      // ここで画像生成処理などを行う
      debugPrint("プロンプト: $prompt");
      ref.read(promptProvider.notifier).state = prompt; // プロンプト保存
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => PDCAPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: true,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(80),
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "プロンプトを入力",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例: 割けるチーズを食べている男子大学生',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _onGeneratePressed,
                  child: const Text("生成"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
