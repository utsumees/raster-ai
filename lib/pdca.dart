import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'common.dart';
import 'utils/ImageListNotifier.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';

// プロンプトの状態（仮で初期値を入れておきます）
final promptProvider = StateProvider<String>((ref) => '猫の画像をください。');

// チャットログ（ユーザー発話 + Botレスポンス）
class ChatLogNotifier extends StateNotifier<List<String>> {
  ChatLogNotifier() : super([]);

  void add(String message) {
    state = [...state, message];
  }
}

final chatLogProvider = StateNotifierProvider<ChatLogNotifier, List<String>>(
  (ref) => ChatLogNotifier(),
);

class PDCAPage extends HookConsumerWidget {
  const PDCAPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonScaffold(
      appBar: true,
      child: Row(
        children: [
          // 左側: チャットパネル
          const Expanded(flex: 2, child: ChatPanel()),
          // 右側: プロンプト入力 + 画像グリッド
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

class ChatPanel extends HookConsumerWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatLog = ref.watch(chatLogProvider);
    final prompt = ref.read(promptProvider);
    final hasFetched = useState(false);

    // 初回レンダリング時にAPIへPOSTする
    useEffect(() {
      Future(() async {
        if (!hasFetched.value) {
          ref.read(chatLogProvider.notifier).add(prompt); // ユーザー発話を最初に追加
          await _postPromptToApi(ref, prompt);
          hasFetched.value = true;
        }
      });
      return null;
    }, []);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatLog.length,
            itemBuilder: (context, index) {
              final isUser = index == 0;
              return ChatBubble(isUser: isUser, text: chatLog[index]);
            },
          ),
        ),
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
              IconButton(onPressed: () {}, icon: Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _postPromptToApi(WidgetRef ref, String prompt) async {
    try {
      final uri = Uri.parse(
        'https://rw4mikh1ia.execute-api.us-west-2.amazonaws.com/v1/llm',
      );
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        "model": "anthropic.claude-3-7-sonnet-20250219-v1:0",
        "prompt": prompt,
      });

      final res = await http.post(uri, headers: headers, body: body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final message = data['contents'] ?? '成功しました';
        ref.read(chatLogProvider.notifier).add(message);
      } else {
        ref.read(chatLogProvider.notifier).add('エラー: ${res.statusCode}');
      }
    } catch (e) {
      ref.read(chatLogProvider.notifier).add('通信エラー: $e');
    }
  }
}

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
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

class ImageGrid extends StatefulHookConsumerWidget {
  const ImageGrid({Key? key}) : super(key: key);

  @override
  _ImageGridState createState() => _ImageGridState();
}

class _ImageGridState extends ConsumerState<ImageGrid> {
  final _channel = WebSocketChannel.connect(
    Uri.parse(
      'wss://emed5h4bp1.execute-api.us-west-2.amazonaws.com/v1?userid=uuu',
    ),
  );

  @override
  Widget build(BuildContext context) {
    Logger.root.info('WebSocket connected');
    return StreamBuilder(
      stream: _channel.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final imageUrl = snapshot.data as String;
          return Image.network(imageUrl);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
