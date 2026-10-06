import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'book_appointment_page.dart';

class DoctorProfilePage extends StatelessWidget {
  final Map doctor;

  const DoctorProfilePage({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // DOCTOR DATA
    // ============================================================

    final String doctorId =
        doctor["_id"]?.toString() ?? "";

    final String doctorName =
        doctor["name"]?.toString() ?? "";

    final String specialization =
        doctor["specialization"]?.toString() ?? "";

    final String experience =
        doctor["experience"]?.toString() ?? "N/A";

    final String hospital =
        doctor["hospital"]?.toString() ?? "N/A";

    final String fees =
        doctor["fees"]?.toString() ?? "0";

    final String about =
        doctor["about"]?.toString() ??
            "Experienced healthcare professional.";

    // ============================================================
    // DEBUG
    // ============================================================

    debugPrint("================================");
    debugPrint("DOCTOR PROFILE OPENED");
    debugPrint("DOCTOR ID = $doctorId");
    debugPrint("DOCTOR NAME = $doctorName");
    debugPrint("DOCTOR FEES = $fees");
    debugPrint("================================");

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      appBar: AppBar(
        title: Text(
          "doctorProfile".tr(),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ====================================================
            // DOCTOR IMAGE
            // ====================================================

            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor:
                    Colors.blue.shade100,

                child: const Icon(
                  Icons.person,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // DOCTOR NAME
            // ====================================================

            Center(
              child: Text(
                doctorName,

                style: const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            // ====================================================
            // SPECIALIZATION
            // ====================================================

            Center(
              child: Text(
                specialization,

                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ====================================================
            // EXPERIENCE
            // ====================================================

            _infoTile(
              Icons.work,
              "experience".tr(),
              experience,
            ),

            // ====================================================
            // HOSPITAL
            // ====================================================

            _infoTile(
              Icons.local_hospital,
              "hospital".tr(),
              hospital,
            ),

            // ====================================================
            // FEES
            // ====================================================

            _infoTile(
              Icons.currency_rupee,
              "consultationFee".tr(),
              "₹$fees",
            ),

            const SizedBox(height: 20),

            // ====================================================
            // ABOUT
            // ====================================================

            Text(
              "aboutDoctor".tr(),

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              about,
            ),

            const SizedBox(height: 40),

            // ====================================================
            // BOOK APPOINTMENT
            // ====================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () {

                  // ==============================================
                  // CHECK DOCTOR ID
                  // ==============================================

                  if (doctorId.isEmpty) {

                    debugPrint(
                      "❌ ERROR: DOCTOR ID IS EMPTY",
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          "doctorInformationIncomplete".tr(),
                        ),
                      ),
                    );

                    return;
                  }

                  // ==============================================
                  // DEBUG
                  // ==============================================

                  debugPrint(
                    "================================",
                  );

                  debugPrint(
                    "OPENING BOOK APPOINTMENT",
                  );

                  debugPrint(
                    "PASSING DOCTOR ID = $doctorId",
                  );

                  debugPrint(
                    "================================",
                  );

                  // ==============================================
                  // OPEN BOOK APPOINTMENT
                  // ==============================================

                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          BookAppointmentPage(
                        doctor: doctor,
                      ),
                    ),
                  );
                },

                child: Text(
                  "bookAppointment".tr(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO TILE
  // ============================================================

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}