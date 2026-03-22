import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api/api_client.dart';

/// Socket.IO Service — real-time cho SOS + clinic status
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final Map<String, Function> _listeners = {};

  /// Base URL không có /api
  String get _socketUrl =>
      ApiConfig.baseUrl.replaceAll('/api', '');

  /// Kết nối Socket.IO
  Future<io.Socket?> connect() async {
    if (_socket?.connected == true) return _socket;

    final token = await TokenManager.getToken();
    if (token == null) return null;

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('Socket connected: ${_socket!.id}');
    });
    _socket!.onConnectError((err) {
      // ignore: avoid_print
      print('Socket error: $err');
    });
    _socket!.onDisconnect((reason) {
      // ignore: avoid_print
      print('Socket disconnected: $reason');
    });

    return _socket;
  }

  /// Ngắt kết nối
  void disconnect() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket = null;
      _listeners.clear();
    }
  }

  /// Lắng nghe event
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) return;
    _socket!.on(event, callback);
    _listeners[event] = callback;
  }

  /// Bỏ lắng nghe
  void off(String event) {
    if (_socket == null) return;
    _socket!.off(event);
    _listeners.remove(event);
  }

  /// Gửi event
  void emit(String event, [dynamic data]) {
    if (_socket?.connected != true) return;
    _socket!.emit(event, data);
  }

  /// Check connection
  bool get isConnected => _socket?.connected ?? false;
}
