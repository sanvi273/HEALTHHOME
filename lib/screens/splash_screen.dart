import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';

import '../pharmacy_dashboard.dart';
import '../lab_dashboard.dart';
import '../doctor_dashboard.dart';

import 'patient/patient_main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _restoreSession();
  }

  // =========================================================
  // RESTORE LAST LOGIN
  // =========================================================

  Future<void> _restoreSession() async {

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final prefs =
        await SharedPreferences.getInstance();

    final bool isLoggedIn =
        prefs.getBool("isLoggedIn") ?? false;

    final String role =
        prefs.getString("userRole") ?? "";

    final String phone =
        prefs.getString("userPhone") ?? "";

    final String name =
        prefs.getString("userName") ?? "";

    debugPrint("================================");
    debugPrint("RESTORING LAST LOGIN");
    debugPrint("isLoggedIn = $isLoggedIn");
    debugPrint("role       = $role");
    debugPrint("phone      = $phone");
    debugPrint("name       = $name");
    debugPrint("================================");

    // =======================================================
    // USER HAS NOT LOGGED IN
    // =======================================================

    if (!isLoggedIn ||
        role.trim().isEmpty ||
        phone.trim().isEmpty) {

      debugPrint(
        "❌ NO SAVED LOGIN",
      );

      _openOnboarding();

      return;
    }

    // =======================================================
    // USER IS STILL LOGGED IN
    // =======================================================

    final normalizedRole =
        role.trim().toLowerCase();

    debugPrint(
      "✅ USER STILL LOGGED IN",
    );

    debugPrint(
      "➡️ RESTORING: $normalizedRole",
    );

    // =======================================================
    // PATIENT
    // =======================================================

    if (normalizedRole == "patient") {

      _openPage(
        const PatientMain(),
      );

      return;
    }

    // =======================================================
    // DOCTOR
    // =======================================================

    if (normalizedRole == "doctor") {

      _openPage(
        const DoctorDashboard(),
      );

      return;
    }

    // =======================================================
    // LAB
    // =======================================================

    if (normalizedRole == "lab" ||
        normalizedRole == "laboratory") {

      _openPage(
        const LaboratoryDashboard(),
      );

      return;
    }

    // =======================================================
    // PHARMACY
    // =======================================================

    if (normalizedRole == "pharmacy") {

      _openPage(
        const PharmacyDashboard(),
      );

      return;
    }

    // =======================================================
    // UNKNOWN ROLE
    // =======================================================

    debugPrint(
      "❌ UNKNOWN SAVED ROLE",
    );

    await _clearSession();

    _openOnboarding();
  }

  // =========================================================
  // OPEN LAST MODULE
  // =========================================================

  void _openPage(Widget page) {

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
      (route) => false,
    );
  }

  // =========================================================
  // OPEN ONBOARDING
  // =========================================================

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

  // =========================================================
  // CLEAR SESSION
  // =========================================================

  Future<void> _clearSession() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove("isLoggedIn");
    await prefs.remove("userRole");
    await prefs.remove("userPhone");
    await prefs.remove("userName");
    await prefs.remove("token");
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration:
            const BoxDecoration(

          gradient:
              LinearGradient(

            colors: [
              Color(0xff0F5FFF),
              Color(0xff00D2FF),
            ],

            begin:
                Alignment.topLeft,

            end:
                Alignment.bottomRight,
          ),
        ),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Image.asset(
              "assets/images/logo.png",
              height: 180,
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              "HealthHome",

              style:
                  TextStyle(

                color:
                    Colors.white,

                fontSize:
                    34,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              "Healthcare at Your Doorstep",

              style:
                  TextStyle(

                color:
                    Colors.white70,

                fontSize:
                    16,
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            const SizedBox(
              width: 28,
              height: 28,

              child:
                  CircularProgressIndicator(
                color:
                    Colors.white,

                strokeWidth:
                    3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}