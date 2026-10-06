import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../payment/payment_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class BookAppointmentPage extends StatefulWidget {
  final Map doctor;

  const BookAppointmentPage({
    super.key,
    required this.doctor,
  });

  @override
  State<BookAppointmentPage> createState() =>
      _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final TextEditingController dateController =
      TextEditingController();

  final TextEditingController timeController =
      TextEditingController();

  bool loading = false;

  bool loadingSlots = false;

  String consultationType = "Video Consultation";

  final ImagePicker picker = ImagePicker();

  List<File> reports = [];

  List<Map<String, dynamic>> availableSlots = [];

  // ============================================================
  // PICK REPORT
  // ============================================================

  Future<void> pickReport() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text("gallery".tr()),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? image =
                      await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    setState(() {
                      reports.add(File(image.path));
                    });
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text("pdf".tr()),
                onTap: () async {
                  Navigator.pop(context);

                  final result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ["pdf"],
                  );

                  if (result != null &&
                      result.files.single.path != null) {
                    setState(() {
                      reports.add(
                        File(result.files.single.path!),
                      );
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // GET AVAILABLE SLOTS
  // ============================================================

  Future<void> loadAvailableSlots(String date) async {
    if (date.isEmpty) return;

    setState(() {
      loadingSlots = true;
      availableSlots = [];
      timeController.clear();
    });

    try {
      final doctorId =
          widget.doctor["_id"]?.toString() ?? "";

      if (doctorId.isEmpty) {
        throw Exception("Doctor ID is missing");
      }

      debugPrint("================================");
      debugPrint("LOADING AVAILABLE SLOTS");
      debugPrint("DOCTOR ID = $doctorId");
      debugPrint("DATE = $date");
      debugPrint("================================");

      final slots =
          await ApiService.getAvailableSlots(
        doctorId: doctorId,
        date: date,
      );

      if (!mounted) return;

      setState(() {
        availableSlots = slots
            .where(
              (slot) =>
                  slot["available"] == true,
            )
            .toList();
      });

      debugPrint(
        "AVAILABLE SLOT COUNT = ${availableSlots.length}",
      );
    } catch (e) {
      debugPrint(
        "LOAD AVAILABLE SLOTS ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        availableSlots = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "failedToLoadAvailableSlots".tr(
              args: [e.toString()],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingSlots = false;
        });
      }
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,

      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),

      lastDate: DateTime(2030),

      initialDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),

      helpText: "selectAppointmentDate".tr(),

      cancelText: "cancel".tr(),

      confirmText: "ok".tr(),

      fieldLabelText: "appointmentDate".tr(),

      fieldHintText: "dateFormatHint".tr(),
    );

    if (date == null) return;

    // Safe format for backend/API
    final formattedDate =
        "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";

    setState(() {
      dateController.text = formattedDate;
      timeController.clear();
      availableSlots = [];
    });

    await loadAvailableSlots(formattedDate);
  }

  // ============================================================
  // SELECT SLOT
  // ============================================================

  void selectSlot(String slot) {
    setState(() {
      timeController.text = slot;
    });
  }

  // ============================================================
  // BOOK APPOINTMENT
  // ============================================================

  Future<void> bookAppointment() async {
    // ============================================================
    // VALIDATION
    // ============================================================

    if (dateController.text.isEmpty ||
        timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "pleaseSelectDateAndTime".tr(),
          ),
        ),
      );

      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final String patientName =
        prefs.getString("patientName") ?? "Patient";

    final String patientPhone =
        prefs.getString("patientPhone") ?? "";

    if (patientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "patientPhoneNotFound".tr(),
          ),
        ),
      );

      return;
    }

    // ============================================================
    // DOCTOR DATA
    // ============================================================

    final String doctorId =
        widget.doctor["_id"]?.toString() ?? "";

    final String doctorName =
        widget.doctor["name"]?.toString() ?? "";

    final String specialization =
        widget.doctor["specialization"]?.toString() ?? "";

    final String hospital =
        widget.doctor["hospital"]?.toString() ?? "";

    final String fees =
        widget.doctor["fees"]?.toString() ?? "0";

    // ============================================================
    // VALIDATE DOCTOR
    // ============================================================

    if (doctorId.isEmpty ||
        doctorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "doctorInformationIncomplete".tr(),
          ),
        ),
      );

      return;
    }

    // ============================================================
    // PAYMENT
    // ============================================================

    final double consultationFee =
        double.tryParse(fees) ?? 0;

    if (consultationFee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "invalidConsultationFee".tr(),
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    // ============================================================
    // PAYMENT
    // ============================================================

    final Map<String, dynamic>? paymentResult =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          amount: consultationFee,
          userId: patientPhone,
          userName: patientName,
          userPhone: patientPhone,
          serviceType: "Doctor",
          serviceId: doctorId,
        ),
      ),
    );

    // ============================================================
    // PAYMENT CANCELLED / FAILED
    // ============================================================

    if (paymentResult == null ||
        paymentResult["success"] != true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "paymentCancelled".tr(),
          ),
        ),
      );

      return;
    }

    // ============================================================
    // GET VERIFIED PAYMENT DETAILS
    // ============================================================

    final String razorpayOrderId =
        paymentResult["orderId"]?.toString() ?? "";

    final String paymentId =
        paymentResult["paymentId"]?.toString() ?? "";

    if (razorpayOrderId.isEmpty ||
        paymentId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "paymentInformationIncomplete".tr(),
          ),
        ),
      );

      return;
    }

    debugPrint("================================");
    debugPrint("PAYMENT VERIFIED");
    debugPrint("ORDER ID = $razorpayOrderId");
    debugPrint("PAYMENT ID = $paymentId");
    debugPrint("DOCTOR ID = $doctorId");
    debugPrint(
      "DATE = ${dateController.text}",
    );
    debugPrint(
      "TIME = ${timeController.text}",
    );
    debugPrint(
      "CONSULTATION = $consultationType",
    );
    debugPrint("================================");

    // ============================================================
    // START BOOKING
    // ============================================================

    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      // ==========================================================
      // BOOK APPOINTMENT
      // ==========================================================

      final response =
          await ApiService.bookAppointment(
        patientName: patientName,
        patientPhone: patientPhone,

        doctorId: doctorId,

        doctorName: doctorName,

        specialization: specialization,

        hospital: hospital,

        fees: fees,

        consultationType: consultationType,

        appointmentDate:
            dateController.text,

        appointmentTime:
            timeController.text,

        reports: reports,

        paymentStatus: "Paid",

        razorpayOrderId:
            razorpayOrderId,

        paymentId:
            paymentId,
      );

      if (!mounted) return;

      // ==========================================================
      // SUCCESS
      // ==========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"] ??
                "appointmentBookedSuccessfully".tr(),
          ),
        ),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(
            "appointmentBooked".tr(),
          ),
          content: Text(
            "appointmentBookedMessage".tr(
              args: [doctorName],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                "ok".tr(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint(
        "BOOK APPOINTMENT ERROR = $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "failedToBookAppointment".tr(
              args: [e.toString()],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(
          "bookAppointment".tr(),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // ==================================================
            // DOCTOR INFORMATION
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),

              child: Row(
                children: [

                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        const Color(0xff10BEC4)
                            .withOpacity(0.12),

                    child: const Icon(
                      Icons.person,
                      color: Color(0xff10BEC4),
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
                          "Dr. ${widget.doctor["name"] ?? ""}",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.doctor[
                                  "specialization"] ??
                              "",
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "₹${widget.doctor["fees"] ?? "0"}",
                          style: const TextStyle(
                            color:
                                Color(0xff10BEC4),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CONSULTATION TYPE
            // ==================================================

            Align(
              alignment:
                  Alignment.centerLeft,

              child: Text(
                "consultationType".tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Column(
                children: [

                  RadioListTile<String>(
                    value:
                        "Video Consultation",

                    groupValue:
                        consultationType,

                    activeColor:
                        const Color(0xff10BEC4),

                    title: Text(
                      "videoConsultation".tr(),
                    ),

                    subtitle: Text(
                      "consultDoctorVideoCall".tr(),
                    ),

                    secondary:
                        const Icon(
                      Icons.video_camera_front,
                    ),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        consultationType =
                            value;
                      });
                    },
                  ),

                  const Divider(
                    height: 1,
                  ),

                  RadioListTile<String>(
                    value:
                        "Hospital Visit",

                    groupValue:
                        consultationType,

                    activeColor:
                        const Color(0xff10BEC4),

                    title: Text(
                      "hospitalVisit".tr(),
                    ),

                    subtitle: Text(
                      "visitDoctorHospital".tr(),
                    ),

                    secondary:
                        const Icon(
                      Icons.local_hospital,
                    ),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        consultationType =
                            value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DATE
            // ==================================================

            Align(
              alignment:
                  Alignment.centerLeft,

              child: Text(
                "selectAppointmentDate".tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller:
                  dateController,

              readOnly: true,

              decoration:
                  InputDecoration(
                labelText:
                    "appointmentDate".tr(),

                border:
                    const OutlineInputBorder(),

                prefixIcon:
                    const Icon(
                  Icons.calendar_month,
                  color:
                      Color(0xff10BEC4),
                ),

                suffixIcon:
                    const Icon(
                  Icons.arrow_drop_down,
                ),
              ),

              onTap: selectDate,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // AVAILABLE SLOTS
            // ==================================================

            if (dateController
                .text
                .isNotEmpty) ...[

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  "availableSlots".tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (loadingSlots)

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(25),

                  decoration:
                      BoxDecoration(
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),

                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Column(
                    children: [

                      const CircularProgressIndicator(
                        color:
                            Color(0xff10BEC4),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "loadingAvailableSlots".tr(),
                      ),
                    ],
                  ),
                )

              else if (availableSlots
                  .isEmpty)

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(18),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,

                    borderRadius:
                        BorderRadius.circular(12),

                    border: Border.all(
                      color:
                          Colors.red.shade200,
                    ),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          "noAvailableSlots".tr(),
                          style: const TextStyle(
                            color:
                                Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                )

              else

                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children:
                      availableSlots.map(
                    (slot) {

                      final String time =
                          slot["time"]
                                  ?.toString() ??
                              "";

                      final bool selected =
                          timeController
                                  .text ==
                              time;

                      return InkWell(
                        borderRadius:
                            BorderRadius
                                .circular(10),

                        onTap: () {
                          selectSlot(time);
                        },

                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),

                          decoration:
                              BoxDecoration(
                            color: selected
                                ? const Color(
                                    0xff10BEC4)
                                : Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(10),

                            border:
                                Border.all(
                              color: selected
                                  ? const Color(
                                      0xff10BEC4)
                                  : Colors.grey
                                      .shade300,
                            ),
                          ),

                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [

                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: selected
                                    ? Colors.white
                                    : const Color(
                                        0xff10BEC4),
                              ),

                              const SizedBox(
                                width: 6,
                              ),

                              Text(
                                time,

                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w600,

                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

              const SizedBox(height: 20),

              // ==================================================
              // SELECTED TIME
              // ==================================================

              TextField(
                controller:
                    timeController,

                readOnly: true,

                decoration:
                    InputDecoration(
                  labelText:
                      "selectedAppointmentTime".tr(),

                  border:
                      const OutlineInputBorder(),

                  prefixIcon:
                      const Icon(
                    Icons.access_time,
                    color:
                        Color(0xff10BEC4),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ==================================================
            // UPLOAD REPORTS
            // ==================================================

            Align(
              alignment:
                  Alignment.centerLeft,

              child: Text(
                "uploadReportsOptional".tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: pickReport,

              child: Container(
                padding:
                    const EdgeInsets.all(16),

                decoration:
                    BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),

                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.upload_file,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "uploadReport".tr(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (reports.isNotEmpty)
              Column(
                children:
                    reports.asMap().entries.map(
                  (entry) {

                    return ListTile(
                      leading:
                          const Icon(
                        Icons.insert_drive_file,
                      ),

                      title: Text(
                        entry.value.path
                            .split('/')
                            .last,
                      ),

                      trailing:
                          IconButton(
                        icon:
                            const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),

                        onPressed: () {
                          setState(() {
                            reports.removeAt(
                                entry.key);
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),

            const SizedBox(height: 20),

            // ==================================================
            // CONFIRM BOOKING
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height: 55,

              child: ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : bookAppointment,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff10BEC4),

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "confirmBooking".tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
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

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}