import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// WebSocket接続用のProviderはそのまま利用
final webSocketProvider = Provider<WebSocketChannel>((ref) {
  return WebSocketChannel.connect(
    Uri.parse('wss://your-api-id.execute-api.region.amazonaws.com/dev'),
  );
});

// AsyncNotifierProviderで非同期状態管理を行う
final imageListProvider =
    AsyncNotifierProvider<ImageListNotifier, List<String>>(
      ImageListNotifier.new,
    );

class ImageListNotifier extends AsyncNotifier<List<String>> {
  late final WebSocketChannel _channel;

  @override
  Future<List<String>> build() async {
    _channel = ref.watch(webSocketProvider);
    // 初期状態は空のリストとする
    state = AsyncData([]);

    // WebSocketのストリームを監視
    _channel.stream.listen((message) {
      final decoded = json.decode(message);
      final imageUrl = decoded['image_url'] as String?;
      if (imageUrl != null) {
        // 現在の状態（画像URLのリスト）を取得し、新しいURLを追加して更新
        final currentList = state.value ?? [];
        state = AsyncData([...currentList, imageUrl]);
      }
    });
    return state.value!;
  }
}
