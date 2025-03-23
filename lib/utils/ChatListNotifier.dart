import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ユーザー or ボットの発話
enum MessageSender { user, bot }

/// チャットメッセージモデル
class ChatMessage {
  final MessageSender sender;
  final String text;
  final String? imageUrl;

  ChatMessage({required this.sender, required this.text, this.imageUrl});
}

/// StateNotifier：チャットログを管理
class ChatLogNotifier extends StateNotifier<List<ChatMessage>> {
  ChatLogNotifier() : super([]);

  /// メッセージ追加のためのヘルパー
  void addMessage({
    required String postBy,
    required String text,
    String? imageUrl,
  }) {
    final sender = postBy == "user" ? MessageSender.user : MessageSender.bot;
    state = [
      ...state,
      ChatMessage(sender: sender, text: text, imageUrl: imageUrl),
    ];
  }

  /// チャットをリセット（必要なら）
  void clear() {
    state = [];
  }
}

/// Riverpodプロバイダー
final chatLogProvider =
    StateNotifierProvider<ChatLogNotifier, List<ChatMessage>>(
      (ref) => ChatLogNotifier(),
    );
