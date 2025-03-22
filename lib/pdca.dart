import 'package:flutter/material.dart';

import 'common.dart';

class PDCAPage extends StatelessWidget {
  const PDCAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: true,
      child: Row(
        children: [
          // 左側: チャット画面
          Expanded(flex: 2, child: ChatPanel()),
          // 右側: プロンプト入力 + 写真グリッド
          Expanded(
            flex: 3,
            child: Column(
              children: const [
                PromptInputField(),
                Expanded(child: ImageGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // チャットログ
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: const [
              ChatBubble(isUser: false, text: "こんにちは！"),
              ChatBubble(isUser: true, text: "猫の画像をください。"),
            ],
          ),
        ),
        // 入力欄
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "メッセージを入力",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}

class PromptInputField extends StatelessWidget {
  const PromptInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: "画像生成プロンプト",
          border: OutlineInputBorder(),
        ),
        readOnly: true,
      ),
    );
  }
}

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: Center(child: Text("写真 ${index + 1}")),
        );
      },
    );
  }
}
