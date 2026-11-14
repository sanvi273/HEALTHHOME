import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'lab_dashboard.dart';
import 'widgets/profile_image.dart';

class LabProfileSetup extends StatefulWidget {
  const LabProfileSetup({super.key});

  @override
  State<LabProfileSetup> createState() =>
      _LabProfileSetupState();
}

class _LabProfileSetupState
    extends State<LabProfileSetup> {

  final nameController =
      TextEditingController();

  final labTypeController =
      TextEditingController();

  final experienceController =
      TextEditingController();

  final addressController =
      TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadLabName();
  }

  Future<void> loadLabName() async {

    final prefs =
        await SharedPreferences.getInstance();

    nameController.text =
        prefs.getString("userName") ?? "";
  }


Future<void> saveLabProfile() async {
  setState(() {
    isLoading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();

    // Get the JWT token saved during login
    final token = prefs.getString("token") ?? "";

    if (token.isEmpty) {
      throw Exception("Login session expired. Please login again.");
    }

    final phone = prefs.getString("userPhone") ?? "";

    if (phone.isEmpty) {
      throw Exception("User phone number not found. Please login again.");
    }

    final result = await ApiService.addLab(
      token: token,
      name: nameController.text,
      labType: labTypeController.text,
      experience: experienceController.text,
      address: addressController.text,
      phone: phone,
    );

    if (result["success"] == true) {
      await prefs.setBool(
        "labProfileCompleted_$phone",
        true,
      );

      await prefs.setString(
        "labType",
        labTypeController.text,
      );

      await prefs.setString(
        "labAddress",
        addressController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lab Profile Saved"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LaboratoryDashboard(),
        ),
      );
    } else {
      throw Exception(
        result["message"] ?? "Unable to save Lab profile.",
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
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


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF4F7FB),

      appBar: AppBar(
        backgroundColor:
            const Color(0xff14B8A6),
        title: const Text(
          "Lab Profile Setup",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(
         children: [

  const SizedBox(height: 20),

  const ProfileImageEditor(
    accentColor: Color(0xff14B8A6),
    backgroundColor: Color(0xffD1FAF5),
    fallbackIcon: Icons.science,
  ),

  const SizedBox(height: 25),

  TextField(
    controller: nameController,
    readOnly: true,
    decoration: inputDecoration(
      "Lab Name",
    ),
  ),

  const SizedBox(height: 15),

  TextField(
    controller: labTypeController,
    decoration: inputDecoration(
      "Lab Type",
    ),
  ),

  const SizedBox(height: 15),

  TextField(
    controller: experienceController,
    decoration: inputDecoration(
      "Experience",
    ),
  ),

  const SizedBox(height: 15),

  TextField(
    controller: addressController,
    decoration: inputDecoration(
      "Address",
    ),
  ),

  const SizedBox(height: 30),

  SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(

      style: ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xff14B8A6),
      ),

      onPressed:
          isLoading
              ? null
              : saveLabProfile,

      child: isLoading

          ? const CircularProgressIndicator(
              color: Colors.white,
            )

          : const Text(
              "Save Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
    ),
  ),
],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(
      String hint) {

    return InputDecoration(

      hintText: hint,

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(16),

        borderSide:
            BorderSide.none,
      ),
    );
  }
}
