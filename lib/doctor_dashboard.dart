import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'services/telegram/AgoraVideoCallPage.dart';
import 'screens/onboarding_screen.dart';
import 'prescription_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() =>
      _DoctorDashboardState();
}

class _DoctorDashboardState
    extends State<DoctorDashboard> {

  //==========================================
  // Bottom Navigation
  //==========================================

  int currentIndex = 0;

  //==========================================
  // Loading
  //==========================================

  bool isLoading = true;
  bool isOnline = true;

  
bool isUpdatingAvailability = false;
bool isSavingSchedule = false;

List<String> workingDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

String startTime = '10:00';
String endTime = '19:30';
String breakStart = '13:00';
String breakEnd = '14:00';

int slotDurationMinutes = 30;
int maxAppointmentsPerDay = 10;


  //==========================================
  // Doctor Details
  //==========================================

String doctorId = "";
String doctorName = "";
String doctorPhone = "";
String doctorHospital = "";
String doctorSpecialization = "";
String doctorExperience = "";
String doctorFees = "";
String doctorAbout = "";

//==========================================
// Appointment Lists
//==========================================
List<dynamic> appointments = [];

List<dynamic> pendingAppointments = [];

List<dynamic> acceptedAppointments = [];

List<dynamic> completedAppointments = [];
  //==========================================
  // INIT
  //==========================================

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await loadDoctor();
    await loadAppointments();
  }

  //==========================================
  // LOAD DOCTOR
  //==========================================

Future<void> loadDoctor() async {

  try {

    final prefs =
        await SharedPreferences.getInstance();

    // ================= BASIC LOGIN DATA =================

    final phone =
        prefs.getString("doctorPhone") ??
        prefs.getString("userPhone") ??
        "";

    final savedName =
        prefs.getString("doctorName") ??
        prefs.getString("userName") ??
        "";

    if (phone.isEmpty) {

      debugPrint(
        "❌ Doctor phone not found",
      );

      if (!mounted) return;

      setState(() {
        doctorName = savedName;
        isLoading = false;
      });

      return;
    }


    debugPrint(
      "================================",
    );

    debugPrint(
      "LOADING DOCTOR PROFILE",
    );

    debugPrint(
      "DOCTOR PHONE = $phone",
    );


    // =====================================================
    // =============== GET PROFILE FROM MONGODB ============
    // =====================================================

    final response =
        await ApiService.getDoctorProfile(
      phone,
    );


    debugPrint(
      "DOCTOR PROFILE RESPONSE = $response",
    );


    if (response["success"] == true &&
    response["doctor"] != null) {

  final doctor = response["doctor"];

  doctorId =
      doctor["_id"]?.toString() ?? "";

  doctorName =
      doctor["name"]?.toString() ??
      savedName;

  doctorPhone =
      doctor["phone"]?.toString() ??
      phone;


      // ================= MONGODB DATA =================

      doctorName =
          doctor["name"]?.toString() ??
          savedName;

      doctorPhone =
          doctor["phone"]?.toString() ??
          phone;

      doctorHospital =
          doctor["hospital"]?.toString() ??
          "";

      doctorSpecialization =
          doctor["specialization"]?.toString() ??
          "";

      doctorExperience =
          doctor["experience"]?.toString() ??
          "";

      doctorFees =
          doctor["fees"]?.toString() ??
          "";

      doctorAbout =
          doctor["about"]?.toString() ??
          "";

      // Load availability and schedule settings saved in MongoDB.
      isOnline = doctor["isAvailable"] is bool
          ? doctor["isAvailable"] as bool
          : true;

      final dynamic scheduleData = doctor["schedule"] is Map
          ? doctor["schedule"]
          : doctor;

      if (scheduleData is Map) {
        final days = scheduleData["workingDays"];
        if (days is List && days.isNotEmpty) {
          workingDays = days.map((day) => day.toString()).toList();
        }
        startTime = scheduleData["startTime"]?.toString() ?? startTime;
        endTime = scheduleData["endTime"]?.toString() ?? endTime;
        breakStart = scheduleData["breakStart"]?.toString() ?? breakStart;
        breakEnd = scheduleData["breakEnd"]?.toString() ?? breakEnd;
        slotDurationMinutes = int.tryParse(
              scheduleData["slotDurationMinutes"]?.toString() ?? "",
            ) ??
            slotDurationMinutes;
        maxAppointmentsPerDay = int.tryParse(
              scheduleData["maxAppointmentsPerDay"]?.toString() ?? "",
            ) ??
            maxAppointmentsPerDay;
      }


      // =================================================
      // OPTIONAL: CACHE THE LATEST DATA LOCALLY
      // =================================================

      await prefs.setString(
        "doctorName",
        doctorName,
      );

      await prefs.setString(
        "doctorPhone",
        doctorPhone,
      );

      await prefs.setString(
  "doctorId",
  doctorId,
);

      await prefs.setString(
        "doctorHospital",
        doctorHospital,
      );

      await prefs.setString(
        "doctorSpecialization",
        doctorSpecialization,
      );

      await prefs.setString(
        "doctorExperience",
        doctorExperience,
      );

      await prefs.setString(
        "doctorFees",
        doctorFees,
      );

      await prefs.setString(
        "doctorAbout",
        doctorAbout,
      );


      debugPrint(
        "✅ Doctor profile loaded from MongoDB",
      );

    } else {

      // =================================================
      // PROFILE NOT FOUND
      // =================================================

      debugPrint(
        "❌ Doctor profile not found",
      );

      doctorName =
          savedName;

      doctorPhone =
          phone;
    }


  } catch (e) {

    debugPrint(
      "❌ LOAD DOCTOR ERROR = $e",
    );

    // Keep basic login information
    // even if the API temporarily fails.

    final prefs =
        await SharedPreferences.getInstance();

    doctorName =
        prefs.getString("doctorName") ??
        prefs.getString("userName") ??
        "";

    doctorPhone =
        prefs.getString("doctorPhone") ??
        prefs.getString("userPhone") ??
        "";

  }


  if (!mounted) return;

  setState(() {
    isLoading = false;
  });
}

 //==========================================
// LOAD APPOINTMENTS
//==========================================

Future<void> loadAppointments() async {
  try {
    debugPrint("================================");
    debugPrint("LOADING DOCTOR APPOINTMENTS");
    debugPrint("DOCTOR ID = $doctorId");
    debugPrint("================================");

    if (doctorId.trim().isEmpty) {
      debugPrint("❌ Doctor ID is EMPTY");
      return;
    }

    final result =
        await ApiService.getDoctorAppointments(
      doctorId.trim(),
    );

    debugPrint(
      "API APPOINTMENT COUNT = ${result.length}",
    );

    // ==========================================================
    // CONVERT API RESULT INTO MAPS
    // ==========================================================

    final List<Map<String, dynamic>> loadedAppointments =
        result
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

    // ==========================================================
    // DEBUG EVERY APPOINTMENT
    // ==========================================================

    for (final appointment in loadedAppointments) {
      debugPrint(
        "--------------------------------",
      );

      debugPrint(
        "APPOINTMENT ID = ${appointment["_id"]}",
      );

      debugPrint(
        "PATIENT = ${appointment["patientName"]}",
      );

      debugPrint(
        "DOCTOR ID = ${appointment["doctorId"]}",
      );

      debugPrint(
        "DATE = ${appointment["appointmentDate"]}",
      );

      debugPrint(
        "TIME = ${appointment["appointmentTime"]}",
      );

      debugPrint(
        "STATUS = [${appointment["status"]}]",
      );

      debugPrint(
        "CONSULTATION = ${appointment["consultationType"]}",
      );
    }

    // ==========================================================
    // FILTER BY STATUS
    // ==========================================================

    final pending =
        loadedAppointments.where((appointment) {
      final status =
          appointment["status"]
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              "";

      return status == "pending";
    }).toList();

    final accepted =
        loadedAppointments.where((appointment) {
      final status =
          appointment["status"]
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              "";

      return status == "accepted" ||
          status == "upcoming";
    }).toList();

    final completed =
        loadedAppointments.where((appointment) {
      final status =
          appointment["status"]
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              "";

      return status == "completed";
    }).toList();

    // ==========================================================
    // UPDATE EVERYTHING
    // ==========================================================

    if (!mounted) return;

    setState(() {
      appointments = loadedAppointments;

      pendingAppointments = pending;

      acceptedAppointments = accepted;

      completedAppointments = completed;
    });

    // ==========================================================
    // FINAL DEBUG
    // ==========================================================

    debugPrint("================================");
    debugPrint(
      "TOTAL = ${appointments.length}",
    );
    debugPrint(
      "PENDING = ${pendingAppointments.length}",
    );
    debugPrint(
      "ACCEPTED = ${acceptedAppointments.length}",
    );
    debugPrint(
      "COMPLETED = ${completedAppointments.length}",
    );
    debugPrint("================================");

  } catch (e, stackTrace) {
    debugPrint(
      "❌ LOAD DOCTOR APPOINTMENTS ERROR = $e",
    );

    debugPrint(
      stackTrace.toString(),
    );
  }
}

  //==================================================
  // DOCTOR PROPOSES A NEW APPOINTMENT DATE/TIME
  //==================================================
  Future<void> proposeReschedule(dynamic appointment) async {
    final appointmentId = appointment["_id"]?.toString() ?? "";
    if (appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment ID is missing.")),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final reasonController = TextEditingController(
      text: "Doctor is unavailable at the original time",
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Propose Reschedule"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Choose a new date and time for this patient."),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        "${selectedDate.day.toString().padLeft(2, '0')}/"
                        "${selectedDate.month.toString().padLeft(2, '0')}/"
                        "${selectedDate.year}",
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedTime.format(dialogContext)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Reason for rescheduling",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Please enter a reason.")),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text("Send Proposal"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      reasonController.dispose();
      return;
    }

    final dateApi =
        "${selectedDate.year.toString().padLeft(4, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";
    final timeApi = selectedTime.format(context);

    try {
      final response = await ApiService.proposeAppointmentReschedule(
        appointmentId: appointmentId,
        proposedAppointmentDate: dateApi,
        proposedAppointmentTime: timeApi,
        rescheduleReason: reasonController.text.trim(),
      );

      if (!mounted) return;
      if (response["success"] == false) {
        throw Exception(response["message"] ?? "Proposal could not be sent.");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reschedule proposal sent to the patient."),
        ),
      );
      await loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to propose reschedule: $e")),
      );
    } finally {
      reasonController.dispose();
    }
  }

  //==========================================
  // ACCEPT
  //==========================================

  Future<void> acceptAppointment(
      dynamic appointment) async {

    await ApiService.updateAppointmentStatus(
      id: appointment["_id"],
      status: "Accepted",
    );

    await loadAppointments();
  }

  //==========================================
  // REJECT
  //==========================================

  Future<void> rejectAppointment(
      dynamic appointment) async {

    await ApiService.updateAppointmentStatus(
      id: appointment["_id"],
      status: "Rejected",
    );

    await loadAppointments();
  }
    //==================================================
  // BUILD
  //==================================================

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [

      casesPage(),

      schedulePage(),

      prescriptionPage(),

      profilePage(),

    ];

    return Scaffold(

      backgroundColor: const Color(0xffF4F7FB),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        selectedItemColor: const Color(0xff14B8A6),

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        onTap: (index) {

          setState(() {

            currentIndex = index;

          });

        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Cases",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Schedule",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: "Prescription",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),

        ],

      ),

    );

  }

  //==================================================
  // DASHBOARD CARD
  //==================================================

Widget dashboardCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(
        vertical: 22,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}

  

  //==================================================
  // CASES PAGE
  //==================================================
Widget casesPage() {
  final cleanName = doctorName.trim();

  final displayName =
      cleanName.toLowerCase().startsWith("dr.")
          ? cleanName
          : "Dr. $cleanName";

  // Patient requests to choose another appointment time.
  final patientRescheduleRequests = appointments.where((item) {
    if (item is! Map) return false;
    final requestedBy =
        item["rescheduleRequestedBy"]?.toString().trim().toLowerCase() ?? "";
    final response =
        item["patientResponse"]?.toString().trim().toLowerCase() ?? "";
    return requestedBy == "patient" &&
        response == "requested another time";
  }).toList();

  return SafeArea(
    child: RefreshIndicator(
      onRefresh: loadAppointments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ======================================================
          // WELCOME
          // ======================================================

          Text(
            "Welcome $displayName",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            doctorSpecialization.trim(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 25),

          // ======================================================
          // COUNTERS
          // ======================================================

          Row(
            children: [
              dashboardCard(
                title: "Pending",
                value:
                    pendingAppointments.length.toString(),
                icon: Icons.pending_actions,
                color: const Color(0xff14B8A6),
              ),

              dashboardCard(
                title: "Accepted",
                value:
                    acceptedAppointments.length.toString(),
                icon: Icons.check_circle,
                color: const Color(0xff0F9D91),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              dashboardCard(
                title: "Completed",
                value:
                    completedAppointments.length.toString(),
                icon: Icons.task_alt,
                color: const Color(0xff17C3B2),
              ),

              dashboardCard(
                title:
                    isOnline ? "Online" : "Offline",
                value:
                    isOnline ? "ON" : "OFF",
                icon: Icons.wifi,
                color:
                    isOnline
                        ? const Color(0xff14B8A6)
                        : Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // PATIENT RESCHEDULE REQUESTS
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Patient Reschedule Requests",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              if (patientRescheduleRequests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patientRescheduleRequests.length.toString(),
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (patientRescheduleRequests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_available, color: Colors.grey, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No patient reschedule requests",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            ...patientRescheduleRequests.map(
              (appointment) => patientRescheduleRequestCard(appointment),
            ),

          const SizedBox(height: 30),

          // ======================================================
          // PENDING TITLE
          // ======================================================

          const Text(
            "Pending Appointments",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // PENDING APPOINTMENTS
          // ======================================================

          if (pendingAppointments.isEmpty)

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: const Column(
                children: [

                  Icon(
                    Icons.event_busy,
                    size: 55,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No Pending Appointments",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )

          else

            Column(
              children: List.generate(
                pendingAppointments.length,
                (index) {
                  final appointment =
                      pendingAppointments[index];

                  return appointmentCard(
                    appointment,
                  );
                },
              ),
            ),

          const SizedBox(height: 30),
        ],
      ),
    ),
  );
}
    //==================================================
  // APPOINTMENT CARD
  //==================================================

 Widget patientRescheduleRequestCard(dynamic appointment) {
  final patientName =
      appointment["patientName"]?.toString().trim().isNotEmpty == true
          ? appointment["patientName"].toString().trim()
          : "Unknown Patient";
  final phone = appointment["patientPhone"]?.toString() ?? "";
  final date = appointment["appointmentDate"]?.toString() ?? "-";
  final time = appointment["appointmentTime"]?.toString() ?? "-";
  final reason = appointment["rescheduleReason"]?.toString().trim() ?? "";
  final appointmentId = appointment["_id"]?.toString() ?? "";

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.orange.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: const Icon(Icons.person, color: Colors.deepOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold,
                    )),
                    if (phone.isNotEmpty)
                      Text(phone, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.notifications_active, color: Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 14),
          Text("Original appointment: $date at $time"),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("Patient note: $reason"),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: appointmentId.isEmpty
                  ? null
                  : () => proposeReschedule(appointment),
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Propose a New Date & Time"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

 Widget appointmentCard(
  dynamic appointment,
) {
  final patientName =
      appointment["patientName"]
              ?.toString()
              .trim() ??
          "Unknown Patient";

  final patientPhone =
      appointment["patientPhone"]
              ?.toString()
              .trim() ??
          "";

  final appointmentDate =
      appointment["appointmentDate"]
              ?.toString()
              .trim() ??
          "";

  final appointmentTime =
      appointment["appointmentTime"]
              ?.toString()
              .trim() ??
          "";

  final consultationType =
      appointment["consultationType"]
              ?.toString()
              .trim() ??
          "Hospital Visit";

  final paymentStatus =
      appointment["paymentStatus"]
              ?.toString()
              .trim() ??
          "Pending";

  return Card(
    margin: const EdgeInsets.only(
      bottom: 18,
    ),

    elevation: 3,

    color: Colors.white,

    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(20),
    ),

    child: Padding(
      padding: const EdgeInsets.all(18),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ====================================================
          // PATIENT
          // ====================================================

          Row(
            children: [

              CircleAvatar(
                radius: 27,

                backgroundColor:
                    const Color(0xffE0F7F4),

                child: const Icon(
                  Icons.person,
                  color:
                      Color(0xff14B8A6),
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      patientName,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      patientPhone,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color:
                      Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  "Pending",
                  style: TextStyle(
                    color:
                        Colors.orange,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 12),

          // ====================================================
          // DATE
          // ====================================================

          Row(
            children: [

              const Icon(
                Icons.calendar_today,
                size: 20,
                color:
                    Color(0xff14B8A6),
              ),

              const SizedBox(width: 10),

              Text(
                appointmentDate,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ====================================================
          // TIME
          // ====================================================

          Row(
            children: [

              const Icon(
                Icons.access_time,
                size: 20,
                color:
                    Color(0xff14B8A6),
              ),

              const SizedBox(width: 10),

              Text(
                appointmentTime,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ====================================================
          // CONSULTATION TYPE
          // ====================================================

          Row(
            children: [

              Icon(
                consultationType ==
                        "Video Consultation"
                    ? Icons.video_call
                    : Icons.local_hospital,
                size: 21,
                color:
                    const Color(0xff14B8A6),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  consultationType,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ====================================================
          // PAYMENT
          // ====================================================

          Row(
            children: [

              const Icon(
                Icons.payment,
                size: 20,
                color:
                    Color(0xff14B8A6),
              ),

              const SizedBox(width: 10),

              Text(
                "Payment: $paymentStatus",
                style:
                    const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // ====================================================
          // REPORTS
          // ====================================================

          const SizedBox(height: 10),

          patientReportsSection(
            appointment,
          ),

          const SizedBox(height: 15),

          // ====================================================
          // PROPOSE RESCHEDULE
          // ====================================================
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => proposeReschedule(appointment),
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Propose Reschedule"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff0F9D91),
                side: const BorderSide(color: Color(0xff14B8A6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ====================================================
          // ACCEPT / REJECT
          // ====================================================

          Row(
            children: [

              Expanded(
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green,
                    foregroundColor:
                        Colors.white,
                    minimumSize:
                        const Size(
                      0,
                      50,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  onPressed: () async {
                    await acceptAppointment(
                      appointment,
                    );
                  },

                  icon: const Icon(
                    Icons.check,
                  ),

                  label: const Text(
                    "Accept",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                    minimumSize:
                        const Size(
                      0,
                      50,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  onPressed: () async {
                    await rejectAppointment(
                      appointment,
                    );
                  },

                  icon: const Icon(
                    Icons.close,
                  ),

                  label: const Text(
                    "Reject",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  //==================================================
  // SCHEDULE PAGE
  //==================================================

  Future<void> _pickScheduleTime(String field) async {
    String current;
    switch (field) {
      case 'start':
        current = startTime;
        break;
      case 'end':
        current = endTime;
        break;
      case 'breakStart':
        current = breakStart;
        break;
      default:
        current = breakEnd;
    }

    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      switch (field) {
        case 'start':
          startTime = formatted;
          break;
        case 'end':
          endTime = formatted;
          break;
        case 'breakStart':
          breakStart = formatted;
          break;
        case 'breakEnd':
          breakEnd = formatted;
          break;
      }
    });
  }

  Future<void> _saveDoctorSchedule() async {
    if (doctorId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor ID is missing. Please log in again.')),
      );
      return;
    }
    if (workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one working day.')),
      );
      return;
    }

    setState(() => isSavingSchedule = true);
    try {
      final response = await ApiService.updateDoctorSchedule(
        doctorId: doctorId,
        workingDays: workingDays,
        startTime: startTime,
        endTime: endTime,
        breakStart: breakStart,
        breakEnd: breakEnd,
        slotDurationMinutes: slotDurationMinutes,
        maxAppointmentsPerDay: maxAppointmentsPerDay,
      );

      if (!mounted) return;
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Schedule could not be saved');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor schedule saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save schedule: $e')),
      );
    } finally {
      if (mounted) setState(() => isSavingSchedule = false);
    }
  }

  Widget _timeSettingTile(String title, String value, String field) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.access_time, color: Color(0xff14B8A6)),
      onTap: () => _pickScheduleTime(field),
    );
  }

  Widget schedulePage() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await loadDoctor();
          await loadAppointments();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Doctor Schedule",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${acceptedAppointments.length} Accepted Appointments",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Working Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final day in [
                          'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                          'Friday', 'Saturday', 'Sunday',
                        ])
                          FilterChip(
                            label: Text(day.substring(0, 3)),
                            selected: workingDays.contains(day),
                            selectedColor: const Color(0xffD9F7F3),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!workingDays.contains(day)) workingDays.add(day);
                                } else {
                                  workingDays.remove(day);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const Divider(height: 28),
                    const Text('Consultation Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _timeSettingTile('Start time', startTime, 'start'),
                    _timeSettingTile('End time', endTime, 'end'),
                    const Divider(height: 24),
                    const Text('Break Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _timeSettingTile('Break starts', breakStart, 'breakStart'),
                    _timeSettingTile('Break ends', breakEnd, 'breakEnd'),
                    const Divider(height: 24),
                    DropdownButtonFormField<int>(
                      value: slotDurationMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Appointment slot duration',
                        border: OutlineInputBorder(),
                      ),
                      items: const [15, 20, 30, 45, 60]
                          .map((minutes) => DropdownMenuItem<int>(
                                value: minutes,
                                child: Text('$minutes minutes'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => slotDurationMinutes = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: maxAppointmentsPerDay,
                      decoration: const InputDecoration(
                        labelText: 'Maximum appointments per day',
                        border: OutlineInputBorder(),
                      ),
                      items: List<int>.generate(30, (i) => i + 1)
                          .map((count) => DropdownMenuItem<int>(
                                value: count,
                                child: Text('$count appointments'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => maxAppointmentsPerDay = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isSavingSchedule ? null : _saveDoctorSchedule,
                        icon: isSavingSchedule
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(isSavingSchedule ? 'Saving...' : 'Save Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff14B8A6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Accepted Appointments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (acceptedAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text("No Accepted Appointments", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else
              ...acceptedAppointments.map((appointment) => scheduleCard(appointment)),
          ],
        ),
      ),
    );
  }

  //==================================================
// PATIENT REPORTS
//==================================================

Widget patientReportsSection(
  dynamic appointment,
) {
  final reports = appointment["reports"];

  if (reports == null ||
      reports is! List ||
      reports.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [
      const Divider(),

      const SizedBox(height: 8),

      const Text(
        "Patient Reports",
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      ...reports.map<Widget>((report) {
        final fileType =
            report["fileType"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        final fileName =
            report["fileName"]
                    ?.toString()
                    .trim() ??
                "Patient Report";

        final fileUrl =
            report["fileUrl"]
                    ?.toString()
                    .trim() ??
                "";

        final isPdf =
            fileType.contains("pdf");

        return Container(
          width: double.infinity,

          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: Colors.grey.shade100,

            borderRadius:
                BorderRadius.circular(12),

            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),

          child: Row(
            children: [

              // ==========================================
              // FILE ICON
              // ==========================================

              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: isPdf
                      ? Colors.red.shade50
                      : Colors.blue.shade50,

                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf
                      : Icons.image,

                  color: isPdf
                      ? Colors.red
                      : Colors.blue,

                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              // ==========================================
              // FILE NAME
              // ==========================================

              Expanded(
                child: Text(
                  fileName,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ==========================================
              // VIEW BUTTON
              // ==========================================
SizedBox(
  width: 75,
  height: 40,
  child: ElevatedButton(
    onPressed: fileUrl.isEmpty
        ? null
        : () {
            _openPatientReport(
              fileUrl: fileUrl,
              fileName: fileName,
              isPdf: isPdf,
            );
          },

    style: ElevatedButton.styleFrom(
      backgroundColor:
          const Color(0xff14B8A6),

      foregroundColor: Colors.white,

      padding: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
    ),

    child: const Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [

        Icon(
          Icons.visibility,
          size: 17,
        ),

        SizedBox(width: 4),

        Text(
          "View",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
             
            ],
          ),
        );
      }),
    ],
  );
}

//==================================================
// OPEN PATIENT REPORT INSIDE APP
//==================================================

void _openPatientReport({
  required String fileUrl,
  required String fileName,
  required bool isPdf,
}) {
  if (fileUrl.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Report file is not available",
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) {
        if (isPdf) {
          // ==========================================
          // PDF VIEWER
          // ==========================================

          return Scaffold(
            appBar: AppBar(
              title: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor:
                  const Color(0xff14B8A6),
              foregroundColor: Colors.white,
            ),

            body: SfPdfViewer.network(
              fileUrl,
            ),
          );
        }

        // ==========================================
        // IMAGE VIEWER
        // ==========================================

        return Scaffold(
          backgroundColor: Colors.black,

          appBar: AppBar(
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            backgroundColor: Colors.black,

            foregroundColor: Colors.white,
          ),

          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,

              child: Image.network(
                fileUrl,

                fit: BoxFit.contain,

                loadingBuilder:
                    (
                      context,
                      child,
                      loadingProgress,
                    ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },

                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(20),

                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          Icon(
                            Icons
                                .broken_image_outlined,
                            color: Colors.white,
                            size: 60,
                          ),

                          SizedBox(height: 15),

                          Text(
                            "Unable to load image",
                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

 //==================================================
// SCHEDULE CARD
//==================================================

Widget scheduleCard(dynamic appointment) {
  final consultationType =
    appointment["consultationType"]?.toString().trim() ??
        "Hospital Visit";

final isVideo =
    consultationType.toLowerCase() == "video consultation";
debugPrint("================================");
debugPrint("CONSULTATION TYPE = [$consultationType]");
debugPrint("IS VIDEO = $isVideo");
debugPrint("APPOINTMENT ID = ${appointment["_id"]}");
debugPrint("================================");


  return Card(
    margin: const EdgeInsets.only(bottom: 18),
    elevation: 3,

    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),

    child: Padding(
      padding: const EdgeInsets.all(18),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ================= PATIENT =================

          Row(
            children: [

              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Colors.green.shade100,

                child: const Icon(
                  Icons.person,
                  color: Color(0xff0F9D91),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      appointment["patientName"]
                              ?.toString() ??
                          "",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      appointment["patientPhone"]
                              ?.toString() ??
                          "",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: const Text(
                  "Accepted",
                  style: TextStyle(
                    color: Color(0xff0F9D91),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ================= DATE =================

          Text(
            "📅 ${appointment["appointmentDate"]}",
            style: const TextStyle(
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          // ================= TIME =================

          Text(
            "🕒 ${appointment["appointmentTime"]}",
            style: const TextStyle(
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          // ================= CONSULTATION TYPE =================

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              color: const Color(0xff14B8A6)
                  .withOpacity(0.08),

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Row(
              children: [

                Icon(
                  isVideo
                      ? Icons.video_call
                      : Icons.local_hospital,
                  color:
                      const Color(0xff14B8A6),
                  size: 21,
                ),

                const SizedBox(width: 8),

                Text(
                  consultationType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xff0F9D91),
                  ),
                ),
              ],
            ),
          ),

          // ================= PATIENT REPORTS =================

          const SizedBox(height: 10),

          patientReportsSection(
            appointment,
          ),

          const SizedBox(height: 12),

          // ================= RESCHEDULE PROPOSAL =================
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => proposeReschedule(appointment),
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Propose Reschedule"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff0F9D91),
                side: const BorderSide(color: Color(0xff14B8A6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ================= ACTION =================

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton.icon(

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff14B8A6),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              icon: Icon(
                isVideo
                    ? Icons.video_call
                    : Icons.medical_services,
                color: Colors.white,
              ),

              label: Text(
                isVideo
                    ? "Start Video Consultation"
                    : "Start Checkup",

                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              onPressed: () async {

                // =================================================
                // VIDEO CONSULTATION
                // =================================================
if (isVideo) {
  try {
    // =================================================
    // 1. DOCTOR STARTS VIDEO CONSULTATION
    // =================================================

    debugPrint("================================");
    debugPrint("DOCTOR STARTING VIDEO CONSULTATION");
    debugPrint("APPOINTMENT ID = ${appointment["_id"]}");
    debugPrint("================================");

    final response = await ApiService.startConsultation(
      appointment["_id"].toString(),
    );

    debugPrint("START CONSULTATION RESPONSE = $response");

    if (response["success"] != true) {
      throw Exception(
        response["message"] ?? "Unable to start consultation",
      );
    }

    // =================================================
    // 2. GET UPDATED APPOINTMENT FROM BACKEND
    //    Backend creates meetingId here
    // =================================================

    final startedAppointment =
        response["appointment"] != null
            ? Map<String, dynamic>.from(
                response["appointment"],
              )
            : appointment;

    final appointmentId =
        startedAppointment["_id"]?.toString() ?? "";

    final meetingId =
        startedAppointment["meetingId"]?.toString() ?? "";

    debugPrint("================================");
    debugPrint("VIDEO CONSULTATION READY");
    debugPrint("APPOINTMENT ID = $appointmentId");
    debugPrint("MEETING ID = $meetingId");
    debugPrint(
      "CONSULTATION STATUS = "
      "${startedAppointment["consultationStatus"]}",
    );
    debugPrint("================================");

    if (appointmentId.isEmpty) {
      throw Exception("Appointment ID is missing");
    }

    if (meetingId.isEmpty) {
      throw Exception(
        "Meeting ID was not generated by backend",
      );
    }

    if (!mounted) return;

    // =================================================
    // 3. OPEN AGORA VIDEO CALL
    // =================================================

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraVideoCallPage(
          doctorName: doctorName,
          patientName:
              startedAppointment["patientName"]?.toString() ??
                  "Patient",
          appointmentId: appointmentId,
          meetingId: meetingId,
          isDoctor: true,
        ),
      ),
    );

    // =================================================
    // 4. REFRESH AFTER CALL
    //
    // AgoraVideoCallPage already calls
    // completeConsultation() for the doctor.
    //
    // Therefore DO NOT call updateAppointmentStatus()
    // here again.
    // =================================================

    if (result == true && mounted) {
      debugPrint(
        "✅ Doctor video consultation finished",
      );

      await loadAppointments();
    }
  } catch (e, stackTrace) {
    debugPrint(
      "❌ VIDEO CONSULTATION ERROR = $e",
    );

    debugPrint(
      stackTrace.toString(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unable to start consultation: $e",
        ),
      ),
    );
  }

  return;
}
                // =================================================
                // HOSPITAL CHECKUP
                // =================================================

                try {

                  await ApiService
                      .updateAppointmentStatus(
                    id: appointment["_id"],
                    status: "Completed",
                  );

                  await loadAppointments();

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Hospital checkup completed",
                      ),
                    ),
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Unable to complete checkup: $e",
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}


    //==================================================
  // PRESCRIPTION PAGE
  //==================================================

  Widget prescriptionPage() {

    return SafeArea(

      child: RefreshIndicator(

        onRefresh: loadAppointments,

        child: ListView(

          padding: const EdgeInsets.all(16),

          children: [

            const Text(

              "Prescription",

              style: TextStyle(

                fontSize: 28,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 8),

            Text(

              "${completedAppointments.length} Completed Consultations",

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 16,

              ),

            ),

            const SizedBox(height: 25),

            if (completedAppointments.isEmpty)

              Container(

                padding: const EdgeInsets.all(40),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(20),

                ),

                child: const Column(

                  children: [

                    Icon(

                      Icons.medication_outlined,

                      size: 70,

                      color: Colors.grey,

                    ),

                    SizedBox(height: 20),

                    Text(

                      "No Completed Consultations",

                      style: TextStyle(

                        fontSize: 18,

                        color: Colors.grey,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              )

            else

              ...completedAppointments.map(

                (appointment) {

                  return Card(

                    margin:
                        const EdgeInsets.only(
                      bottom: 18,
                    ),

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                    ),

                    child: Padding(

                      padding:
                          const EdgeInsets.all(
                        18,
                      ),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Row(

                            children: [

                              CircleAvatar(

                                radius: 28,

                                backgroundColor:
                                    const Color(
                                  0xff14B8A6,
                                ),

                                child: const Icon(

                                  Icons.person,

                                  color:
                                      Colors.white,

                                ),

                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              Expanded(

                                child: Column(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(

                                      appointment[
                                              "patientName"] ??
                                          "",

                                      style:
                                          const TextStyle(

                                        fontSize:
                                            20,

                                        fontWeight:
                                            FontWeight
                                                .bold,

                                      ),

                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(

                                      appointment[
                                              "patientPhone"] ??
                                          "",

                                      style:
                                          const TextStyle(

                                        color:
                                            Colors.grey,

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              Container(

                                padding:
                                    const EdgeInsets
                                        .symmetric(

                                  horizontal: 12,

                                  vertical: 6,

                                ),

                                decoration:
                                    BoxDecoration(

                                  color: Colors
                                      .green
                                      .shade100,

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              20),

                                ),

                                child: const Text(

                                  "Completed",

                                  style:
                                      TextStyle(

                                    color:
                                        Colors.green,

                                    fontWeight:
                                        FontWeight
                                            .bold,

                                  ),

                                ),

                              ),

                            ],

                          ),

                          const SizedBox(
                              height: 18),

                          Text(
                            "📅 ${appointment["appointmentDate"]}",
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "🕒 ${appointment["appointmentTime"]}",
                          ),

                          const SizedBox(height: 5),

                        

                          const SizedBox(
                              height: 20),

                          SizedBox(

                            width:
                                double.infinity,

                            height: 50,

                            child:
                                ElevatedButton.icon(

                              style:
                                  ElevatedButton
                                      .styleFrom(

                                backgroundColor:
                                    const Color(
                                  0xff14B8A6,
                                ),

                              ),

                              icon: const Icon(

                                Icons.edit_note,

                                color:
                                    Colors.white,

                              ),

                              label: const Text(

                                "Write Prescription",

                                style: TextStyle(

                                  color:
                                      Colors.white,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                ),

                              ),

                              onPressed: () async {

  final refresh = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PrescriptionScreen(
        appointment: appointment,
      ),
    ),
  );

  if (refresh == true) {
    await loadAppointments();
  }

},

                            ),

                          ),

                        ],

                      ),

                    ),

                  );

                },

              ),

          ],

        ),

      ),

    );

  }
    //==================================================
  // PROFILE PAGE
  //==================================================

  Widget profilePage() {

    return SafeArea(

      child: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          const SizedBox(height: 15),

          Center(

            child: CircleAvatar(

              radius: 55,

              backgroundColor: const Color(0xff14B8A6),

              child: Text(

                doctorName.isNotEmpty
                    ? doctorName[0].toUpperCase()
                    : "D",

                style: const TextStyle(

                  color: Colors.white,

                  fontSize: 40,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ),

          const SizedBox(height: 20),

          Center(

            child: Text(

              doctorName,

              style: const TextStyle(

                fontSize: 26,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

          const SizedBox(height: 8),

          Center(

            child: Text(

              doctorSpecialization,

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 17,

              ),

            ),

          ),

          const SizedBox(height: 30),

          profileTile(

            Icons.phone,

            "Phone",

            doctorPhone,

          ),

          profileTile(

            Icons.local_hospital,

            "Hospital",

            doctorHospital,

          ),

          profileTile(

            Icons.work,

            "Experience",

            doctorExperience,

          ),

          profileTile(

            Icons.currency_rupee,

            "Consultation Fees",

            doctorFees,

          ),

          profileTile(

            Icons.info,

            "About",

            doctorAbout,

          ),

          const SizedBox(height: 20),

          Card(

            shape: RoundedRectangleBorder(

              borderRadius:
                  BorderRadius.circular(18),

            ),

            child: SwitchListTile(

              activeThumbColor:
                  const Color(0xff14B8A6),

              title: const Text(

                "Available for Consultation",

                style: TextStyle(

                  fontWeight: FontWeight.bold,

                ),

              ),

              subtitle: Text(

                isOnline
                    ? "Online"
                    : "Offline",

              ),

              value: isOnline,

              
onChanged: isUpdatingAvailability
    ? null
    : (value) async {
        if (doctorId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor ID is missing.'),
            ),
          );
          return;
        }

        setState(() {
          isUpdatingAvailability = true;
        });

        try {
          await ApiService.updateDoctorAvailability(
            doctorId: doctorId,
            isAvailable: value,
          );

          if (!mounted) return;

          setState(() {
            isOnline = value;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value ? 'You are now online.' : 'You are now offline.',
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to update availability: $e'),
            ),
          );
        } finally {
          if (mounted) {
            setState(() {
              isUpdatingAvailability = false;
            });
          }
        }
      },


            ),

          ),

          const SizedBox(height: 35),

          SizedBox(

            height: 55,

            child: ElevatedButton.icon(

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.red,

                shape: RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(15),

                ),

              ),

              onPressed: logout,

              icon: const Icon(

                Icons.logout,

                color: Colors.white,

              ),

              label: const Text(

                "Logout",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

  //==================================================
  // PROFILE TILE
  //==================================================

  Widget profileTile(

    IconData icon,

    String title,

    String value,

  ) {

    return Card(

      margin: const EdgeInsets.only(bottom: 15),

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(18),

      ),

      child: ListTile(

        leading: CircleAvatar(

          backgroundColor:
              const Color(0xff14B8A6),

          child: Icon(

            icon,

            color: Colors.white,

          ),

        ),

        title: Text(title),

        subtitle: Text(

          value.isEmpty ? "-" : value,

        ),

      ),

    );

  }
    //==================================================
  // LOGOUT
  //==================================================

Future<void> logout() async {

  final prefs =
      await SharedPreferences.getInstance();

  // ==========================================
  // CLEAR ONLY LOGIN SESSION
  // ==========================================

  await prefs.remove("isLoggedIn");
  await prefs.remove("userRole");
  await prefs.remove("userPhone");
  await prefs.remove("userName");
  await prefs.remove("token");

  debugPrint("================================");
  debugPrint("DOCTOR LOGOUT");
  debugPrint("LOGIN SESSION CLEARED");
  debugPrint("================================");

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

}