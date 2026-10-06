import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import 'screens/patient/patient_main.dart';
import 'doctor_dashboard.dart';
import 'lab_dashboard.dart';
import 'pharmacy_dashboard.dart';

// ======================================================
// MAIN
// ======================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ====================================================
  // EASY LOCALIZATION
  // ====================================================

  await EasyLocalization.ensureInitialized();

  // ====================================================
  // FIREBASE
  // ====================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ====================================================
  // ONESIGNAL
  // ====================================================

  OneSignal.Debug.setLogLevel(
    OSLogLevel.verbose,
  );

  OneSignal.initialize(
    "ebea4754-636f-4c9a-a863-9902fe6ad7c0",
  );

  // ====================================================
  // FCM
  // ====================================================

  try {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    String? fcmToken =
        await FirebaseMessaging.instance.getToken();

    debugPrint("================================");
    debugPrint("FCM TOKEN = $fcmToken");

    debugPrint(
      "Permission = ${OneSignal.Notifications.permission}",
    );

    debugPrint(
      "Opted In = ${OneSignal.User.pushSubscription.optedIn}",
    );

    debugPrint(
      "Token = ${OneSignal.User.pushSubscription.token}",
    );

    debugPrint(
      "ID = ${OneSignal.User.pushSubscription.id}",
    );

    debugPrint("================================");
  } catch (e) {
    debugPrint(
      "FCM / ONESIGNAL ERROR = $e",
    );
  }

  // ====================================================
  // RUN APP
  // ====================================================

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
      ],

      path: 'lib/l10n',

      fallbackLocale: const Locale('en'),

      startLocale: const Locale('en'),

      child: const HealthHomeApp(),
    ),
  );
}

// ======================================================
// HEALTHHOME APP
// ======================================================

class HealthHomeApp extends StatelessWidget {
  const HealthHomeApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ==================================================
      // EASY LOCALIZATION
      // ==================================================

      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: context.supportedLocales,

      locale: context.locale,

      // ==================================================
      // APP TITLE
      // ==================================================

      title: "HealthHome",

      // ==================================================
      // THEME
      // ==================================================

      theme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Poppins',

        scaffoldBackgroundColor:
            Colors.white,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF18C5C5),
          brightness:
              Brightness.light,
        ),

        // ==================================================
        // APP BAR
        // ==================================================

        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              Colors.white,

          foregroundColor:
              Colors.black,

          elevation: 0,

          centerTitle: true,
        ),

        // ==================================================
        // BUTTON
        // ==================================================

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF18C5C5),

            foregroundColor:
                Colors.white,

            minimumSize:
                const Size(
              double.infinity,
              55,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  const BorderRadius.all(
                Radius.circular(12),
              ),
            ),
          ),
        ),

        // ==================================================
        // CARD
        // ==================================================

        cardTheme:
            const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),

        // ==================================================
        // TEXT THEME
        // ==================================================

        textTheme:
            const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.black,
          ),

          bodyMedium: TextStyle(
            color: Colors.black,
          ),

          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // ==================================================
      // INITIAL SCREEN
      // ==================================================

      home: const CheckLoginScreen(),
    );
  }
}

// ======================================================
// CHECK LOGIN SCREEN
// ======================================================

class CheckLoginScreen
    extends StatefulWidget {
  const CheckLoginScreen({
    super.key,
  });

  @override
  State<CheckLoginScreen>
      createState() =>
          _CheckLoginScreenState();
}

class _CheckLoginScreenState
    extends State<CheckLoginScreen> {

  // ====================================================
  // INIT
  // ====================================================

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  // ====================================================
  // RESTORE LAST LOGGED-IN USER
  // ====================================================

  Future<void> checkLogin() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    // ==================================================
    // SMALL SPLASH DELAY
    // ==================================================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    // ==================================================
    // LOGIN STATUS
    // ==================================================

    final bool isLoggedIn =
        prefs.getBool(
              "isLoggedIn",
            ) ??
            false;

    // ==================================================
    // ROLE
    // ==================================================

    final String role =
        prefs.getString(
              "userRole",
            ) ??
            "";

    // ==================================================
    // PHONE
    // ==================================================

    final String phone =
        prefs.getString(
              "userPhone",
            ) ??
            "";

    // ==================================================
    // NAME
    // ==================================================

    final String name =
        prefs.getString(
              "userName",
            ) ??
            "";

    // ==================================================
    // DEBUG
    // ==================================================

    debugPrint(
      "================================",
    );

    debugPrint(
      "RESTORING LAST LOGIN",
    );

    debugPrint(
      "isLoggedIn = $isLoggedIn",
    );

    debugPrint(
      "role       = $role",
    );

    debugPrint(
      "phone      = $phone",
    );

    debugPrint(
      "name       = $name",
    );

    debugPrint(
      "================================",
    );

    // ==================================================
    // NO LOGIN SESSION
    // ==================================================

    if (!isLoggedIn ||
        role.trim().isEmpty ||
        phone.trim().isEmpty) {

      debugPrint(
        "❌ NO VALID ACTIVE LOGIN",
      );

      _openOnboarding();

      return;
    }

    // ==================================================
    // NORMALIZE ROLE
    // ==================================================

    final normalizedRole =
        role.trim().toLowerCase();

    debugPrint(
      "✅ ACTIVE SESSION FOUND",
    );

    debugPrint(
      "➡️ RESTORING MODULE = $normalizedRole",
    );

    // ==================================================
    // PATIENT
    // ==================================================

    if (normalizedRole ==
        "patient") {

      debugPrint(
        "👤 RESTORING PATIENT DASHBOARD",
      );

      _openPage(
        const PatientMain(),
      );

      return;
    }

    // ==================================================
    // DOCTOR
    // ==================================================

    if (normalizedRole ==
        "doctor") {

      debugPrint(
        "👨‍⚕️ RESTORING DOCTOR DASHBOARD",
      );

      _openPage(
        const DoctorDashboard(),
      );

      return;
    }

    // ==================================================
    // LABORATORY
    // ==================================================

    if (normalizedRole ==
            "lab" ||
        normalizedRole ==
            "laboratory") {

      debugPrint(
        "🧪 RESTORING LAB DASHBOARD",
      );

      _openPage(
        const LaboratoryDashboard(),
      );

      return;
    }

    // ==================================================
    // PHARMACY
    // ==================================================

    if (normalizedRole ==
        "pharmacy") {

      debugPrint(
        "💊 RESTORING PHARMACY DASHBOARD",
      );

      _openPage(
        const PharmacyDashboard(),
      );

      return;
    }

    // ==================================================
    // UNKNOWN ROLE
    // ==================================================

    debugPrint(
      "❌ UNKNOWN ROLE = $normalizedRole",
    );

    await _clearSession();

    _openOnboarding();
  }

  // ====================================================
  // OPEN DASHBOARD
  // ====================================================

  void _openPage(
    Widget page,
  ) {

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder: (_) => page,
      ),

      (route) => false,
    );
  }

  // ====================================================
  // OPEN ONBOARDING
  // ====================================================

  void _openOnboarding() {

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const OnboardingScreen(),
      ),

      (route) => false,
    );
  }

  // ====================================================
  // CLEAR LOGIN SESSION
  // ====================================================

  Future<void> _clearSession() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      "isLoggedIn",
    );

    await prefs.remove(
      "userRole",
    );

    await prefs.remove(
      "userPhone",
    );

    await prefs.remove(
      "userName",
    );

    await prefs.remove(
      "token",
    );

    debugPrint(
      "🔴 LOGIN SESSION CLEARED",
    );
  }

  // ====================================================
  // UI
  // ====================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return const Scaffold(
      backgroundColor:
          Colors.white,

      body: Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF18C5C5),
        ),
      ),
    );
  }
}