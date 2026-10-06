

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



  Widget buildAppointmentCard(

    Map<String, dynamic> appointment,

  ) {

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

        getAppointmentDate(appointment);



    final String time =

        getAppointmentTime(appointment);



    final Color statusColor =

        getStatusColor(status);



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

      margin: const EdgeInsets.only(

        bottom: 14,

      ),

      child: Material(

        color: Colors.white,

        borderRadius:

            BorderRadius.circular(18),

        elevation: 3,

        shadowColor:

            Colors.black.withValues(alpha: 0.10),

        child: InkWell(

          borderRadius:

              BorderRadius.circular(18),

          onTap: () {

            openAppointmentDetails(

              appointment,

            );

          },

          child: Padding(

            padding:

                const EdgeInsets.all(18),

            child: Row(

              crossAxisAlignment:

                  CrossAxisAlignment.center,

              children: [



                // DOCTOR ICON



                Container(

                  width: 68,

                  height: 68,

                  decoration:

                      const BoxDecoration(

                    color:

                        Color(0xffCFF8F5),

                    shape: BoxShape.circle,

                  ),

                  child: const Icon(

                    Icons.person,

                    size: 38,

                    color:

                        Color(0xff007F7A),

                  ),

                ),



                const SizedBox(width: 16),



                // DOCTOR INFORMATION



                Expanded(

                  child: Column(

                    crossAxisAlignment:

                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        doctorName,

                        maxLines: 1,

                        overflow:

                            TextOverflow.ellipsis,

                        style:

                            const TextStyle(

                          fontSize: 20,

                          fontWeight:

                              FontWeight.w500,

                          color:

                              Color(0xff222222),

                        ),

                      ),



                      const SizedBox(

                        height: 4,

                      ),



                      Text(

                        specialization,

                        maxLines: 1,

                        overflow:

                            TextOverflow.ellipsis,

                        style:

                            const TextStyle(

                          fontSize: 17,

                          color:

                              Color(0xff555555),

                        ),

                      ),



                      const SizedBox(

                        height: 5,

                      ),



                      if (date.isNotEmpty ||

                          time.isNotEmpty)

                        Text(

                          "$date${date.isNotEmpty && time.isNotEmpty ? " • " : ""}$time",

                          maxLines: 1,

                          overflow:

                              TextOverflow.ellipsis,

                          style:

                              const TextStyle(

                            fontSize: 16,

                            color:

                                Color(0xff555555),

                          ),

                        ),



                        if (
  consultationType == "Video Consultation" &&
  (consultationStatus == "Ready" ||
      consultationStatus == "Joined") &&
  readyConsultation != null &&
  readyConsultation!["_id"].toString() ==
      (appointment["_id"] ?? "").toString()
) ...[

  const SizedBox(height: 12),



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
 appointmentId: (appointment["_id"] ?? "").toString(),
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

      icon: const Icon(

        Icons.videocam,

        color: Colors.white,

      ),

      label: const Text(

        "Join Video Consultation",

        style: TextStyle(

          color: Colors.white,

          fontWeight: FontWeight.bold,

        ),

      ),

      style: ElevatedButton.styleFrom(

        backgroundColor:

            const Color(0xff00C2CB),

        padding:

            const EdgeInsets.symmetric(

          vertical: 13,

        ),

        shape: RoundedRectangleBorder(

          borderRadius:

              BorderRadius.circular(12),

        ),

      ),

    ),

  ),

],

                    ],

                  ),

                ),



                const SizedBox(width: 8),



                // STATUS



                Container(

                  padding:

                      const EdgeInsets.symmetric(

                    horizontal: 12,

                    vertical: 9,

                  ),

                  decoration:

                      BoxDecoration(

                    color:

                        getStatusBackground(

                      status,

                    ),

                    borderRadius:

                        BorderRadius.circular(

                      14,

                    ),

                  ),

                  child: Text(

                    translateStatus(status),

                    style: TextStyle(

                      color: statusColor,

                      fontSize: 14,

                      fontWeight:

                          FontWeight.bold,

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }



  // ============================================================

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