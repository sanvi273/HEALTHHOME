import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/api_service.dart';

import 'screens/onboarding_screen.dart';

import 'pharmacy_dashboard.dart';
import 'lab_dashboard.dart';
import 'doctor_dashboard.dart';

import 'screens/patient/patient_main.dart';
import 'screens/patient/profile_setup_page.dart';

import 'doctor_profile_setup.dart';
import 'lab_profile_setup.dart';
import 'pharmacy_profile_setup.dart';
import 'professional_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================= CONTROLLERS =================

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController nameController = TextEditingController();

  // ================= ADDRESS CONTROLLERS =================

  final TextEditingController fullAddressController = TextEditingController();

  final TextEditingController landmarkController = TextEditingController();

  final TextEditingController cityController = TextEditingController();

  final TextEditingController stateController = TextEditingController();

  final TextEditingController pincodeController = TextEditingController();

  String selectedAddressLabel = "Home";

  double? selectedLatitude;
  double? selectedLongitude;

  bool isGettingLocation = false;

  // ================= VARIABLES =================

  bool isLogin = true;

  bool isLoading = false;

  // ================= DISPOSE =================

  @override
  void dispose() {
    phoneController.dispose();

    passwordController.dispose();

    nameController.dispose();

    fullAddressController.dispose();
    landmarkController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    super.dispose();
  }

  // =========================================================
  // ======================== BUILD ==========================
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ================= BACK BUTTON =================

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 28,
                    color: Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 25),

                // ================= TITLE =================

                Text(
                  isLogin ? "welcomeBack".tr() : "createAccount".tr(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= SUBTITLE =================

                Text(
                  isLogin
                      ? "${'loginAs'.tr()} ${widget.role}"
                      : "signUpToGetStarted".tr(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 35),

                // =================================================
                // ================= LOGIN / SIGNUP TAB ============
                // =================================================

                Row(
                  children: [
                    // ================= LOGIN =================

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = true;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "login".tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLogin
                                  ? const Color(
                                      0xff00C2CB,
                                    )
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            width: 55,
                            decoration: BoxDecoration(
                              color: isLogin
                                  ? const Color(
                                      0xff00C2CB,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 35),

                    // ================= SIGN UP =================

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = false;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "signUp".tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: !isLogin
                                  ? const Color(
                                      0xff00C2CB,
                                    )
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            width: 70,
                            decoration: BoxDecoration(
                              color: !isLogin
                                  ? const Color(
                                      0xff00C2CB,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // =================================================
                // ================= FULL NAME =====================
                // =================================================

                if (!isLogin)
                  buildField(
                    controller: nameController,
                    hint: "fullName".tr(),
                    icon: Icons.person,
                    keyboardType: TextInputType.name,
                  ),

                // =================================================
                // ================= ADDRESS =======================
                // =================================================

                if (!isLogin) ...[
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAddressLabel,
                    decoration: InputDecoration(
                      hintText: "addressType".tr(),
                      prefixIcon: const Icon(
                        Icons.label_outline,
                        color: Color(0xff00C2CB),
                      ),
                      filled: true,
                      fillColor: const Color(0xffF5F7FB),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "Home",
                        child: Text("home".tr()),
                      ),
                      DropdownMenuItem(
                        value: "Work",
                        child: Text("work".tr()),
                      ),
                      DropdownMenuItem(
                        value: "College",
                        child: Text("college".tr()),
                      ),
                      DropdownMenuItem(
                        value: "Other",
                        child: Text("other".tr()),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedAddressLabel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isGettingLocation ? null : useCurrentLocation,
                      icon: isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                            ),
                      label: Text(
                        isGettingLocation
                            ? "gettingCurrentLocation".tr()
                            : "useCurrentLocation".tr(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff00AAB3),
                        side: const BorderSide(
                          color: Color(0xff00C2CB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildField(
                    controller: fullAddressController,
                    hint: "fullAddress".tr(),
                    icon: Icons.home_outlined,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  buildField(
                    controller: landmarkController,
                    hint: "landmarkOptional".tr(),
                    icon: Icons.location_on_outlined,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  buildField(
                    controller: cityController,
                    hint: "city".tr(),
                    icon: Icons.location_city,
                    keyboardType: TextInputType.text,
                  ),
                  buildField(
                    controller: stateController,
                    hint: "state".tr(),
                    icon: Icons.map_outlined,
                    keyboardType: TextInputType.text,
                  ),
                  buildField(
                    controller: pincodeController,
                    hint: "pincode".tr(),
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],

                // =================================================
                // ================= PHONE =========================
                // =================================================

                buildField(
                  controller: phoneController,
                  hint: "mobileNumber".tr(),
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                // =================================================
                // ================= PASSWORD ======================
                // =================================================

                buildField(
                  controller: passwordController,
                  hint: "password".tr(),
                  icon: Icons.lock,
                  obscure: true,
                ),

                const SizedBox(height: 30),

                // =================================================
// ================= LOGIN BUTTON ==================
// =================================================

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xff00C2CB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            // =================================================
                            // LOGIN / SIGNUP → EXISTING FLOW
                            // =================================================

                            await handleSubmit();
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            isLogin ? "login".tr() : "signUp".tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 35),

                const SizedBox(height: 30),

                // =================================================
                // ================= BOTTOM SWITCH =================
                // =================================================

                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: isLogin
                            ? "newHere".tr()
                            : "alreadyHaveAccount".tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: isLogin ? "signUp".tr() : "login".tr(),
                            style: const TextStyle(
                              color: Color(
                                0xff00C2CB,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ====================== HANDLE SUBMIT ====================
  // =========================================================

  Future<void> handleSubmit() async {
    // ================= PHONE VALIDATION =================

    final phone = phoneController.text.trim();

    final password = passwordController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "validMobileNumber".tr(),
          ),
        ),
      );

      return;
    }

    // ================= PASSWORD VALIDATION =================

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "passwordMinimum".tr(),
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =====================================================
      // ======================= LOGIN ========================
      // =====================================================

      if (isLogin) {
        await handleLogin(
          phone,
          password,
        );
      }

      // =====================================================
      // ====================== SIGN UP =======================
      // =====================================================

      else {
        await handleSignUp(
          phone,
          password,
        );
      }
    } catch (e) {
      debugPrint(
        "SUBMIT ERROR = $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // ======================== LOGIN ==========================
  // =========================================================

  Future<void> handleLogin(
    String phone,
    String password,
  ) async {
    final response = await ApiService.loginUser(
      phone: phone,
      password: password,
    );

    // ================= LOGIN FAILED =================

    if (response["success"] != true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"]?.toString() ?? "loginFailed".tr(),
          ),
        ),
      );

      return;
    }

    // ================= GET USER DATA =================

    final user = response["user"];

    if (user == null) {
      throw Exception(
        "userDataNotReceived".tr(),
      );
    }

    final String userRole = user["role"].toString().toLowerCase();

    final String userName = user["name"].toString();

    final String userPhone = user["phone"].toString();

    // =====================================================
    // ================= SHARED PREFERENCES =================
    // =====================================================

    final prefs = await SharedPreferences.getInstance();

    // =====================================================
    // SAVE LOGIN TOKEN BEFORE VERIFICATION CHECK
    // =====================================================

    final String loginToken = response["token"]?.toString() ?? "";

    if (loginToken.isEmpty) {
      throw Exception(
        "Login token not received from server",
      );
    }

    await prefs.setString(
      "token",
      loginToken,
    );

    await prefs.setBool(
      "isLoggedIn",
      true,
    );

    debugPrint(
      "LOGIN TOKEN SAVED BEFORE VERIFICATION CHECK",
    );
    // =====================================================
    // PROFESSIONAL VERIFICATION CHECK
    // =====================================================

    final String verificationStatus =
        user["verificationStatus"]?.toString().toUpperCase() ?? "NOT_REQUIRED";

    final String verificationId = user["verificationId"]?.toString() ?? "";

    debugPrint(
      "VERIFICATION STATUS = $verificationStatus",
    );

    debugPrint(
      "VERIFICATION ID = $verificationId",
    );

    // =====================================================
    // CHECK PROFESSIONAL ACCOUNT
    // =====================================================

    final bool isProfessional = userRole == "doctor" ||
        userRole == "laboratory" ||
        userRole == "lab" ||
        userRole == "pharmacy";

    // =====================================================
    // BLOCK PROFESSIONAL IF NOT APPROVED
    // =====================================================

    if (isProfessional && verificationStatus != "APPROVED") {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalVerificationScreen(
            role: userRole,
          ),
        ),
      );

      return;
    }

    debugPrint(
      "================================",
    );

    debugPrint(
      "LOGIN SUCCESS",
    );

    debugPrint(
      "USER NAME  = $userName",
    );

    debugPrint(
      "USER PHONE = $userPhone",
    );

    debugPrint(
      "USER ROLE  = $userRole",
    );

    debugPrint(
      "================================",
    );

    // =====================================================
    // ================= SHARED PREFERENCES =================
    // =====================================================

    // Token and login state were already saved before the
    // professional verification check. Continue saving the
    // remaining user information here.

    await prefs.setString(
      "token",
      response["token"]?.toString() ?? "",
    );

    await prefs.setBool(
      "isLoggedIn",
      true,
    );

    await prefs.setString(
      "userName",
      userName,
    );

    await prefs.setString(
      "userPhone",
      userPhone,
    );

    await prefs.setString(
      "userRole",
      userRole,
    );

    // =====================================================
    // ================= ROLE DATA ==========================
    // =====================================================

    if (userRole == "patient") {
      await prefs.setString(
        "patientName",
        userName,
      );

      await prefs.setString(
        "patientPhone",
        userPhone,
      );
    } else if (userRole == "doctor") {
      await prefs.setString(
        "doctorName",
        userName,
      );

      await prefs.setString(
        "doctorPhone",
        userPhone,
      );
    } else if (userRole == "lab" || userRole == "laboratory") {
      await prefs.setString(
        "labName",
        userName,
      );

      await prefs.setString(
        "labPhone",
        userPhone,
      );
    } else if (userRole == "pharmacy") {
      await prefs.setString(
        "pharmacyName",
        userName,
      );

      await prefs.setString(
        "pharmacyPhone",
        userPhone,
      );
    }

    // =====================================================
    // ================= ONESIGNAL =========================
    // =====================================================

    try {
      final pushSubscription = OneSignal.User.pushSubscription;

      final String? oneSignalId = pushSubscription.id;

      if (oneSignalId != null) {
        await ApiService.updateOneSignalId(
          phone: userPhone,
          oneSignalId: oneSignalId,
        );
      }

      debugPrint(
        "ONESIGNAL ID = $oneSignalId",
      );
    } catch (e) {
      // OneSignal failure should NOT stop login.

      debugPrint(
        "ONESIGNAL UPDATE ERROR = $e",
      );
    }

    // =====================================================
    // ================= LOGIN MESSAGE =====================
    // =====================================================

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "loginSuccessful".tr(),
        ),
      ),
    );

    // =====================================================
    // ================= PROFILE ROUTING ===================
    // =====================================================

    await navigateAfterLogin(
      userRole,
      userPhone,
    );
  }

// =========================================================
// ================= PROFILE NAVIGATION ===================
// =========================================================

  Future<void> navigateAfterLogin(
    String userRole,
    String phone,
  ) async {
    final role = userRole.trim().toLowerCase();

    final cleanPhone = phone.trim();

    debugPrint("================================");
    debugPrint("PROFILE NAVIGATION");
    debugPrint("ROLE  = $role");
    debugPrint("PHONE = $cleanPhone");
    debugPrint("================================");

    // =====================================================
    // ====================== PATIENT =======================
    // =====================================================

    if (role == "patient") {
      try {
        final profile = await ApiService.getProfile(
          cleanPhone,
        );

        debugPrint(
          "PATIENT PROFILE RESPONSE = $profile",
        );

        if (!mounted) return;

        if (profile["success"] == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const PatientMain(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileSetupPage(),
            ),
          );
        }
      } catch (e) {
        debugPrint(
          "PATIENT PROFILE ERROR = $e",
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to check patient profile: $e",
            ),
          ),
        );
      }

      return;
    }

    // =====================================================
    // ======================== LAB =========================
    // =====================================================

    if (role == "lab" || role == "laboratory") {
      try {
        debugPrint(
          "CHECKING LAB PROFILE",
        );

        debugPrint(
          "LAB PHONE = $cleanPhone",
        );

        final profile = await ApiService.getLabProfile(
          cleanPhone,
        );

        debugPrint(
          "LAB PROFILE RESPONSE = $profile",
        );

        if (!mounted) return;

        if (profile["success"] == true && profile["lab"] != null) {
          debugPrint(
            "✅ EXISTING LAB FOUND",
          );

          final prefs = await SharedPreferences.getInstance();

          final lab = Map<String, dynamic>.from(
            profile["lab"],
          );

          await prefs.setString(
            "labName",
            lab["name"]?.toString() ?? "",
          );

          await prefs.setString(
            "labPhone",
            lab["phone"]?.toString() ?? cleanPhone,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LaboratoryDashboard(),
            ),
            (route) => false,
          );
        } else {
          debugPrint(
            "❌ LAB PROFILE NOT FOUND",
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LabProfileSetup(),
            ),
          );
        }
      } catch (e) {
        debugPrint(
          "❌ LAB PROFILE ERROR = $e",
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to check lab profile: $e",
            ),
          ),
        );
      }

      return;
    }

    // =====================================================
    // ====================== DOCTOR ========================
    // =====================================================

    if (role == "doctor") {
      try {
        debugPrint(
          "CHECKING DOCTOR PROFILE",
        );

        debugPrint(
          "DOCTOR PHONE = $cleanPhone",
        );

        final profile = await ApiService.getDoctorProfile(
          cleanPhone,
        );

        debugPrint(
          "DOCTOR PROFILE RESPONSE = $profile",
        );

        if (!mounted) return;

        if (profile["success"] == true && profile["doctor"] != null) {
          debugPrint(
            "✅ EXISTING DOCTOR FOUND",
          );

          final prefs = await SharedPreferences.getInstance();

          final doctor = Map<String, dynamic>.from(
            profile["doctor"],
          );

          await prefs.setString(
            "doctorName",
            doctor["name"]?.toString() ?? "",
          );

          await prefs.setString(
            "doctorPhone",
            doctor["phone"]?.toString() ?? cleanPhone,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const DoctorDashboard(),
            ),
            (route) => false,
          );
        } else {
          debugPrint(
            "❌ DOCTOR PROFILE NOT FOUND",
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DoctorProfileSetup(),
            ),
          );
        }
      } catch (e) {
        debugPrint(
          "❌ DOCTOR PROFILE ERROR = $e",
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to check doctor profile: $e",
            ),
          ),
        );
      }

      return;
    }

    // =====================================================
    // ===================== PHARMACY =======================
    // =====================================================

    if (role == "pharmacy") {
      try {
        debugPrint(
          "================================",
        );

        debugPrint(
          "CHECKING PHARMACY PROFILE",
        );

        debugPrint(
          "PHARMACY PHONE = $cleanPhone",
        );

        debugPrint(
          "================================",
        );

        // ===============================================
        // GET PHARMACY FROM MONGODB
        // ===============================================

        final profile = await ApiService.getPharmacyProfile(
          cleanPhone,
        );

        debugPrint(
          "PHARMACY PROFILE RESPONSE = $profile",
        );

        if (!mounted) return;

        // ===============================================
        // EXISTING PHARMACY
        // ===============================================

        if (profile["success"] == true && profile["pharmacy"] != null) {
          debugPrint(
            "✅ EXISTING PHARMACY FOUND",
          );

          final prefs = await SharedPreferences.getInstance();

          final pharmacy = Map<String, dynamic>.from(
            profile["pharmacy"],
          );

          // =============================================
          // SAVE REAL MONGODB DATA
          // =============================================

          await prefs.setString(
            "pharmacyName",
            pharmacy["name"]?.toString() ?? "",
          );

          await prefs.setString(
            "pharmacyPhone",
            pharmacy["phone"]?.toString() ?? cleanPhone,
          );

          debugPrint(
            "PHARMACY NAME = "
            "${pharmacy["name"]}",
          );

          debugPrint(
            "PHARMACY PHONE = "
            "${pharmacy["phone"]}",
          );

          debugPrint(
            "PHARMACY ADDRESS = "
            "${pharmacy["address"]}",
          );

          debugPrint(
            "PHARMACY SHOP TYPE = "
            "${pharmacy["shopType"]}",
          );

          debugPrint(
            "PHARMACY EXPERIENCE = "
            "${pharmacy["experience"]}",
          );

          debugPrint(
            "PHARMACY RATING = "
            "${pharmacy["rating"]}",
          );

          debugPrint(
            "➡️ OPENING PHARMACY DASHBOARD",
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const PharmacyDashboard(),
            ),
            (route) => false,
          );
        }

        // ===============================================
        // NEW PHARMACY
        // ===============================================

        else {
          debugPrint(
            "❌ PHARMACY PROFILE NOT FOUND",
          );

          debugPrint(
            "➡️ OPENING PHARMACY PROFILE SETUP",
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PharmacyProfileSetup(),
            ),
          );
        }
      } catch (e) {
        debugPrint(
          "❌ PHARMACY PROFILE ERROR = $e",
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to check pharmacy profile: $e",
            ),
          ),
        );
      }

      return;
    }

    // =====================================================
    // ================= UNKNOWN ROLE ======================
    // =====================================================

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unknown user role: $userRole",
        ),
      ),
    );
  }

  // =========================================================
  // ======================== SIGN UP ========================
  // =========================================================

  Future<void> handleSignUp(
    String phone,
    String password,
  ) async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your full name",
          ),
        ),
      );

      return;
    }

    // ================= ADDRESS VALIDATION =================

    final fullAddress = fullAddressController.text.trim();

    final city = cityController.text.trim();

    final state = stateController.text.trim();

    final pincode = pincodeController.text.trim();

    if (fullAddress.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        pincode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter complete address details",
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter a valid 6 digit pincode",
          ),
        ),
      );
      return;
    }

    final response = await ApiService.registerUser(
      name: name,
      email: "$phone@gmail.com",
      password: password,
      phone: phone,
      role: widget.role.toLowerCase(),
      label: selectedAddressLabel,
      fullAddress: fullAddressController.text.trim(),
      landmark: landmarkController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      pincode: pincodeController.text.trim(),
      latitude: selectedLatitude,
      longitude: selectedLongitude,
    );

    // ================= SIGNUP FAILED =================

    if (response["success"] != true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"]?.toString() ?? "Registration failed",
          ),
        ),
      );

      return;
    }

    // ================= SAVE BASIC STATE =================

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      "profileCompleted_$phone",
      false,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Account Created Successfully",
        ),
      ),
    );

    // Switch to login screen.

    setState(() {
      isLogin = true;

      passwordController.clear();
    });
  }

  // =========================================================
  // ================= CURRENT LOCATION =====================
  // =========================================================

  Future<void> useCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enable location services.",
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission is required.",
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      selectedLatitude = position.latitude;
      selectedLongitude = position.longitude;

      final Geocoding geocoding = Geocoding();

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final addressParts = <String>[
          if ((place.name ?? "").trim().isNotEmpty) place.name!.trim(),
          if ((place.street ?? "").trim().isNotEmpty &&
              place.street!.trim() != (place.name ?? "").trim())
            place.street!.trim(),
          if ((place.subLocality ?? "").trim().isNotEmpty)
            place.subLocality!.trim(),
        ];

        final readableAddress = addressParts.join(", ");

        if (readableAddress.isNotEmpty) {
          fullAddressController.text = readableAddress;
        }

        cityController.text =
            (place.locality ?? place.subAdministrativeArea ?? "").trim();

        stateController.text = (place.administrativeArea ?? "").trim();

        pincodeController.text = (place.postalCode ?? "").trim();

        if ((place.subLocality ?? "").trim().isNotEmpty) {
          landmarkController.text = place.subLocality!.trim();
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location detected. You can edit the address before signing up.",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "CURRENT LOCATION ERROR = $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to get current location: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // =========================================================
  // ======================= TEXT FIELD ======================
  // =========================================================

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: const Color(
              0xff00C2CB,
            ),
          ),
          filled: true,
          fillColor: const Color(
            0xffF5F7FB,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              18,
            ),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
