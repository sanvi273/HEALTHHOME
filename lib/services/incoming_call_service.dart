import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'api_service.dart';
import '../screens/incoming_video_call_screen.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> healthHomeFcmBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await IncomingCallService.initializeLocalNotifications();
  await IncomingCallService.showIncomingNotification(message.data);
}

class IncomingCallService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final Set<String> _shownCalls = <String>{};
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'incoming_calls',
    'Incoming calls',
    description: 'Audible alerts for incoming HealthHome video consultations',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(healthHomeFcmBackgroundHandler);
    await initializeLocalNotifications();
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.denied) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registerToken(token);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);
    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data['type'] == 'incoming_call') {
        await showIncomingNotification(message.data);
        _openIncoming(message.data);
      }
    });
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _openIncoming(message.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && initial.data['type'] == 'incoming_call') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openIncoming(initial.data));
    }
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _openIncoming(Map<String, dynamic>.from(jsonDecode(payload)));
        } catch (_) {}
      });
    }
  }

  static Future<void> initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          _openIncoming(Map<String, dynamic>.from(jsonDecode(payload)));
        } catch (_) {}
      },
    );
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
    await android?.requestFullScreenIntentPermission();
  }

  static Future<void> showIncomingNotification(
      Map<String, dynamic> data) async {
    if (data['type'] != 'incoming_call' || data['callId'] == null) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive),
    );
    await _localNotifications.show(
      data['callId'].hashCode,
      'Incoming video consultation',
      '${data['doctorName'] ?? 'Your doctor'} is ready to consult',
      details,
      payload: jsonEncode(data),
    );
  }

  static Future<void> cancelNotification(String callId) async {
    await _localNotifications.cancel(callId.hashCode);
  }

  static Future<void> registerToken(String token) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('token');
    if (jwt == null || jwt.isEmpty) return;
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    try {
      await ApiService.registerCallDevice(token: token, platform: platform);
    } catch (error) {
      debugPrint('Call push registration failed: $error');
    }
  }

  static Future<void> registerCurrentDevice() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registerToken(token);
    } catch (error) {
      debugPrint('Unable to obtain FCM token: $error');
    }
  }

  static Future<void> unregisterCurrentDevice() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await ApiService.removeCallDevice(token: token);
    } catch (error) {
      debugPrint('Call push unregistration failed: $error');
    }
  }

  static void _openIncoming(Map<String, dynamic> data) {
    final callId = data['callId']?.toString() ?? '';
    final appointmentId = data['appointmentId']?.toString() ?? '';
    if (callId.isEmpty ||
        appointmentId.isEmpty ||
        _navigatorKey?.currentState == null ||
        !_shownCalls.add(callId)) {
      return;
    }
    _navigatorKey!.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => IncomingVideoCallScreen(
        callId: callId,
        appointmentId: appointmentId,
        doctorName: data['doctorName']?.toString() ?? 'Your doctor',
        doctorImage: data['doctorImage']?.toString() ?? '',
        onClosed: () => _shownCalls.remove(callId),
      ),
      fullscreenDialog: true,
    ));
  }
}
