

import 'package:easy_localization/easy_localization.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

import '../../services/telegram/AgoraVideoCallPage.dart';

class AppointmentsPage extends StatefulWidget {

  const AppointmentsPage({super.key});

  @override

  State<AppointmentsPage> createState() => _AppointmentsPageState();

}

class _AppointmentsPageState extends State<AppointmentsPage> {

  List<dynamic> appointments = [];

  bool loading = true;

  int selectedTab = 0;

// ============================================================

// AGORA VIDEO CONSULTATION

// ============================================================

Map<String, dynamic>? readyConsultation;

Timer? consultationTimer;

bool checkingConsultation = false;

  final List<String> tabs = [

    "Upcoming",

    "Completed",

    "Cancelled",

  ];

  @override

void initState() {

  super.initState();

  loadAppointments();

  // Check whether doctor has started a video consultation.

  checkReadyConsultation();

  // Keep checking while patient remains on this page.

  consultationTimer = Timer.periodic(

    const Duration(seconds: 5),

    (_) {

      checkReadyConsultation();

    },

  );

}

  // ============================================================

  // LOAD PATIENT APPOINTMENTS

  // ============================================================

  Future<void> loadAppointments() async {

    if (mounted) {

      setState(() {

        loading = true;

      });

    }

    try {

      final prefs = await SharedPreferences.getInstance();

      final String phone =

          prefs.getString("patientPhone") ?? "";

      print("================================");

      print("PATIENT APPOINTMENTS");

      print("PATIENT PHONE = $phone");

      print("================================");

      if (phone.isEmpty) {

        print("❌ Patient phone not found");

        if (mounted) {

          setState(() {

            appointments = [];

            loading = false;

          });

        }

        return;

      }

      final result =

          await ApiService.getPatientAppointments(phone);

      print("APPOINTMENTS API RESULT = $result");

      if (mounted) {

        setState(() {

          appointments = List<dynamic>.from(result);

          loading = false;

        });

      }

    } catch (e) {

      print("❌ APPOINTMENT ERROR = $e");

      if (mounted) {

        setState(() {

          appointments = [];

          loading = false;

        });

      }

    }

  }

// ============================================================

// CHECK READY AGORA CONSULTATION

// ============================================================

Future<void> checkReadyConsultation() async {

  if (checkingConsultation) return;

  checkingConsultation = true;

  try {

    final prefs = await SharedPreferences.getInstance();

    final String phone =

        prefs.getString("patientPhone") ?? "";

    if (phone.isEmpty) {

      return;

    }

    final result =

        await ApiService.checkReadyConsultation(phone);

    if (!mounted) return;

    if (result != null) {

      setState(() {

        readyConsultation =

            Map<String, dynamic>.from(result);

      });

      print("================================");

      print("AGORA CONSULTATION READY");

      print("APPOINTMENT ID = ${result["_id"]}");

      print("DOCTOR = ${result["doctorName"]}");

      print("MEETING ID = ${result["meetingId"]}");

      print("CONSULTATION STATUS = ${result["consultationStatus"]}");

      print("================================");

    } else {

      if (mounted) {

        setState(() {

          readyConsultation = null;

        });

      }

    }

  } catch (e) {

    print("❌ READY CONSULTATION ERROR = $e");

  } finally {

    checkingConsultation = false;

  }

}

  // ============================================================

  // GET CURRENT TAB APPOINTMENTS

  // ============================================================

  List<dynamic> get filteredAppointments {

    return appointments.where((appointment) {

      final String status =

          (appointment["status"] ?? "")

              .toString()

              .trim()

              .toLowerCase();

      // UPCOMING

      // Pending + Accepted

      if (selectedTab == 0) {

        return status == "pending" ||

            status == "accepted" ||

            status == "upcoming";

      }

      // COMPLETED

      if (selectedTab == 1) {

        return status == "completed";

      }

      // CANCELLED

      // Rejected + Cancelled

      if (selectedTab == 2) {

        return status == "rejected" ||

            status == "cancelled";

      }

      return false;

    }).toList();

  }

  // ============================================================

  // STATUS COLOR

  // ============================================================

  Color getStatusColor(String status) {

    switch (status.toLowerCase()) {

      case "accepted":

        return const Color(0xff4CAF50);

      case "completed":

        return const Color(0xffF0A000);

      case "rejected":

      case "cancelled":

        return const Color(0xffE53935);

      case "pending":

      default:

        return const Color(0xffF0A000);

    }

  }

  // ============================================================

  // STATUS BACKGROUND

  // ============================================================

  Color getStatusBackground(String status) {

    return getStatusColor(status).withValues(alpha: 0.12);

  }

  // ============================================================

  // TRANSLATE STATUS

  // ============================================================

  String translateStatus(String status) {

    switch (status.toLowerCase()) {

      case "accepted":

        return "accepted".tr();

      case "completed":

        return "completed".tr();

      case "rejected":

        return "rejected".tr();

      case "cancelled":

        return "cancelled".tr();

      case "pending":

        return "pending".tr();

      default:

        return status;

    }

  }

  // ============================================================

  // FORMAT DATE

  // ============================================================

  String formatDate(dynamic date) {

    if (date == null) {

      return "";

    }

    final value = date.toString().trim();

    if (value.isEmpty) {

      return "";

    }

    try {

      final parsedDate = DateTime.parse(value);

      return DateFormat(

        "d/M/yyyy",

      ).format(parsedDate);

    } catch (_) {

      return value;

    }

  }

  // ============================================================

  // GET APPOINTMENT DATE

  // ============================================================

  String getAppointmentDate(

    Map<String, dynamic> appointment,

  ) {

    final date =

        appointment["appointmentDate"];

    return formatDate(date);

  }

  // ============================================================

  // GET APPOINTMENT TIME

  // ============================================================

  String getAppointmentTime(

    Map<String, dynamic> appointment,

  ) {

    final time =

        appointment["appointmentTime"];

    if (time == null) {

      return "";

    }

    return time.toString();

  }

  // ============================================================

  // OPEN APPOINTMENT DETAILS

  // ============================================================

  Future<void> openAppointmentDetails(

    Map<String, dynamic> appointment,

  ) async {

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) =>

            AppointmentDetailsPage(

          appointment: appointment,

        ),

      ),

    );

    // Refresh after coming back.

    await loadAppointments();

  }

  // ============================================================

  // TAB BUTTON

  // ============================================================

  Widget buildTab(

    int index,

    String title,

  ) {

    final bool selected =

        selectedTab == index;

    return Expanded(

      child: GestureDetector(

        onTap: () {

          setState(() {

            selectedTab = index;

          });

        },

        child: AnimatedContainer(

          duration:

              const Duration(milliseconds: 200),

          margin:

              const EdgeInsets.symmetric(

            horizontal: 5,

          ),

          padding:

              const EdgeInsets.symmetric(

            vertical: 12,

          ),

          decoration: BoxDecoration(

            color: selected

                ? const Color(0xffD8F4F2)

                : Colors.transparent,

            borderRadius:

                BorderRadius.circular(12),

            border: Border.all(

              color: selected

                  ? const Color(0xffB7E5E1)

                  : const Color(0xffC8CDD0),

              width: 1.2,

            ),

          ),

          child: Row(

            mainAxisAlignment:

                MainAxisAlignment.center,

            children: [

              Icon(

                index == 0

                    ? Icons.check

                    : index == 1

                        ? Icons.check_circle_outline

                        : Icons.close,

                size: 20,

                color: selected

                    ? const Color(0xff008F89)

                    : const Color(0xff42484B),

              ),

              const SizedBox(width: 7),

              Text(

                title,

                style: TextStyle(

                  fontSize: 16,

                  fontWeight: selected

                      ? FontWeight.w600

                      : FontWeight.w500,

                  color: selected

                      ? const Color(0xff008F89)

                      : const Color(0xff303538),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  // ============================================================

  // APPOINTMENT CARD

  // ============================================================

Widget buildAppointmentCard(Map<String, dynamic> appointment) {

  final String doctorName =

      (appointment["doctorName"] ?? "Doctor").toString();

  final String specialization =

      (appointment["specialization"] ??

              appointment["speciality"] ??

              "Specialist")

          .toString();

  final String status =

      (appointment["status"] ?? "Pending").toString();

  final String date = getAppointmentDate(appointment);

  final String time = getAppointmentTime(appointment);

  final Color statusColor = getStatusColor(status);

  final String consultationType =

      (appointment["consultationType"] ?? "").toString().trim();

  final String consultationStatus =

      (appointment["consultationStatus"] ?? "").toString().trim();

  final String appointmentId =

      (appointment["_id"] ?? "").toString();

  final bool isReadyForVideo =

      consultationType == "Video Consultation" &&

      (consultationStatus == "Ready" ||

          consultationStatus == "Joined") &&

      readyConsultation != null &&

      readyConsultation!["_id"].toString() == appointmentId;

  return Container(

    margin: const EdgeInsets.only(bottom: 14),

    child: Material(

      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      elevation: 2,

      shadowColor: Colors.black.withValues(alpha: 0.07),

      child: InkWell(

        borderRadius: BorderRadius.circular(20),

        onTap: () => openAppointmentDetails(appointment),

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // DOCTOR INFORMATION AND STATUS

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Container(

                    width: 60,

                    height: 60,

                    decoration: const BoxDecoration(

                      color: Color(0xffCFF8F5),

                      shape: BoxShape.circle,

                    ),

                    child: const Icon(

                      Icons.person,

                      size: 34,

                      color: Color(0xff007F7A),

                    ),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          doctorName,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(

                            fontSize: 18,

                            fontWeight: FontWeight.w700,

                            color: Color(0xff222222),

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          specialization,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(

                            fontSize: 14,

                            color: Color(0xff626B70),

                          ),

                        ),

                        if (date.isNotEmpty || time.isNotEmpty) ...[

                          const SizedBox(height: 7),

                          Text(

                            [

                              date,

                              time,

                            ].where((value) => value.isNotEmpty).join(" • "),

                            style: const TextStyle(

                              fontSize: 13,

                              color: Color(0xff555555),

                            ),

                          ),

                        ],

                      ],

                    ),

                  ),

                  const SizedBox(width: 8),

                  // STATUS BADGE

                  Flexible(

                    child: Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 10,

                        vertical: 8,

                      ),

                      decoration: BoxDecoration(

                        color: getStatusBackground(status),

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: Text(

                        translateStatus(status),

                        textAlign: TextAlign.center,

                        softWrap: true,

                        style: TextStyle(

                          color: statusColor,

                          fontSize: 12,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

              // FULL-WIDTH RESCHEDULE PROPOSAL

              if (_hasDoctorRescheduleProposal(appointment))

                _buildRescheduleProposal(appointment),

              // VIDEO CONSULTATION BUTTON

              if (isReadyForVideo) ...[

                const SizedBox(height: 14),

                SizedBox(

                  width: double.infinity,

                  child: ElevatedButton.icon(

                    onPressed: () async {

                      final result = await Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) => AgoraVideoCallPage(

                            doctorName: doctorName,

                            patientName: "Patient",

                            appointmentId: appointmentId,

                            meetingId: (

                              readyConsultation?["meetingId"] ??

                              appointment["meetingId"] ??

                              ""

                            ).toString(),

                            isDoctor: false,

                          ),

                        ),

                      );

                      if (result == true && mounted) {

                        await loadAppointments();

                        await checkReadyConsultation();

                      }

                    },

                    icon: const Icon(Icons.videocam),

                    label: const Text("Join Video Consultation"),

                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xff00A99D),

                      foregroundColor: Colors.white,

                      minimumSize: const Size.fromHeight(48),

                      elevation: 0,

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(12),

                      ),

                    ),

                  ),

                ),

              ],

            ],

          ),

        ),

      ),

    ),

  );

}

  // ============================================================

  // ============================================================

  // DOCTOR RESCHEDULE PROPOSAL

  // ============================================================

  bool _hasDoctorRescheduleProposal(Map<String, dynamic> appointment) {

    final proposedDate =

        (appointment["proposedAppointmentDate"] ?? "").toString().trim();

    final proposedTime =

        (appointment["proposedAppointmentTime"] ?? "").toString().trim();

    final requestedBy =

        (appointment["rescheduleRequestedBy"] ?? "").toString().trim();

    final response =

        (appointment["patientResponse"] ?? "").toString().trim();

    return proposedDate.isNotEmpty &&

        proposedTime.isNotEmpty &&

        requestedBy.toLowerCase() == "doctor" &&

        response.toLowerCase() != "accepted";

  }

  Widget _buildRescheduleProposal(Map<String, dynamic> appointment) {
  final proposedDate =
      (appointment["proposedAppointmentDate"] ?? "").toString().trim();
  final proposedTime =
      (appointment["proposedAppointmentTime"] ?? "").toString().trim();
  final reason =
      (appointment["rescheduleReason"] ?? "").toString().trim();
  final response =
      (appointment["patientResponse"] ?? "Pending").toString().trim();

  final isWaiting =
      response.isEmpty || response.toLowerCase() == "pending";
  final isRequestingAnother =
      response.toLowerCase() == "requested another time";

  const teal = Color(0xff008F89);
  const darkTeal = Color(0xff006F69);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffEAF8F6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffB8E6E0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xffD2F2ED),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.event_repeat,
                color: teal,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Doctor suggested a new time",
                softWrap: true,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: darkTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Proposed date and time displayed side by side.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _proposalDetailRow(
                Icons.calendar_month_outlined,
                "Proposed date",
                formatDate(proposedDate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _proposalDetailRow(
                Icons.schedule,
                "Proposed time",
                proposedTime,
              ),
            ),
          ],
        ),

        if (reason.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Reason: $reason",
              softWrap: true,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xff465B59),
              ),
            ),
          ),
        ],

        if (isWaiting) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final acceptButton = ElevatedButton.icon(
                onPressed: () =>
                    _respondToReschedule(appointment, "Accepted"),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                ),
                label: const Text(
                  "Accept new time",
                  textAlign: TextAlign.center,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0F9D91),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              final requestButton = OutlinedButton.icon(
                onPressed: () => _respondToReschedule(
                  appointment,
                  "Requested Another Time",
                ),
                icon: const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                ),
                label: const Text(
                  "Request another time",
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: teal,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: const BorderSide(
                    color: Color(0xff8ACFC7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    acceptButton,
                    const SizedBox(height: 10),
                    requestButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: acceptButton),
                  const SizedBox(width: 10),
                  Expanded(child: requestButton),
                ],
              );
            },
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isRequestingAnother
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_outline,
                  color: teal,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRequestingAnother
                        ? "You requested another time. Please wait for the doctor to suggest a new slot."
                        : "Your response: $response",
                    softWrap: true,
                    style: const TextStyle(
                      color: darkTeal,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _proposalDetailRow(IconData icon, String label, String value) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Icon(icon, size: 18, color: const Color(0xff008F89)),

        const SizedBox(width: 8),

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                label,

                style: const TextStyle(

                  color: Color(0xff617573),

                  fontSize: 12,

                  fontWeight: FontWeight.w500,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                value.isEmpty ? "Not provided" : value,

                softWrap: true,

                style: const TextStyle(

                  color: Color(0xff183D3A),

                  fontSize: 14,

                  fontWeight: FontWeight.w700,

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }

  Future<void> _respondToReschedule(

    Map<String, dynamic> appointment,

    String response,

  ) async {

    final appointmentId = (appointment["_id"] ?? "").toString().trim();

    if (appointmentId.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text("Appointment ID is missing.")),

      );

      return;

    }

    try {

      final result = await ApiService.respondToAppointmentReschedule(

        appointmentId: appointmentId,

        response: response,

      );

      if (result["success"] == false) {

        throw Exception(result["message"] ?? "Could not update response.");

      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            response == "Accepted"

                ? "New appointment time accepted."

                : "Request sent to the doctor.",

          ),

        ),

      );

      await loadAppointments();

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text("Unable to respond to proposal: $e")),

      );

    }

  }

// EMPTY TAB

  // ============================================================

  Widget buildEmptyState() {

    String title;

    String subtitle;

    IconData icon;

    if (selectedTab == 0) {

      title = "noUpcomingAppointments".tr();

      subtitle =

          "upcomingAppointmentsMessage".tr();

      icon = Icons.event_available;

    } else if (selectedTab == 1) {

      title = "noCompletedAppointments".tr();

      subtitle =

          "completedAppointmentsMessage".tr();

      icon = Icons.check_circle_outline;

    } else {

      title = "noCancelledAppointments".tr();

      subtitle =

          "cancelledAppointmentsMessage".tr();

      icon = Icons.event_busy;

    }

    return Center(

      child: Padding(

        padding:

            const EdgeInsets.symmetric(

          horizontal: 35,

        ),

        child: Column(

          mainAxisAlignment:

              MainAxisAlignment.center,

          children: [

            Container(

              width: 85,

              height: 85,

              decoration:

                  const BoxDecoration(

                color: Color(0xffE8F5F3),

                shape: BoxShape.circle,

              ),

              child: Icon(

                icon,

                size: 45,

                color:

                    const Color(0xff12A89D),

              ),

            ),

            const SizedBox(height: 20),

            Text(

              title,

              textAlign: TextAlign.center,

              style:

                  const TextStyle(

                fontSize: 20,

                fontWeight:

                    FontWeight.bold,

              ),

            ),

            const SizedBox(height: 8),

            Text(

              subtitle,

              textAlign: TextAlign.center,

              style:

                  const TextStyle(

                fontSize: 14,

                color:

                    Colors.grey,

              ),

            ),

          ],

        ),

      ),

    );

  }

  // ============================================================

  // BUILD

  // ============================================================

  @override

  void dispose() {

    consultationTimer?.cancel();

    super.dispose();

  }

  @override

  Widget build(

    BuildContext context,

  ) {

    final List<dynamic>

        currentAppointments =

        filteredAppointments;

    return Scaffold(

      backgroundColor:

          const Color(0xffF7F8FA),

      appBar: AppBar(

        backgroundColor:

            Colors.white,

        elevation: 0,

        foregroundColor:

            Colors.black,

        leading: IconButton(

          icon: const Icon(

            Icons.arrow_back,

            size: 28,

          ),

          onPressed: () {

            Navigator.pop(context);

          },

        ),

        title: Text(

          "myAppointments".tr(),

          style: const TextStyle(

            color: Colors.black,

            fontSize: 24,

            fontWeight:

                FontWeight.bold,

          ),

        ),

        centerTitle: true,

      ),

      body: RefreshIndicator(

        onRefresh: loadAppointments,

        child: Column(

          children: [

            const SizedBox(height: 12),

            // TABS

            Padding(

              padding:

                  const EdgeInsets.symmetric(

                horizontal: 8,

              ),

              child: Row(

                children: [

                  buildTab(

                    0,

                    "upcoming".tr(),

                  ),

                  buildTab(

                    1,

                    "completed".tr(),

                  ),

                  buildTab(

                    2,

                    "cancelled".tr(),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 18),

            // APPOINTMENTS

            Expanded(

              child: loading

                  ? const Center(

                      child:

                          CircularProgressIndicator(

                        color:

                            Color(0xff12A89D),

                      ),

                    )

                  : currentAppointments

                          .isEmpty

                      ? ListView(

                          physics:

                              const AlwaysScrollableScrollPhysics(),

                          children: [

                            SizedBox(

                              height:

                                  MediaQuery.of(context)

                                          .size

                                          .height *

                                      0.55,

                              child:

                                  buildEmptyState(),

                            ),

                          ],

                        )

                      : ListView.builder(

                          physics:

                              const AlwaysScrollableScrollPhysics(),

                          padding:

                              const EdgeInsets

                                  .fromLTRB(

                            20,

                            0,

                            20,

                            25,

                          ),

                          itemCount:

                              currentAppointments

                                  .length,

                          itemBuilder:

                              (context, index) {

                            final appointment =

                                Map<String,

                                    dynamic>.from(

                              currentAppointments[

                                  index],

                            );

                            return buildAppointmentCard(

                              appointment,

                            );

                          },

                        ),

            ),

          ],

        ),

      ),

    );

  }

}

// ==================================================================

// APPOINTMENT DETAILS PAGE

// ==================================================================

class AppointmentDetailsPage extends StatelessWidget {

  final Map<String, dynamic> appointment;

  const AppointmentDetailsPage({

    super.key,

    required this.appointment,

  });

  String translateStatus(

    BuildContext context,

    String status,

  ) {

    switch (status.toLowerCase()) {

      case "accepted":

        return "accepted".tr();

      case "completed":

        return "completed".tr();

      case "rejected":

        return "rejected".tr();

      case "cancelled":

        return "cancelled".tr();

      case "pending":

        return "pending".tr();

      default:

        return status;

    }

  }

  @override

  Widget build(BuildContext context) {

    final String doctorName =

        (appointment["doctorName"] ??

                "Doctor")

            .toString();

    final String specialization =

        (appointment["specialization"] ??

                appointment["speciality"] ??

                "Specialist")

            .toString();

    final String status =

        (appointment["status"] ??

                "Pending")

            .toString();

    final String date =

        (appointment["appointmentDate"] ??

                "")

            .toString();

    final String time =

        (appointment["appointmentTime"] ??

                "")

            .toString();

    return Scaffold(

      backgroundColor:

          const Color(0xffF7F8FA),

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        foregroundColor: Colors.black,

        title: Text(

          "appointmentDetails".tr(),

        ),

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:

              CrossAxisAlignment.start,

          children: [

            Text(

              doctorName,

              style: const TextStyle(

                fontSize: 26,

                fontWeight:

                    FontWeight.bold,

              ),

            ),

            const SizedBox(height: 8),

            Text(

              specialization,

              style: const TextStyle(

                fontSize: 18,

                color:

                    Color(0xff555555),

              ),

            ),

            const SizedBox(height: 22),

            _detailRow(

              "status".tr(),

              translateStatus(

                context,

                status,

              ),

            ),

            _detailRow(

              "date".tr(),

              date,

            ),

            _detailRow(

              "time".tr(),

              time,

            ),

          ],

        ),

      ),

    );

  }

  Widget _detailRow(

    String label,

    String value,

  ) {

    return Container(

      width: double.infinity,

      margin:

          const EdgeInsets.only(bottom: 12),

      padding:

          const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:

            BorderRadius.circular(14),

      ),

      child: Row(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: 90,

            child: Text(

              label,

              style: const TextStyle(

                color: Colors.grey,

                fontSize: 14,

              ),

            ),

          ),

          Expanded(

            child: Text(

              value.isEmpty

                  ? "-"

                  : value,

              style: const TextStyle(

                fontSize: 16,

                fontWeight:

                    FontWeight.w500,

              ),

            ),

          ),

        ],

      ),

    );

  }

}