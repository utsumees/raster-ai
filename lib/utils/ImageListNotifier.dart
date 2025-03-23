import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';

// WebSocket接続用のProviderはそのまま利用
final webSocketProvider = Provider<WebSocketChannel>((ref) {
  return WebSocketChannel.connect(
    Uri.parse(
      'wss://emed5h4bp1.execute-api.us-west-2.amazonaws.com/v1?userid=uuu',
    ),
  );
});

// AsyncNotifierProviderで非同期状態管理を行う
final imageListProvider =
    AsyncNotifierProvider<ImageListNotifier, List<String>>(
      ImageListNotifier.new,
    );

class ImageListNotifier extends AsyncNotifier<List<String>> {
  late final WebSocketChannel _channel;
  late final StreamSubscription _subscription;

  @override
  Future<List<String>> build() async {
    _channel = ref.watch(webSocketProvider);
    // 初期状態は空のリストとする
    state = AsyncData([]);
    Logger.root.info('WebSocket connected');

    // WebSocketのストリームを監視
    _subscription = _channel.stream.listen(
      (message) {
        Logger.root.info('Received message: $message');
        try {
          final decoded = json.decode(message);
          final imageUrl = decoded['image_url'] as String?;
          if (imageUrl != null) {
            final currentList = state.value ?? [];
            state = AsyncData([...currentList, imageUrl]);
          }
        } catch (e, stackTrace) {
          // JSONのパースや処理中のエラーをハンドル
          state = AsyncError(e, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        // WebSocketエラーのハンドリング
        state = AsyncError(error, stackTrace);
      },
      onDone: () {
        // 接続が閉じたときの処理（必要に応じて再接続などのロジックを追加）
      },
    );

    // クリーンアップ処理を登録
    ref.onDispose(() {
      _subscription.cancel();
      _channel.sink.close();
    });

    return state.value!;
  }
}
