
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'professional_verification_screen.dart';

class DoctorProfileSetup extends StatefulWidget {
  const DoctorProfileSetup({super.key});

  @override
  State<DoctorProfileSetup> createState() =>
      _DoctorProfileSetupState();
}

class _DoctorProfileSetupState extends State<DoctorProfileSetup> {
  final nameController = TextEditingController();
  final specializationController = TextEditingController();
  final experienceController = TextEditingController();
  final feesController = TextEditingController();
  final hospitalController = TextEditingController();
  final aboutController = TextEditingController();

  final licenseNumberController = TextEditingController();
  final licenseTypeController = TextEditingController();
  final documentUrlController = TextEditingController();

  bool isLoading = false;

  static const Color primary = Color(0xff14B8A6);

  @override
  void initState() {
    super.initState();
    loadDoctorName();
  }

  Future<void> loadDoctorName() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      nameController.text = prefs.getString("userName") ?? "";
    });
  }

  Future<void> saveDoctorProfile() async {
    if (nameController.text.trim().isEmpty ||
        specializationController.text.trim().isEmpty ||
        experienceController.text.trim().isEmpty ||
        feesController.text.trim().isEmpty ||
        hospitalController.text.trim().isEmpty ||
        licenseNumberController.text.trim().isEmpty ||
        licenseTypeController.text.trim().isEmpty ||
        documentUrlController.text.trim().isEmpty) {
      _showMessage("Please complete all required fields.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";
      final phone = prefs.getString("userPhone") ?? "";

      if (token.isEmpty) {
        throw Exception("Login session expired. Please login again.");
      }

      if (phone.isEmpty) {
        throw Exception("Doctor phone number not found. Please login again.");
      }

      // STEP 1: Save the doctor's professional profile.
      //
      // IMPORTANT:
      // ApiService.addDoctor must be updated to send this JWT token.
final profileResult = await ApiService.addDoctor(
  token: token,
  name: nameController.text.trim(),
  phone: phone,
  specialization: specializationController.text.trim(),
  experience: experienceController.text.trim(),
  fees: feesController.text.trim(),
  hospital: hospitalController.text.trim(),
  about: aboutController.text.trim(),
);

      if (profileResult["success"] != true) {
        throw Exception(
          profileResult["message"] ?? "Unable to save doctor profile.",
        );
      }

      // STEP 2: Submit the doctor's verification application.
      final verificationResult = await ApiService.submitVerification(
        token: token,
        role: "doctor",
        licenseNumber: licenseNumberController.text.trim(),
        licenseType: licenseTypeController.text.trim(),
        documentUrl: documentUrlController.text.trim(),
        businessName: hospitalController.text.trim(),
      );

      if (verificationResult["success"] != true) {
        throw Exception(
          verificationResult["message"] ??
              "Unable to submit verification application.",
        );
      }

      // STEP 3: Save profile information locally.
      await prefs.setBool(
        "doctorProfileCompleted_$phone",
        true,
      );

      await prefs.setString(
        "doctorSpecialization",
        specializationController.text.trim(),
      );

      await prefs.setString(
        "doctorExperience",
        experienceController.text.trim(),
      );

      await prefs.setString(
        "doctorFees",
        feesController.text.trim(),
      );

      await prefs.setString(
        "doctorHospital",
        hospitalController.text.trim(),
      );

      await prefs.setString(
        "doctorAbout",
        aboutController.text.trim(),
      );

      if (!mounted) return;

      // STEP 4: Do NOT open DoctorDashboard before approval.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfessionalVerificationScreen(
            role: "doctor",
          ),
        ),
      );
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration inputDecoration(
    String hint, {
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff18343B),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: inputDecoration(hint, icon: icon),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    feesController.dispose();
    hospitalController.dispose();
    aboutController.dispose();
    licenseNumberController.dispose();
    licenseTypeController.dispose();
    documentUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Doctor Profile Setup",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xffD1FAF5),
              child: Icon(
                Icons.medical_services,
                size: 55,
                color: primary,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Complete Your Doctor Profile",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xff18343B),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Submit your professional details for admin verification.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),

            _sectionTitle(
              "Professional Information",
              "Enter your doctor profile details.",
            ),

            _field(
              nameController,
              "Doctor Name",
              icon: Icons.person_outline,
              readOnly: true,
            ),
            const SizedBox(height: 14),

            _field(
              specializationController,
              "Specialization",
              icon: Icons.medical_information_outlined,
            ),
            const SizedBox(height: 14),

            _field(
              experienceController,
              "Experience (e.g. 5 years)",
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 14),

            _field(
              feesController,
              "Consultation Fees",
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            _field(
              hospitalController,
              "Hospital / Clinic Name",
              icon: Icons.local_hospital_outlined,
            ),
            const SizedBox(height: 14),

            _field(
              aboutController,
              "About Doctor",
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            _sectionTitle(
              "Professional Verification",
              "Provide your registration and licence details.",
            ),

            _field(
              licenseTypeController,
              "Licence Type (e.g. Medical Registration)",
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 14),

            _field(
              licenseNumberController,
              "Medical Registration / Licence Number",
              icon: Icons.numbers,
            ),
            const SizedBox(height: 14),

            _field(
              documentUrlController,
              "Licence Document URL",
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Provide a secure link to your licence document. "
                "The actual file-upload integration will be connected separately.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : saveDoctorProfile,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Submit for Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
