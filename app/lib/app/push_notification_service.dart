import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/plaude_api.dart';
import 'app_config.dart';

class PushNotificationService {
  PushNotificationService({required this.api});

  final PlaudeApi api;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _registeredUserId;
  String? _registeredToken;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get _supportsPushPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasFirebaseConfig {
    if (!AppConfig.hasFirebaseBaseConfig) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppConfig.firebaseAndroidAppId.isNotEmpty,
      TargetPlatform.iOS => AppConfig.firebaseIosAppId.isNotEmpty,
      _ => false,
    };
  }

  Future<void> initialize() async {
    if (_initialized || !_supportsPushPlatform || !_hasFirebaseConfig) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: _firebaseOptionsForCurrentPlatform(),
      );
    }

    const channel = AndroidNotificationChannel(
      'recording_updates',
      'Recording updates',
      description: 'Notifications when a recording finishes processing.',
      importance: Importance.high,
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      _handleTokenRefresh,
    );

    _initialized = true;
  }

  Future<void> syncRegistrationForUser(String userId) async {
    await initialize();
    if (!_initialized) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    if (_registeredUserId == userId && _registeredToken == token) {
      return;
    }

    if (_registeredUserId != null &&
        _registeredToken != null &&
        (_registeredUserId != userId || _registeredToken != token)) {
      await _safeUnregisterCurrentToken();
    }

    await api.registerPushDevice(token: token, platform: _devicePlatform);
    _registeredUserId = userId;
    _registeredToken = token;
  }

  Future<void> clearRegistration() async {
    await _safeUnregisterCurrentToken();
    _registeredUserId = null;
    _registeredToken = null;
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _handleTokenRefresh(String token) async {
    final userId = _registeredUserId;
    if (userId == null || token.isEmpty) {
      return;
    }

    try {
      await api.registerPushDevice(token: token, platform: _devicePlatform);
      _registeredToken = token;
    } catch (_) {
      // Ignore transient push sync issues.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'recording_updates',
        'Recording updates',
        channelDescription:
            'Notifications when a recording finishes processing.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _safeUnregisterCurrentToken() async {
    if (_registeredToken == null) {
      return;
    }

    try {
      await api.unregisterPushDevice(token: _registeredToken!);
    } catch (_) {
      // Ignore cleanup failures during logout or token rotation.
    }
  }

  String get _devicePlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

  FirebaseOptions _firebaseOptionsForCurrentPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAndroidAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: AppConfig.firebaseStorageBucket.isEmpty
            ? null
            : AppConfig.firebaseStorageBucket,
      ),
      TargetPlatform.iOS => FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseIosAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: AppConfig.firebaseStorageBucket.isEmpty
            ? null
            : AppConfig.firebaseStorageBucket,
      ),
      _ => throw UnsupportedError(
        'Push notifications are only configured for Android and iOS.',
      ),
    };
  }
}
