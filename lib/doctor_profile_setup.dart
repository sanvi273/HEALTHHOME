import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'doctor_dashboard.dart';

class DoctorProfileSetup extends StatefulWidget {
  const DoctorProfileSetup({super.key});

  @override
  State<DoctorProfileSetup> createState() =>
      _DoctorProfileSetupState();
}

class _DoctorProfileSetupState
    extends State<DoctorProfileSetup> {

  final nameController =
      TextEditingController();

  final specializationController =
      TextEditingController();

  final experienceController =
      TextEditingController();

  final feesController =
      TextEditingController();

  final hospitalController =
      TextEditingController();

  final aboutController =
      TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDoctorName();
  }

  Future<void> loadDoctorName() async {

    final prefs =
        await SharedPreferences.getInstance();

    nameController.text =
        prefs.getString("userName") ?? "";
  }

  Future<void> saveDoctorProfile() async {

    setState(() {
      isLoading = true;
    });

    try {

     final prefs =
    await SharedPreferences.getInstance();

final result =
    await ApiService.addDoctor(
  name: nameController.text,
  phone:
      prefs.getString("userPhone") ?? "",
  specialization:
      specializationController.text,
  experience:
      experienceController.text,
  fees:
      feesController.text,
  hospital:
      hospitalController.text,
  about:
      aboutController.text,
);

if (result["success"] == true) 
      { 
        print(
  prefs.getBool(
    "doctorProfileCompleted_${prefs.getString("userPhone")}",
  ),
);
print(prefs.getKeys(),
);
         await prefs.setBool(
          "doctorProfileCompleted_${prefs.getString("userPhone")}",
          true,
          
        );

        await prefs.setString(
          "doctorSpecialization",
          specializationController.text,
        );

        await prefs.setString(
          "doctorExperience",
          experienceController.text,
        );

        await prefs.setString(
          "doctorFees",
          feesController.text,
        );

        await prefs.setString(
          "doctorHospital",
          hospitalController.text,
        );

        await prefs.setString(
          "doctorAbout",
          aboutController.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DoctorDashboard(),
          ),
        );
      }
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
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
          "Doctor Profile Setup",
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

            const CircleAvatar(
              radius: 55,
              backgroundColor:
                  Color(0xffD1FAF5),
              child: Icon(
                Icons.medical_services,
                size: 60,
                color: Color(0xff14B8A6),
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,
              readOnly: true,
              decoration:
                  inputDecoration(
                "Doctor Name",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  specializationController,
              decoration:
                  inputDecoration(
                "Specialization",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  experienceController,
              decoration:
                  inputDecoration(
                "Experience",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  feesController,
              decoration:
                  inputDecoration(
                "Consultation Fees",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  hospitalController,
              decoration:
                  inputDecoration(
                "Hospital / Clinic",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  aboutController,
              maxLines: 4,
              decoration:
                  inputDecoration(
                "About Doctor",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xff14B8A6,
                  ),
                ),

                onPressed:
                    isLoading
                        ? null
                        : saveDoctorProfile,

                child: isLoading

                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )

                    : const Text(
                        "Save Profile",
                        style: TextStyle(
                          color:
                              Colors.white,
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