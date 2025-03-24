import 'package:flutter/cupertino.dart';
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
    required MessageSender postBy,
    required String text,
    String? imageUrl,
  }) {
    debugPrint("addMessage");
    state = [
      ...state,
      ChatMessage(sender: postBy, text: text, imageUrl: imageUrl),
    ];
  }

  void updateLastMessage({
    String? newText,
    String? newImageUrl,
    bool append = false,
  }) {
    if (state.isEmpty) {
      addMessage(postBy: MessageSender.bot, text: newText ?? "");
      return;
    }
    debugPrint("updateLastMessage");

    final last = state.last;
    final updated = ChatMessage(
      sender: last.sender,
      text:
          append && newText != null
              ? last.text + newText
              : newText ?? last.text,
      imageUrl: newImageUrl ?? last.imageUrl,
    );

    state = [...state.sublist(0, state.length - 1), updated];
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
