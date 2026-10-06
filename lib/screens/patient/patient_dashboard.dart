import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'appointments_page.dart';
import 'doctor_list_page.dart';
import 'lab_home_page.dart';
import 'pharmacy_page.dart';
import 'my_prescription_page.dart' as prescription;
import 'profile_page.dart';
import 'reports_page.dart';
import 'medicine_order_page.dart';
import 'lab_orders_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String userName = "";
  String patientPhone = "";

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    loadUser();
  }

  // ------------------------------------------------------------
  // LOAD PATIENT DATA
  // ------------------------------------------------------------

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = prefs.getString("patientName") ?? "Patient";
      patientPhone = prefs.getString("patientPhone") ?? "";
    });
  }

  // ------------------------------------------------------------
  // OPEN PROFILE
  // ------------------------------------------------------------

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // ==================================================
              // TOP ROW
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.end,

                children: [

                  GestureDetector(
                    onTap: openProfile,

                    child: const CircleAvatar(
                      radius: 23,

                      backgroundColor:
                          Color(0xffC8F7F9),

                      child: Icon(
                        Icons.person,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // GREETING
              // ==================================================

              Text(
                "${_greeting()}, $userName 👋",

                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00C2CB),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // SERVICES
              // ==================================================

              Row(
                children: [

                  // ------------------------------------------------
                  // DOCTOR CONSULTATION
                  // ------------------------------------------------

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DoctorsListPage(),
                          ),
                        );
                      },

                      child: _serviceCard(
                        'doctorConsultation'.tr(),
                        Icons.medical_services,
                        const Color(0xffEAF2FF),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ------------------------------------------------
                  // MEDICINE DELIVERY
                  // ------------------------------------------------

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PharmacyPage(),
                          ),
                        );
                      },

                      child: _serviceCard(
                        'medicineDelivery'.tr(),
                        Icons.local_pharmacy,
                        const Color(0xffEAFBF8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ------------------------------------------------
                  // HOME LAB TESTS
                  // ------------------------------------------------

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LabHomePage(),
                          ),
                        );
                      },

                      child: _serviceCard(
                        'homeLabTests'.tr(),
                        Icons.science,
                        const Color(0xffF4ECFF),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // DELIVERY BANNER
              // ==================================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xffEEF4FF),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      'fastDeliveryTitle'.tr(),

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'fastDeliverySubtitle'.tr(),

                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // QUICK ACCESS TITLE
              // ==================================================

              Text(
                'quickAccess'.tr(),

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // QUICK ACCESS
              // ==================================================

              Wrap(
                spacing: 12,
                runSpacing: 12,

                children: [

                  // ------------------------------------------------
                  // MY APPOINTMENTS
                  // ------------------------------------------------

                  SizedBox(
                    width: 110,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AppointmentsPage(),
                          ),
                        );
                      },

                      child: _quickCard(
                        'myAppointments'.tr(),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // MY PRESCRIPTIONS
                  // ------------------------------------------------

                  SizedBox(
                    width: 110,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                prescription
                                    .MyPrescriptionPage(),
                          ),
                        );
                      },

                      child: _quickCard(
                        'myPrescriptions'.tr(),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // LAB REPORTS
                  // ------------------------------------------------

                  SizedBox(
                    width: 110,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ReportsPage(),
                          ),
                        );
                      },

                      child: _quickCard(
                        'labReports'.tr(),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // MY MEDICINE ORDERS
                  // ------------------------------------------------

                  SizedBox(
                    width: 110,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const MedicineOrdersPage(),
                          ),
                        );
                      },

                      child: _quickCard(
                        'myMedicineOrders'.tr(),
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // MY LAB ORDERS
                  // ------------------------------------------------

                  SizedBox(
                    width: 110,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LabOrdersPage(),
                          ),
                        );
                      },

                      child: _quickCard(
                        'myLabOrders'.tr(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'goodMorning'.tr();
    }

    if (hour < 17) {
      return 'goodAfternoon'.tr();
    }

    return 'goodEvening'.tr();
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  static Widget _serviceCard(
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 170,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color,

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 42,
            color: const Color(0xff00C2CB),
          ),

          const Spacer(),

          Text(
            title,

            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACCESS CARD
  // ============================================================

  static Widget _quickCard(
    String title,
  ) {
    return Container(
      height: 90,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.grey.withOpacity(0.08),

            blurRadius: 8,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),

          child: Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}