import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
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
  await IncomingCallService.initializeLocalNotifications(requestPermissions: false);
  await IncomingCallService.showIncomingNotification(message.data);
}

class IncomingCallService {
  static const MethodChannel _nativeCallChannel =
      MethodChannel('healthhome_tgcalls');
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final Set<String> _shownCalls = <String>{};
  static Timer? _ringTimeout;
  static Timer? _activeCallPoll;
  static String? _ringingCallId;
  static bool _isForeground = true;
  static bool _checkingActiveCalls = false;
  static final _IncomingCallLifecycleObserver _lifecycleObserver =
      _IncomingCallLifecycleObserver();
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
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _activeCallPoll ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isForeground) unawaited(checkActivePatientCalls());
    });
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

  static Future<void> initializeLocalNotifications(
      {bool requestPermissions = true}) async {
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
    if (requestPermissions) {
      await android?.requestNotificationsPermission();
      await android?.requestFullScreenIntentPermission();
    }
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
        showWhen: false,
        visibility: NotificationVisibility.public,
        timeoutAfter: 45000,
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

  static Future<bool> requestVideoCallPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _nativeCallChannel.invokeMethod<bool>('requestAvPermissions') ?? false;
    } on PlatformException catch (error) {
      debugPrint('Camera/microphone permission request failed: ${error.message}');
      return false;
    }
  }

  static Future<void> stopIncomingRingtone() async {
    _ringTimeout?.cancel();
    _ringTimeout = null;
    _ringingCallId = null;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _nativeCallChannel.invokeMethod<void>('stopIncomingRingtone');
    } catch (error) {
      debugPrint('Unable to stop incoming-call ringtone: $error');
    }
  }

  static void _startIncomingRingtone(String callId) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _ringTimeout?.cancel();
    _ringingCallId = callId;
    _nativeCallChannel.invokeMethod<bool>('startIncomingRingtone').catchError((error) {
      debugPrint('Unable to play incoming-call ringtone: $error');
      return false;
    });
    _ringTimeout = Timer(const Duration(seconds: 45), () {
      if (_ringingCallId == callId) unawaited(stopIncomingRingtone());
    });
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
      await checkActivePatientCalls();
    } catch (error) {
      debugPrint('Unable to obtain FCM token: $error');
    }
  }

  static Future<void> checkActivePatientCalls() async {
    if (_checkingActiveCalls || !_isForeground || kIsWeb) return;
    _checkingActiveCalls = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getString('userRole') ?? '').toLowerCase() != 'patient' ||
          (prefs.getString('token') ?? '').isEmpty) {
        return;
      }
      final calls = await ApiService.getActiveVideoCalls();
      for (final call in calls) {
        if (call['status']?.toString().toUpperCase() != 'RINGING') continue;
        presentIncomingCall({
          'type': 'incoming_call',
          'callId': call['callId']?.toString() ?? '',
          'appointmentId': call['appointmentId']?.toString() ?? '',
          'doctorName': call['doctorName']?.toString() ?? 'Your doctor',
        });
      }
    } catch (error) {
      debugPrint('Active incoming-call check failed: $error');
    } finally {
      _checkingActiveCalls = false;
    }
  }

  static void _setForeground(bool foreground) {
    _isForeground = foreground;
    if (foreground) unawaited(checkActivePatientCalls());
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
    _startIncomingRingtone(callId);
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

  static void presentIncomingCall(Map<String, dynamic> data) {
    _openIncoming(data);
  }
}

class _IncomingCallLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    IncomingCallService._setForeground(state == AppLifecycleState.resumed);
  }
}
