import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/incoming_call_service.dart';
import '../services/telegram/AgoraVideoCallPage.dart';
import '../models/patient_report.dart';
import '../widgets/help_support_card.dart';
import '../widgets/ratings_card.dart';
import '../widgets/profile_image.dart';
import 'edit_profile_screen.dart';
import 'onboarding_screen.dart';
import '../prescription_screen.dart';
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

static Map<String, dynamic> _defaultSchedule() => {
  'workingDays': <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ],
  'startTime': '10:00',
  'endTime': '19:30',
  'breakStart': '13:00',
  'breakEnd': '14:00',
  'daySchedules': <Map<String, dynamic>>[
    for (final day in const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ])
      <String, dynamic>{
        'day': day,
        'enabled': day != 'Sunday',
        'startTime': '10:00',
        'endTime': '19:30',
        'breakStart': '13:00',
        'breakEnd': '14:00',
      },
  ],
  'slotDurationMinutes': 30,
  'maxAppointmentsPerDay': 10,
};

Map<String, dynamic> hospitalVisitSchedule = _defaultSchedule();
Map<String, dynamic> videoConsultationSchedule = _defaultSchedule();
String selectedScheduleType = 'Hospital Visit';

Map<String, dynamic> get _activeSchedule =>
    selectedScheduleType == 'Video Consultation'
        ? videoConsultationSchedule
        : hospitalVisitSchedule;

List<Map<String, dynamic>> _readDaySchedules(
  dynamic saved,
  List<String> workingDays,
  String startTime,
  String endTime,
  String breakStart,
  String breakEnd,
) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  final entries = saved is List
      ? saved.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList()
      : <Map<String, dynamic>>[];
  return weekdays.map((day) {
    final entry = entries.firstWhere(
      (item) => item['day']?.toString() == day,
      orElse: () => <String, dynamic>{},
    );
    return <String, dynamic>{
      'day': day,
      'enabled': entry['enabled'] is bool
          ? entry['enabled'] == true
          : workingDays.contains(day),
      'startTime': (entry['startTime'] ?? startTime).toString(),
      'endTime': (entry['endTime'] ?? endTime).toString(),
      'breakStart': (entry['breakStart'] ?? breakStart).toString(),
      'breakEnd': (entry['breakEnd'] ?? breakEnd).toString(),
    };
  }).toList();
}

Map<String, dynamic> _readSchedule(dynamic saved, dynamic legacy) {
  final defaults = _defaultSchedule();
  final savedMap = saved is Map ? saved : const <dynamic, dynamic>{};
  final legacyMap = legacy is Map ? legacy : const <dynamic, dynamic>{};
  final days = savedMap['workingDays'] ?? legacyMap['workingDays'];
  final workingDays = days is List && days.isNotEmpty
      ? days.map((day) => day.toString()).toList()
      : List<String>.from(defaults['workingDays'] as List);
  final startTime = (savedMap['startTime'] ?? legacyMap['startTime'] ?? defaults['startTime']).toString();
  final endTime = (savedMap['endTime'] ?? legacyMap['endTime'] ?? defaults['endTime']).toString();
  final breakStart = (savedMap['breakStart'] ?? legacyMap['breakStart'] ?? defaults['breakStart']).toString();
  final breakEnd = (savedMap['breakEnd'] ?? legacyMap['breakEnd'] ?? defaults['breakEnd']).toString();
  final rawDaySchedules = savedMap['daySchedules'] ?? legacyMap['daySchedules'];
  return {
    'workingDays': workingDays,
    'startTime': startTime,
    'endTime': endTime,
    'breakStart': breakStart,
    'breakEnd': breakEnd,
    'daySchedules': _readDaySchedules(
      rawDaySchedules,
      workingDays,
      startTime,
      endTime,
      breakStart,
      breakEnd,
    ),
    'slotDurationMinutes': int.tryParse(
          (savedMap['slotDurationMinutes'] ?? legacyMap['slotDurationMinutes'] ?? defaults['slotDurationMinutes']).toString(),
        ) ?? 30,
    'maxAppointmentsPerDay': int.tryParse(
          (savedMap['maxAppointmentsPerDay'] ?? legacyMap['maxAppointmentsPerDay'] ?? defaults['maxAppointmentsPerDay']).toString(),
        ) ?? 10,
  };
}


  //==========================================
  // Doctor Details
  //==========================================

String doctorId = "";
String doctorName = "";
String doctorPhone = "";
String doctorEmergencyNumber = "";
String doctorHospital = "";
String doctorAddress = "";
String doctorSpecialization = "";
String doctorExperience = "";
String doctorFees = "";
String doctorVideoConsultationFee = "";
String doctorHospitalVisitFee = "";
String doctorAbout = "";

//==========================================
// Appointment Lists
//==========================================
List<dynamic> appointments = [];

List<dynamic> pendingAppointments = [];

List<dynamic> acceptedAppointments = [];

List<dynamic> completedAppointments = [];

List<Map<String, dynamic>> doctorPrescriptionTemplates = [];
bool isLoadingDoctorPrescriptionTemplates = true;
String? doctorPrescriptionTemplatesError;
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
    loadDoctorPrescriptionTemplates();
  }

  Future<void> loadDoctorPrescriptionTemplates() async {
    if (mounted) {
      setState(() {
        isLoadingDoctorPrescriptionTemplates = true;
        doctorPrescriptionTemplatesError = null;
      });
    }

    try {
      final templates = await ApiService.getDoctorPrescriptionTemplates();
      if (!mounted) return;
      setState(() {
        doctorPrescriptionTemplates = templates;
        isLoadingDoctorPrescriptionTemplates = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingDoctorPrescriptionTemplates = false;
        doctorPrescriptionTemplatesError =
            error.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  //==========================================
  // LOAD DOCTOR
  //==========================================

Future<void> loadDoctor() async {

  try {

    final prefs =
        await SharedPreferences.getInstance();

    doctorAddress = prefs.getString("doctorAddress") ?? "";

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

      doctorEmergencyNumber =
          doctor["emergencyNumber"]?.toString() ?? doctorPhone;

      doctorHospital =
          doctor["hospital"]?.toString() ??
          "";
      doctorAddress = doctor["address"]?.toString() ?? "";

      doctorSpecialization =
          doctor["specialization"]?.toString() ??
          "";

      doctorExperience =
          doctor["experience"]?.toString() ??
          "";

      doctorHospitalVisitFee =
          doctor["hospitalVisitFee"]?.toString() ??
          doctor["fees"]?.toString() ??
          "";
      doctorVideoConsultationFee =
          doctor["videoConsultationFee"]?.toString() ??
          doctor["fees"]?.toString() ??
          "";
      doctorFees = doctorHospitalVisitFee;

      doctorAbout =
          doctor["about"]?.toString() ??
          "";

      // Load availability and schedule settings saved in MongoDB.
      isOnline = doctor["isAvailable"] is bool
          ? doctor["isAvailable"] as bool
          : true;

      final dynamic legacySchedule = doctor["schedule"] is Map
          ? doctor["schedule"]
          : doctor;
      final dynamic savedSchedules = doctor["consultationSchedules"];
      hospitalVisitSchedule = _readSchedule(
        savedSchedules is Map ? savedSchedules["hospitalVisit"] : null,
        legacySchedule,
      );
      videoConsultationSchedule = _readSchedule(
        savedSchedules is Map ? savedSchedules["videoConsultation"] : null,
        legacySchedule,
      );


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
        "doctorEmergencyNumber",
        doctorEmergencyNumber,
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
        "doctorAddress",
        doctorAddress,
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
        "doctorVideoConsultationFee",
        doctorVideoConsultationFee,
      );
      await prefs.setString(
        "doctorHospitalVisitFee",
        doctorHospitalVisitFee,
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
      doctorEmergencyNumber = doctorPhone;
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
    doctorEmergencyNumber =
        prefs.getString("doctorEmergencyNumber") ?? doctorPhone;
    doctorAddress = prefs.getString("doctorAddress") ?? "";

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
            .where((appointment) {
              final consultationType =
                  appointment['consultationType']?.toString().trim().toLowerCase() ?? '';
              final paymentStatus =
                  appointment['paymentStatus']?.toString().trim().toLowerCase() ?? '';
              return consultationType != 'video consultation' || paymentStatus == 'paid';
            })
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

  Future<void> recordHospitalPayment(dynamic appointment) async {
    final appointmentId = appointment["_id"]?.toString() ?? "";
    if (appointmentId.isEmpty) return;
    try {
      await ApiService.collectHospitalVisitPayment(
        appointmentId: appointmentId,
      );
      await loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hospital visit payment recorded.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to record payment: $e")),
      );
    }
  }

  Future<void> completeVideoAppointment(dynamic appointment) async {
    final appointmentId = appointment["_id"]?.toString().trim() ?? "";
    if (appointmentId.isEmpty) return;

    try {
      final response = await ApiService.completeConsultation(appointmentId);
      final completedAppointment = response["appointment"] is Map
          ? Map<String, dynamic>.from(response["appointment"] as Map)
          : Map<String, dynamic>.from(appointment as Map);

      await loadAppointments();
      if (!mounted) return;

      final refresh = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionScreen(
            appointment: completedAppointment,
          ),
        ),
      );

      if (mounted) loadDoctorPrescriptionTemplates();
      if (refresh == true && mounted) {
        await loadAppointments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to complete consultation: $e")),
      );
    }
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

          if (index == 0) {
            loadAppointments();
          }

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

 Widget patientHealthSummary(dynamic appointment) {
  String value(String key) {
    final raw = appointment[key]?.toString().trim() ?? "";
    return raw.isEmpty ? "Not provided" : raw;
  }

  final height = value("patientHeight");
  final weight = value("patientWeight");
  final details = <String>[
    "Gender: ${value('patientGender')}",
    "Blood group: ${value('patientBloodGroup')}",
    "Height: $height${height == "Not provided" ? "" : " cm"}",
    "Weight: $weight${weight == "Not provided" ? "" : " kg"}",
    "BMI: ${value("patientBmi")}",
  ];

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xffF3FAF9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xffD8EFEC)),
    ),
    child: Wrap(
      spacing: 14,
      runSpacing: 8,
      children: details
          .map((detail) => Text(
                detail,
                style: const TextStyle(fontSize: 13, color: Color(0xff335B58)),
              ))
          .toList(),
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
  final paymentMethod =
      appointment["paymentMethod"]?.toString().trim() ?? "ONLINE";
  final isReconsultation = appointment["isReconsultation"] == true;

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

              HealthHomeProfileAvatar(
                imageUrl:
                    appointment["patientProfileImageUrl"]?.toString(),
                radius: 27,
                backgroundColor: const Color(0xffE0F7F4),
                fallbackIcon: Icons.person,
                iconColor: const Color(0xff14B8A6),
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
          patientHealthSummary(appointment),

          const SizedBox(height: 18),

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

          if (isReconsultation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffE4F6F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Free reconsultation",
                style: TextStyle(
                  color: Color(0xff008F89),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          if (isReconsultation) const SizedBox(height: 10),

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

              Expanded(
                child: Text(
                isReconsultation
                    ? "Free reconsultation • No payment required"
                    : paymentMethod == "AT_HOSPITAL"
                        ? "Payment at hospital: $paymentStatus"
                        : "Online payment: $paymentStatus",
                style:
                    const TextStyle(
                  fontSize: 14,
                ),
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

  List<Map<String, dynamic>> _scheduleDayEntries(Map<String, dynamic> schedule) =>
      (schedule['daySchedules'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _dayScheduleFor(String day) =>
      _scheduleDayEntries(_activeSchedule)
          .firstWhere((entry) => entry['day'] == day);

  Map<String, dynamic> _schedulePayload(Map<String, dynamic> schedule) {
    final daySchedules = _scheduleDayEntries(schedule)
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final workingDays = daySchedules
        .where((entry) => entry['enabled'] == true)
        .toList();
    final firstWorkingDay = workingDays.isNotEmpty ? workingDays.first : null;
    return {
      ...schedule,
      'daySchedules': daySchedules,
      'workingDays': workingDays.map((entry) => entry['day'].toString()).toList(),
      if (firstWorkingDay != null) ...{
        'startTime': firstWorkingDay['startTime'],
        'endTime': firstWorkingDay['endTime'],
        'breakStart': firstWorkingDay['breakStart'],
        'breakEnd': firstWorkingDay['breakEnd'],
      },
    };
  }

  String? _validateSchedule(Map<String, dynamic> schedule, String label) {
    final enabledDays = _scheduleDayEntries(schedule)
        .where((entry) => entry['enabled'] == true)
        .toList();
    if (enabledDays.isEmpty) return '$label: select at least one working day.';

    bool isValidTime(String value) => RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(value);
    int minutesOfDay(String value) {
      final parts = value.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    for (final entry in enabledDays) {
      final day = entry['day'].toString();
      final start = entry['startTime'].toString();
      final end = entry['endTime'].toString();
      final breakStart = entry['breakStart'].toString();
      final breakEnd = entry['breakEnd'].toString();
      if (!isValidTime(start) || !isValidTime(end) ||
          (isValidTime(start) && isValidTime(end) && minutesOfDay(start) >= minutesOfDay(end))) {
        return '$label: set valid start and end times for $day.';
      }
      if (breakStart.isEmpty != breakEnd.isEmpty) {
        return '$label: set both break times or turn the break off for $day.';
      }
      if (breakStart.isNotEmpty &&
          (!isValidTime(breakStart) || !isValidTime(breakEnd) ||
              (isValidTime(breakStart) && isValidTime(breakEnd) &&
                  (minutesOfDay(breakStart) >= minutesOfDay(breakEnd) ||
                      minutesOfDay(breakStart) < minutesOfDay(start) ||
                      minutesOfDay(breakEnd) > minutesOfDay(end))))) {
        return '$label: the $day break must fit within working hours.';
      }
    }
    return null;
  }

  Future<void> _pickScheduleTime(String field, {String? day}) async {
    final targetSchedule = day == null ? _activeSchedule : _dayScheduleFor(day);
    final scheduleField = field == 'start'
        ? 'startTime'
        : field == 'end'
            ? 'endTime'
            : field;
    final current = (targetSchedule[scheduleField]?.toString().isNotEmpty == true
            ? targetSchedule[scheduleField].toString()
            : '10:00');

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
      targetSchedule[scheduleField] = formatted;
    });
  }

  Future<void> _saveDoctorSchedule() async {
    if (doctorId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor ID is missing. Please log in again.')),
      );
      return;
    }
    final hospitalPayload = _schedulePayload(hospitalVisitSchedule);
    final videoPayload = _schedulePayload(videoConsultationSchedule);
    final scheduleError = _validateSchedule(hospitalPayload, 'Hospital visit') ??
        _validateSchedule(videoPayload, 'Video consultation');
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleError)),
      );
      return;
    }

    setState(() => isSavingSchedule = true);
    try {
      final response = await ApiService.updateDoctorSchedule(
        doctorId: doctorId,
        consultationSchedules: {
          'hospitalVisit': hospitalPayload,
          'videoConsultation': videoPayload,
        },
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

  Widget _timeSettingTile(String title, String value, String field, {String? day}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.access_time, color: Color(0xff14B8A6)),
      onTap: () => _pickScheduleTime(field, day: day),
    );
  }

  Widget _dayScheduleCard(String day) {
    final daySchedule = _dayScheduleFor(day);
    final enabled = daySchedule['enabled'] == true;
    final hasBreak = daySchedule['breakStart'].toString().isNotEmpty &&
        daySchedule['breakEnd'].toString().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Switch(
          value: enabled,
          activeColor: const Color(0xff14B8A6),
          onChanged: (value) => setState(() => daySchedule['enabled'] = value),
        ),
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          enabled
              ? '${daySchedule['startTime']} – ${daySchedule['endTime']}'
              : 'Closed',
        ),
        children: [
          if (enabled) ...[
            Row(
              children: [
                Expanded(child: _timeSettingTile('Start time', daySchedule['startTime'].toString(), 'startTime', day: day)),
                const SizedBox(width: 12),
                Expanded(child: _timeSettingTile('End time', daySchedule['endTime'].toString(), 'endTime', day: day)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Break time'),
              subtitle: Text(hasBreak ? '${daySchedule['breakStart']} – ${daySchedule['breakEnd']}' : 'No break'),
              value: hasBreak,
              activeColor: const Color(0xff14B8A6),
              onChanged: (value) => setState(() {
                daySchedule['breakStart'] = value ? '13:00' : '';
                daySchedule['breakEnd'] = value ? '14:00' : '';
              }),
            ),
            if (hasBreak)
              Row(
                children: [
                  Expanded(child: _timeSettingTile('Break starts', daySchedule['breakStart'].toString(), 'breakStart', day: day)),
                  const SizedBox(width: 12),
                  Expanded(child: _timeSettingTile('Break ends', daySchedule['breakEnd'].toString(), 'breakEnd', day: day)),
                ],
              ),
          ] else
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('This day is not available for appointments.'),
              ),
            ),
        ],
      ),
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
            Wrap(
              spacing: 10,
              children: [
                for (final type in ['Hospital Visit', 'Video Consultation'])
                  ChoiceChip(
                    avatar: Icon(
                      type == 'Hospital Visit' ? Icons.local_hospital : Icons.video_call,
                      size: 18,
                    ),
                    label: Text(type),
                    selected: selectedScheduleType == type,
                    selectedColor: const Color(0xffD9F7F3),
                    onSelected: (_) => setState(() => selectedScheduleType = type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Set working hours for each day. Hospital visits and video consultations have separate schedules.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$selectedScheduleType • Weekly hours', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Turn on each working day and set its own hours and break.'),
                    const SizedBox(height: 14),
                    for (final day in const [
                      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                      'Friday', 'Saturday', 'Sunday',
                    ])
                      _dayScheduleCard(day),
                    const Divider(height: 28),
                    DropdownButtonFormField<int>(
                      initialValue: _activeSchedule['slotDurationMinutes'] as int,
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
                        if (value != null) setState(() => _activeSchedule['slotDurationMinutes'] = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _activeSchedule['maxAppointmentsPerDay'] as int,
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
                        if (value != null) setState(() => _activeSchedule['maxAppointmentsPerDay'] = value);
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
  final appointmentId = appointment is Map
      ? appointment["_id"]?.toString().trim() ?? ""
      : "";
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

      ...reports.map<Widget>((rawReport) {
        final report = PatientReport.fromJson(rawReport);
        final fileName = report.fileName;
        final isPdf = report.isPdf;
        final canView = report.canView &&
            appointmentId.isNotEmpty &&
            report.reportId.isNotEmpty;

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
if (!canView)
  SizedBox(
    width: 108,
    child: Text(
      "Image unavailable",
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  )
else
  Tooltip(
    message: "View $fileName",
    child: SizedBox(
      width: 78,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: () => _openPatientReport(
          appointmentId: appointmentId,
          report: report,
        ),
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text("View"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff00C2CB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
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
  required String appointmentId,
  required PatientReport report,
}) {
  if (!report.canView ||
      appointmentId.trim().isEmpty ||
      report.reportId.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Report file is not available",
        ),
      ),
    );
    return;
  }

  final reportFuture = ApiService.getDoctorAppointmentReportBytes(
    appointmentId: appointmentId,
    reportId: report.reportId,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          backgroundColor: report.isPdf ? Colors.white : Colors.black,
          appBar: AppBar(
            title: Text(
              report.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            backgroundColor: const Color(0xff14B8A6),
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder<Uint8List>(
            future: reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error?.toString().replaceFirst("Exception: ", "") ??
                          "Unable to load this report.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: report.isPdf ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ),
                );
              }

              final bytes = snapshot.data!;
              if (report.isPdf) return SfPdfViewer.memory(bytes);

              return LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.memory(
                      bytes,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Text(
                          "Unable to display this image.",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
final paymentStatus = appointment["paymentStatus"]?.toString() ?? "Pending";
final paymentMethod = appointment["paymentMethod"]?.toString() ?? "ONLINE";
final isReconsultation = appointment["isReconsultation"] == true;
final consultationStatus =
    appointment["consultationStatus"]?.toString().trim().toLowerCase() ?? "";
final canCompleteVideoAppointment = isVideo &&
    (consultationStatus == "ready" || consultationStatus == "joined");
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

          patientHealthSummary(appointment),

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

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xff14B8A6), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReconsultation
                      ? "Free reconsultation • No payment required"
                      : isVideo
                          ? "Online payment: $paymentStatus"
                          : paymentMethod == "AT_HOSPITAL"
                              ? "Payment at hospital: $paymentStatus"
                              : "Online payment: $paymentStatus",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (!isVideo && paymentMethod == "AT_HOSPITAL" && paymentStatus != "Paid") ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => recordHospitalPayment(appointment),
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                  "Record hospital payment received"
                  "${appointment["fees"] == null ? "" : " • ₹${appointment["fees"]}"}",
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff0F9D91),
                  side: const BorderSide(color: Color(0xff14B8A6)),
                ),
              ),
            ),
          ],

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

          if (canCompleteVideoAppointment) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => completeVideoAppointment(appointment),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Complete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0F9D91),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

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
    final avPermissionsGranted =
        await IncomingCallService.requestVideoCallPermissions();
    if (!avPermissionsGranted) {
      throw Exception(
          'Camera and microphone permissions are required. Allow them in Android Settings before starting the call.');
    }

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
    final pushStatus = response["push"];
    if (pushStatus is Map && (pushStatus["delivered"] as num? ?? 0) == 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Call started, but the patient device was not reached: ${pushStatus["reason"] ?? "no registered device"}")),
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
    final callId = response["call"] is Map
        ? response["call"]["callId"]?.toString()
        : null;

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
          callId: callId,
        ),
      ),
    );

    // Refresh after the doctor returns from the call. The doctor can
    // complete the appointment separately from Schedule.

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

            buildQuickPrescriptionTemplatesCard(),

            const SizedBox(height: 18),

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

  if (mounted) loadDoctorPrescriptionTemplates();
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

            const SizedBox(height: 8),

            buildPrescriptionLibraryCard(),

          ],

        ),

      ),

    );

  }

  Widget buildQuickPrescriptionTemplatesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 7, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xff14B8A6)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Quick Prescription Templates",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: showPrescriptionTemplateLibrary,
                child: const Text("View All  ›"),
              ),
            ],
          ),
          if (isLoadingDoctorPrescriptionTemplates)
            const LinearProgressIndicator(minHeight: 2)
          else if (doctorPrescriptionTemplatesError != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    doctorPrescriptionTemplatesError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: loadDoctorPrescriptionTemplates,
                  child: const Text("Retry"),
                ),
              ],
            )
          else if (doctorPrescriptionTemplates.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                "Save common prescriptions from a patient visit to see them here.",
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: doctorPrescriptionTemplates.take(4).map((template) {
                  final name = template["name"]?.toString() ?? "Prescription";
                  return Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 112,
                        height: 118,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xffFAFCFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE8EEF0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xffE7F8F6),
                              child: Icon(
                                prescriptionTemplateIcon(name),
                                color: const Color(0xff14B8A6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPrescriptionLibraryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 7, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, color: Color(0xff14B8A6)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  "Your Prescription Library",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: showPrescriptionTemplateLibrary,
                child: const Text("Manage  ›"),
              ),
            ],
          ),
          if (isLoadingDoctorPrescriptionTemplates)
            const LinearProgressIndicator(minHeight: 2)
          else if (doctorPrescriptionTemplatesError != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                doctorPrescriptionTemplatesError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            )
          else if (doctorPrescriptionTemplates.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Text(
                  "Reusable prescriptions you save will appear here.",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...doctorPrescriptionTemplates.take(3).map((template) {
              final name = template["name"]?.toString() ?? "Prescription";
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xffE7F8F6),
                  child: Icon(
                    prescriptionTemplateIcon(name),
                    color: const Color(0xff14B8A6),
                  ),
                ),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  prescriptionTemplateSummary(template),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
              );
            }),
        ],
      ),
    );
  }

  IconData prescriptionTemplateIcon(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains("cold") || normalized.contains("fever")) {
      return Icons.ac_unit;
    }
    if (normalized.contains("acidity") || normalized.contains("stomach")) {
      return Icons.sick_outlined;
    }
    if (normalized.contains("cough") || normalized.contains("breath")) {
      return Icons.air;
    }
    if (normalized.contains("pain")) return Icons.healing;
    return Icons.medical_services_outlined;
  }

  String prescriptionTemplateSummary(Map<String, dynamic> template) {
    final medicines = template["medicines"] is List
        ? (template["medicines"] as List)
            .whereType<Map>()
            .map((medicine) => medicine["medicine"]?.toString().trim() ?? "")
            .where((name) => name.isNotEmpty)
            .toList()
        : <String>[];
    if (medicines.isNotEmpty) return medicines.take(2).join(" + ");

    final labTests = template["labTests"] is List
        ? (template["labTests"] as List)
            .whereType<Map>()
            .map((test) => test["testName"]?.toString().trim() ?? "")
            .where((name) => name.isNotEmpty)
            .toList()
        : <String>[];
    if (labTests.isNotEmpty) return labTests.take(2).join(" + ");

    final diagnosis = template["diagnosis"]?.toString().trim() ?? "";
    if (diagnosis.isNotEmpty) return diagnosis;
    final symptoms = template["symptoms"]?.toString().trim() ?? "";
    if (symptoms.isNotEmpty) return symptoms;
    return "Advice and notes";
  }

  void showPrescriptionTemplateLibrary() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Your Prescription Library"),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(dialogContext).size.height * 0.5,
          child: isLoadingDoctorPrescriptionTemplates
              ? const Center(child: CircularProgressIndicator())
              : doctorPrescriptionTemplatesError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doctorPrescriptionTemplatesError!,
                            textAlign: TextAlign.center,
                          ),
                          TextButton.icon(
                            onPressed: loadDoctorPrescriptionTemplates,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : doctorPrescriptionTemplates.isEmpty
                      ? const Center(
                          child: Text(
                            "No saved templates yet. Save one from a patient's Write Prescription form.",
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView(
                          children: doctorPrescriptionTemplates.map((template) {
                            final name = template["name"]?.toString() ?? "Prescription";
                            return ListTile(
                              leading: Icon(
                                prescriptionTemplateIcon(name),
                                color: const Color(0xff14B8A6),
                              ),
                              title: Text(name),
                              subtitle: Text(prescriptionTemplateSummary(template)),
                            );
                          }).toList(),
                        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
          if (doctorPrescriptionTemplatesError != null)
            IconButton(
              tooltip: "Refresh templates",
              onPressed: loadDoctorPrescriptionTemplates,
              icon: const Icon(Icons.refresh),
            ),
        ],
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

          const Center(
            child: ProfileImageEditor(
              accentColor: Color(0xff14B8A6),
              backgroundColor: Color(0xffE6FFFB),
              fallbackIcon: Icons.medical_services,
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

          const SizedBox(height: 16),

          Center(
            child: EditProfileButton(
              role: 'doctor',
              initialProfile: {
                'name': doctorName,
                'emergencyNumber': doctorEmergencyNumber,
                'specialization': doctorSpecialization,
                'experience': doctorExperience,
                'fees': doctorFees,
                'videoConsultationFee': doctorVideoConsultationFee,
                'hospitalVisitFee': doctorHospitalVisitFee,
                'hospital': doctorHospital,
                'address': doctorAddress,
                'about': doctorAbout,
              },
              onProfileUpdated: (profile) async {
                if (!mounted) return;
                setState(() {
                  doctorName = profile['name']?.toString() ?? doctorName;
                  doctorEmergencyNumber =
                      profile['emergencyNumber']?.toString() ?? doctorEmergencyNumber;
                  doctorSpecialization =
                      profile['specialization']?.toString() ?? doctorSpecialization;
                  doctorExperience =
                      profile['experience']?.toString() ?? doctorExperience;
                  doctorVideoConsultationFee =
                      profile['videoConsultationFee']?.toString() ??
                          doctorVideoConsultationFee;
                  doctorHospitalVisitFee =
                      profile['hospitalVisitFee']?.toString() ??
                          profile['fees']?.toString() ??
                          doctorHospitalVisitFee;
                  doctorFees = doctorHospitalVisitFee;
                  doctorHospital =
                      profile['hospital']?.toString() ?? doctorHospital;
                  doctorAddress = profile['address']?.toString() ?? doctorAddress;
                  doctorAbout = profile['about']?.toString() ?? doctorAbout;
                });
              },
            ),
          ),

          const SizedBox(height: 30),

          profileTile(

            Icons.phone,

            "Phone",

            doctorPhone,

          ),

          profileTile(
            Icons.emergency_outlined,
            "Emergency Contact",
            doctorEmergencyNumber,
          ),

          profileTile(

            Icons.local_hospital,

            "Hospital",

            doctorHospital,

          ),

          if (doctorAddress.trim().isNotEmpty)
            profileTile(
              Icons.location_on_outlined,
              "Hospital Address",
              doctorAddress,
            ),

          profileTile(

            Icons.work,

            "Experience",

            doctorExperience,

          ),

          profileTile(
            Icons.video_call,
            "Video Consultation Fee",
            "₹$doctorVideoConsultationFee",
          ),

          profileTile(
            Icons.currency_rupee,
            "Hospital Visit Fee",
            "₹$doctorHospitalVisitFee",
          ),

          profileTile(

            Icons.info,

            "About",

            doctorAbout,

          ),

          const RatingsCard(),

          const HelpSupportCard(),

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
  await IncomingCallService.unregisterCurrentDevice();
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
