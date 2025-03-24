import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'common.dart';
import 'utils/ChatListNotifier.dart';

final promptProvider = StateProvider<String>((ref) => '');
final userIdProvider = StateProvider<String>((ref) => '');
final streamedPromptProvider = StateProvider<String>((ref) => '');

/// 生成された画像URLリストを管理する StateNotifier
class GeneratedImagesNotifier extends StateNotifier<List<String>> {
  GeneratedImagesNotifier() : super([]);

  void addImage(String imageUrl) {
    state = [...state, imageUrl];
  }

  void clear() {
    state = [];
  }
}

/// RiverpodのProvider
final generatedImagesProvider =
    StateNotifierProvider<GeneratedImagesNotifier, List<String>>(
      (ref) => GeneratedImagesNotifier(),
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

late WebSocketChannel channel;

class ChatPanel extends HookConsumerWidget {
  const ChatPanel({super.key});
  static const String websocketUrl =
      "wss://emed5h4bp1.execute-api.us-west-2.amazonaws.com/v1";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // チャットログを監視
    final chatLog = ref.watch(chatLogProvider);
    final prompt = ref.read(promptProvider);

    // 1回だけ起動状態を管理
    final hasFetched = useState(false);

    // ★ ScrollControllerを用意
    final scrollController = useScrollController();

    // チャットログが変化するたびに最下部へアニメーションスクロール
    useEffect(() {
      if (scrollController.hasClients) {
        Future.microtask(() {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
      return null;
    }, [chatLog]);

    // 初回レンダリング時にAPIへPOST ＋ WebSocket接続
    useEffect(() {
      Future(() async {
        if (!hasFetched.value) {
          // 1. チャットログをクリア
          ref.read(chatLogProvider.notifier).clear();
          // 2. 最初のユーザー発話を追加
          ref
              .read(chatLogProvider.notifier)
              .addMessage(
                postBy: MessageSender.user,
                text: ref.read(promptProvider.notifier).state.trim(),
              );
          // 3. ステートマシン実行
          _startStateMachine(ref, prompt);

          hasFetched.value = true;
        }
      });
      return null;
    }, []);

    return Column(
      children: [
        // チャット一覧
        Expanded(
          child: ListView.builder(
            controller: scrollController, // ★ ScrollControllerを指定
            padding: const EdgeInsets.all(8),
            itemCount: chatLog.length,
            itemBuilder: (context, index) {
              final message = chatLog[index];
              return ChatBubble(
                isUser: message.sender == MessageSender.user,
                text: message.text,
                imageUrl: message.imageUrl,
              );
            },
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

  /// WebSocket接続 & StepFunctions開始
  Future<void> _startStateMachine(WidgetRef ref, String prompt) async {
    // userId
    final userId = ref.read(userIdProvider).trim();

    // WebSocket接続
    try {
      channel = WebSocketChannel.connect(
        Uri.parse("$websocketUrl?userid=$userId"),
      );
      await channel.ready;
    } catch (e) {
      debugPrint("Failed to connect websocket.\n$e");
    }

    // connectionIdを取得
    final connectionIdRes = await http.get(
      Uri.parse(
        "https://rw4mikh1ia.execute-api.us-west-2.amazonaws.com/v1/chat/connectionid?userid=$userId",
      ),
    );
    final connectionId = connectionIdRes.body;

    // WebSocketの受信イベントを処理
    channel.stream.listen((data) {
      debugPrint("---------------");
      debugPrint(data);
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final type = decoded['type'] as String;
      debugPrint("type: $type");

      // contentsから取得
      final contents = decoded['contents'] as Map<String, dynamic>;
      final text =
          (type != "image_generation") ? contents['text'] as String? : null;
      final imageUrl =
          (type == "image_generation")
              ? contents['image_url'] as String?
              : null;
      final isStream =
          (type != "image_generation") ? contents['is_stream'] as bool? : false;

      // チャットログを更新するヘルパー
      void modifyChat(String? text, String? imageUrl, bool? isStream) {
        if (isStream == true) {
          ref
              .read(chatLogProvider.notifier)
              .updateLastMessage(
                newText: text,
                newImageUrl: imageUrl,
                append: true,
              );
        } else {
          if (text != null) {
            ref
                .read(chatLogProvider.notifier)
                .addMessage(
                  postBy: MessageSender.bot,
                  text: text,
                  imageUrl: imageUrl,
                );
          }
        }
      }

      // 種類別に処理
      switch (type) {
        case ('converSDPrompt'):
          {
            final promptState = ref.read(streamedPromptProvider.notifier);
            if (text != null) {
              if (isStream == true) {
                promptState.state += text; // 追記
              } else {
                promptState.state = text; // 上書き
              }
            }
          }
          break;

        case ('image_generation'):
          if (imageUrl != null) {
            ref.read(generatedImagesProvider.notifier).addImage(imageUrl);
          }
          break;

        case ('evaluate_image'):
          modifyChat(text, imageUrl, isStream);
          break;

        case ('judge'):
          modifyChat(text, imageUrl, isStream);
          break;
      }
    });

    // StepFunction開始をリクエスト
    try {
      final uri = Uri.parse(
        'https://goem60ty6j.execute-api.us-west-2.amazonaws.com/V1_StepFunction/execution',
      );
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        "input": jsonEncode({
          "body": {
            "connection_id": connectionId,
            "user_id": userId,
            "user_input": ref.read(promptProvider.notifier).state.trim(),
          },
        }),
        "stateMachineArn":
            "arn:aws:states:us-west-2:425103998868:stateMachine:ImageGenerationStateMachine",
      });
      final res = await http.post(uri, headers: headers, body: body);
      debugPrint(
        "Requested StepFunction to be started.\nstatusCode: ${res.statusCode}  body: ${res.body}",
      );
    } catch (e) {
      debugPrint("Failed to request StepFunction to be started.\n$e");
    }
  }
}

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final String? imageUrl;

  const ChatBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.network(imageUrl!, width: 200),
              ),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class PromptInputField extends ConsumerWidget {
  const PromptInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(streamedPromptProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        readOnly: true,
        // minLines: 開始時の行数
        // maxLines: null にすると内容に応じて無制限に伸びる
        minLines: 5,
        maxLines: 10,
        controller: TextEditingController(text: prompt)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: prompt.length),
          ),
        decoration: const InputDecoration(
          labelText: "画像生成プロンプト",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class ImageGrid extends HookConsumerWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画像URLリストを監視
    final imageUrls = ref.watch(generatedImagesProvider);

    // ★ ScrollController
    final scrollController = useScrollController();

    // 画像リストが変わるたびに最下部へアニメーションスクロール
    useEffect(() {
      if (scrollController.hasClients) {
        Future.microtask(() {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
      return null;
    }, [imageUrls]);

    return GridView.builder(
      controller: scrollController, // ★ コントローラを設定
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4列
        crossAxisSpacing: 8, // 列間の余白
        mainAxisSpacing: 8, // 行間の余白
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final url = imageUrls[index];
        return Container(
          color: Colors.grey[200],
          child: Image.network(url, fit: BoxFit.contain),
        );
      },
    );
  }
}
