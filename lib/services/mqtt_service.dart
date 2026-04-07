import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:geolocator/geolocator.dart';

/// MQTT Service — real-time cho booking notifications
/// FCM vẫn chạy song song: MQTT nhanh hơn khi app đang mở,
/// FCM lo khi app bị kill.
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  String? _userId;

  static const String _host = 'wss://api.moewcare.app/mqtt';
  static const int _port = 443; // WSS mặc định chạy trên 443

  // ----- Rút gọn: dùng StreamController thay vì callback đơn -----
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Timer? _locationTimer;

  // ──────────────────────────────────────────────────
  // Kết nối MQTT sau khi login thành công
  // ──────────────────────────────────────────────────
  Future<void> connect(String userId) async {
    // Nếu đã connect cùng userId → không cần reconnect
    if (_client?.connectionStatus?.state == MqttConnectionState.connected &&
        _userId == userId) {
      debugPrint('MQTT: already connected for user $userId');
      return;
    }

    _userId = userId;

    // QUAN TRỌNG: ClientId phải unique để tránh reconnect loop
    // khi cùng user đăng nhập từ nhiều phiên khác nhau
    final clientId =
        'moew_mobile_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient.withPort(_host, clientId, _port);
    _client!.useWebSocket = true; // ← Bật tính năng WebSockets
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.connectTimeoutPeriod = 5000;

    // QUAN TRỌNG: Set callback TRƯỚC khi gọi connect()
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnect = () => debugPrint('MQTT: reconnecting...');

    // Mosquitto anonymous — không cần username/password
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMsg;

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT connect error: $e');
      _client?.disconnect();
    }
  }

  // ──────────────────────────────────────────────────
  // Callbacks nội bộ
  // ──────────────────────────────────────────────────

  void _onConnected() {
    debugPrint('MQTT: connected ✓');
    _subscribeTopics();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }

        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
        publishLocation(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('Location tracking error: $e');
      }
    });
  }

  void _onDisconnected() {
    debugPrint('MQTT: disconnected (sẽ tự reconnect nếu autoReconnect=true)');
  }

  // ──────────────────────────────────────────────────
  // Subscribe các topic sau khi connected
  // ──────────────────────────────────────────────────
  void _subscribeTopics() {
    if (_userId == null || _client == null) return;

    final notifyTopic = 'moew/user/$_userId/notify';
    _client!.subscribe(notifyTopic, MqttQos.atLeastOnce);
    debugPrint('MQTT: subscribed → $notifyTopic');

    // Lắng nghe tất cả message nhận được
    // QUAN TRỌNG: chỉ listen 1 lần trong _onConnected để tránh double-fire
    _client!.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>> messages) {
      for (final msg in messages) {
        final recMsg = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMsg.payload.message,
        );
        _handleMessage(msg.topic, payload);
      }
    });
  }

  // ──────────────────────────────────────────────────
  // Xử lý message nhận về
  // ──────────────────────────────────────────────────
  void _handleMessage(String topic, String rawPayload) {
    try {
      final data = jsonDecode(rawPayload) as Map<String, dynamic>;
      final type = (data['type'] as String?) ?? 'unknown';
      debugPrint('MQTT[$topic] → type=$type');
      _messageController.add(data);
    } catch (e) {
      debugPrint('MQTT parse error on $topic: $e');
    }
  }

  // ──────────────────────────────────────────────────
  // Publish (dùng khi cần, VD: future features)
  // ──────────────────────────────────────────────────
  void _publish(String topic, String payload, MqttQos qos) {
    if (!isConnected) {
      debugPrint('MQTT: not connected, skip publish to $topic');
      return;
    }
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!);
  }

  /// Gửi SOS (QoS 2 — đảm bảo 100% delivery)
  void publishSOS(Map<String, dynamic> sosData) {
    if (_userId == null) return;
    _publish(
      'moew/user/$_userId/sos',
      jsonEncode(sosData),
      MqttQos.exactlyOnce,
    );
  }

  /// Gửi GPS location (QoS 0 — fire-and-forget, OK nếu mất vài gói)
  void publishLocation(double lat, double lng) {
    if (_userId == null) return;
    _publish(
      'moew/user/$_userId/location',
      jsonEncode({
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      MqttQos.atMostOnce,
    );
  }

  void disconnect() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _client?.disconnect();
    _client = null;
    _userId = null;
    debugPrint('MQTT: disconnected and cleaned up');
  }

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  String? get connectedUserId => _userId;
}
