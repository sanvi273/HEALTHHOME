import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import 'package:shared_preferences/shared_preferences.dart';



import '../../services/api_service.dart';

import 'lab_order_tracking_page.dart';



class LabOrdersPage extends StatefulWidget {

  const LabOrdersPage({

    super.key,

  });



  @override

  State<LabOrdersPage> createState() =>

      _LabOrdersPageState();

}



class _LabOrdersPageState

    extends State<LabOrdersPage> {

  // ============================================================

  // COLORS

  // ============================================================



  static const Color primaryColor =

      Color(0xff00C2CB);



  static const Color backgroundColor =

      Color(0xffF7F8FA);



  static const Color darkText =

      Color(0xff0F172A);



  // ============================================================

  // VARIABLES

  // ============================================================



  bool isLoading = true;



  List<dynamic> myOrders = [];



  String patientPhone = "";



  // ============================================================

  // COLLECTION OTP STORAGE

  //

  // orderId -> OTP

  // ============================================================



  final Map<String, String>

      collectionOtps = {};



  // orderId -> loading

  final Set<String>

      loadingOtpOrders = {};



  // orderId -> error message

  final Map<String, String>

      otpErrors = {};



  // ============================================================

  // INIT

  // ============================================================



  @override

  void initState() {

    super.initState();



    loadOrders();

  }



  // ============================================================

  // LOAD LAB ORDERS

  // ============================================================



  Future<void> loadOrders() async {

    try {

      if (mounted) {

        setState(() {

          isLoading = true;

        });

      }



      final prefs =

          await SharedPreferences

              .getInstance();



      patientPhone =

          prefs.getString(

                "patientPhone",

              ) ??

              prefs.getString(

                "userPhone",

              ) ??

              "";



      if (patientPhone

          .trim()

          .isEmpty) {

        throw Exception(

          "Patient phone number not found.",

        );

      }



      debugPrint(

        "======================================",

      );



      debugPrint(

        "LOADING PATIENT LAB ORDERS",

      );



      debugPrint(

        "PATIENT PHONE = $patientPhone",

      );



      debugPrint(

        "======================================",

      );



      final data =

          await ApiService.getLabOrders();



      final List<dynamic>

          allOrders =

          List<dynamic>.from(

        data,

      );



      // ========================================================

      // ONLY LOGGED-IN PATIENT'S ORDERS

      // ========================================================



      myOrders =

          allOrders.where(

        (order) {

          if (order is! Map) {

            return false;

          }



          final orderPhone =

              order["patientPhone"]

                      ?.toString()

                      .trim() ??

                  "";



          final orderPatientId =

              order["patientId"]

                      ?.toString()

                      .trim() ??

                  "";



          return orderPhone ==

                  patientPhone.trim() ||

              orderPatientId ==

                  patientPhone.trim();

        },

      ).toList();



      // ========================================================

      // NEWEST ORDER FIRST

      // ========================================================



      myOrders.sort(

        (a, b) {

          final aDate =

              DateTime.tryParse(

                    a["createdAt"]

                            ?.toString() ??

                        "",

                  ) ??

                  DateTime

                      .fromMillisecondsSinceEpoch(

                    0,

                  );



          final bDate =

              DateTime.tryParse(

                    b["createdAt"]

                            ?.toString() ??

                        "",

                  ) ??

                  DateTime

                      .fromMillisecondsSinceEpoch(

                    0,

                  );



          return bDate.compareTo(

            aDate,

          );

        },

      );



      debugPrint(

        "SORTED LAB ORDERS = $myOrders",

      );



      if (!mounted) {

        return;

      }



      setState(() {

        isLoading = false;

      });



      // ========================================================

      // LOAD OTPs FOR ACTIVE HOME COLLECTION ORDERS

      // ========================================================



      await loadCollectionOtps();



    } catch (e) {

      debugPrint(

        "LOAD LAB ORDERS ERROR = $e",

      );



      if (!mounted) {

        return;

      }



      setState(() {

        isLoading = false;

      });



      ScaffoldMessenger.of(

        context,

      ).showSnackBar(

        SnackBar(

          content: Text(

            "${"unableToLoadLabOrders".tr()} $e",

          ),

          backgroundColor:

              Colors.red,

        ),

      );

    }

  }



  // ============================================================

  // LOAD COLLECTION OTPs

  // ============================================================



  Future<void>

      loadCollectionOtps() async {

    if (myOrders.isEmpty) {

      return;

    }



    debugPrint(

      "======================================",

    );



    debugPrint(

      "LOADING LAB COLLECTION OTPs",

    );



    debugPrint(

      "======================================",

    );



    for (final rawOrder

        in myOrders) {

      try {

        if (rawOrder is! Map) {

          continue;

        }



        final Map<String, dynamic>

            order =

            Map<String, dynamic>.from(

          rawOrder,

        );



        final String orderId =

            order["_id"]

                    ?.toString() ??

                order["id"]

                    ?.toString() ??

                "";



        final String status =

            order["status"]

                    ?.toString() ??

                "";



        final String collectionMode =

            order["collectionMode"]

                    ?.toString() ??

                "";



        // ------------------------------------------------------

        // OTP ONLY FOR HOME COLLECTION

        // ------------------------------------------------------



        if (!isHomeCollection(

          collectionMode,

        )) {

          continue;

        }



        // ------------------------------------------------------

        // OTP ONLY WHEN COLLECTOR IS ON THE WAY

        // ------------------------------------------------------



        if (!isOnTheWay(

          status,

        )) {

          continue;

        }



        if (orderId.isEmpty) {

          continue;

        }



        await fetchCollectionOtp(

          orderId,

        );

      } catch (e) {

        debugPrint(

          "LAB OTP LOOP ERROR = $e",

        );

      }

    }

  }



  // ============================================================

  // FETCH COLLECTION OTP

  // ============================================================



  Future<void>

      fetchCollectionOtp(

    String orderId,

  ) async {

    if (orderId.isEmpty) {

      return;

    }



    if (loadingOtpOrders

        .contains(orderId)) {

      return;

    }



    if (mounted) {

      setState(() {

        loadingOtpOrders.add(

          orderId,

        );



        otpErrors.remove(

          orderId,

        );

      });

    }



    try {

      debugPrint(

        "======================================",

      );



      debugPrint(

        "GETTING LAB COLLECTION OTP",

      );



      debugPrint(

        "ORDER ID = $orderId",

      );



      debugPrint(

        "======================================",

      );



      final result =

          await ApiService

              .getCollectionOtp(

        orderId,

      );



      debugPrint(

        "LAB COLLECTION OTP RESULT = $result",

      );



      if (result["success"] ==

          true) {

        final String otp =

            result["collectionOtp"]

                    ?.toString()

                    .trim() ??

                "";



        if (otp.isNotEmpty) {

          if (!mounted) {

            return;

          }



          setState(() {

            collectionOtps[

                orderId] = otp;



            otpErrors.remove(

              orderId,

            );

          });



          debugPrint(

            "LAB COLLECTION OTP LOADED = $otp",

          );

        } else {

          if (!mounted) {

            return;

          }



          setState(() {

            otpErrors[

                    orderId] =

                "OTP was not returned by the server.";

          });

        }

      } else {

        final String message =

            result["message"]

                    ?.toString() ??

                "Unable to get collection OTP.";



        if (!mounted) {

          return;

        }



        setState(() {

          otpErrors[

              orderId] = message;

        });



        debugPrint(

          "LAB COLLECTION OTP ERROR = $message",

        );

      }

    } catch (e) {

      debugPrint(

        "FETCH LAB COLLECTION OTP ERROR = $e",

      );



      if (!mounted) {

        return;

      }



      setState(() {

        otpErrors[

            orderId] = e.toString();

      });

    } finally {

      if (!mounted) {

        return;

      }



      setState(() {

        loadingOtpOrders.remove(

          orderId,

        );

      });

    }

  }



  // ============================================================
  // PATIENT ID HELPER
  // ============================================================

  String getPatientId(Map<String, dynamic> order) {
    final value = order["patientId"];
    if (value is Map) {
      return (value["_id"] ?? value["id"] ?? "").toString().trim();
    }
    return (value ?? "").toString().trim();
  }

  bool canManageBooking(String status) {
    final value = status.trim().toLowerCase();
    return value == "pending" || value == "accepted";
  }

  Future<void> cancelBooking(Map<String, dynamic> order) async {
    final orderId = (order["_id"] ?? order["id"] ?? "").toString();
    final patientId = getPatientId(order);
    if (orderId.isEmpty || patientId.isEmpty) {
      _showMessage("Cannot cancel: booking or patient ID is missing.", isError: true);
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel lab booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please tell us why you want to cancel (optional)."),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Cancellation reason",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Keep booking")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Cancel booking"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    try {
      await ApiService.cancelLabOrder(
        orderId: orderId,
        patientId: patientId,
        reason: controller.text.trim(),
      );
      if (!mounted) return;
      _showMessage("Lab booking cancelled successfully.");
      await refreshOrders();
    } catch (e) {
      if (mounted) _showMessage("Unable to cancel booking: $e", isError: true);
    } finally {
      controller.dispose();
    }
  }

  Future<void> rescheduleBooking(Map<String, dynamic> order) async {
    final orderId = (order["_id"] ?? order["id"] ?? "").toString();
    final patientId = getPatientId(order);
    if (orderId.isEmpty || patientId.isEmpty) {
      _showMessage("Cannot reschedule: booking or patient ID is missing.", isError: true);
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Reschedule lab booking"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Choose your preferred new date and time. The laboratory must approve the request."),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, selectedTime.minute));
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(DateFormat('EEE, dd MMM yyyy').format(selectedDate)),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
                    if (picked != null) setDialogState(() {
                      selectedTime = picked;
                      selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute);
                    });
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedTime.format(dialogContext)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Reason (optional)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Back")),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Request reschedule")),
          ],
        ),
      ),
    );

    if (result != true) {
      reasonController.dispose();
      return;
    }

    final scheduledAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    if (!scheduledAt.isAfter(DateTime.now())) {
      reasonController.dispose();
      _showMessage("Please choose a future date and time.", isError: true);
      return;
    }

    try {
      await ApiService.requestLabReschedule(
        orderId: orderId,
        patientId: patientId,
        scheduledAt: scheduledAt,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      _showMessage("Reschedule request sent. Waiting for laboratory approval.");
      await refreshOrders();
    } catch (e) {
      if (mounted) _showMessage("Unable to request reschedule: $e", isError: true);
    } finally {
      reasonController.dispose();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : primaryColor),
    );
  }

  // ============================================================

  // REFRESH

  // ============================================================



  Future<void>

      refreshOrders() async {

    if (mounted) {

      setState(() {

        isLoading = true;



        collectionOtps.clear();



        otpErrors.clear();



        loadingOtpOrders.clear();

      });

    }



    await loadOrders();

  }



  // ============================================================

  // OPEN TRACKING

  // ============================================================



  void openTracking(

    Map<String, dynamic> order,

  ) {

    final String orderId =

        order["_id"]

                ?.toString() ??

            order["id"]

                ?.toString() ??

            "";



    if (orderId.isEmpty) {

      ScaffoldMessenger.of(

        context,

      ).showSnackBar(

        SnackBar(

          content: Text(

            "labOrderIdNotFound".tr(),

          ),

          backgroundColor:

              Colors.red,

        ),

      );



      return;

    }



    final String labName =

        order["labName"]

                ?.toString() ??

            "laboratory".tr();



    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>

            LabOrderTrackingPage(

          orderId: orderId,

          labName: labName,

        ),

      ),

    ).then((_) {

      loadOrders();

    });

  }



  // ============================================================

  // HOME COLLECTION CHECK

  // ============================================================



  bool isHomeCollection(

    String collectionMode,

  ) {

    final value =

        collectionMode

            .trim()

            .toLowerCase();



    return value ==

            "home collection" ||

        value ==

            "homecollection";

  }



  // ============================================================

  // ON THE WAY CHECK

  // ============================================================



  bool isOnTheWay(

    String status,

  ) {

    return status

            .trim()

            .toLowerCase() ==

        "on the way";

  }



  // ============================================================

  // STATUS TRANSLATION

  // ============================================================



  String translateStatus(

    String status,

  ) {

    switch (

        status.toLowerCase()) {

      case "completed":

        return "completed".tr();



      case "in progress":

        return "inProgress".tr();



      case "sample received":

        return "sampleReceived".tr();



      case "sample collected":

        return "sampleCollected".tr();



      case "on the way":

        return "onTheWay".tr();



      case "collector assigned":

        return "collectorAssigned".tr();



      case "accepted":

        return "accepted".tr();



      case "rejected":

        return "rejected".tr();



      case "pending":

        return "pending".tr();



      default:

        return status;

    }

  }



  // ============================================================

  // STATUS COLOR

  // ============================================================



  Color getStatusColor(

    String status,

  ) {

    switch (

        status.toLowerCase()) {

      case "completed":

        return Colors.green;



      case "in progress":

        return Colors.blue;



      case "sample received":

        return Colors.indigo;



      case "sample collected":

        return Colors.teal;



      case "on the way":

        return Colors.orange;



      case "collector assigned":

        return Colors.deepPurple;



      case "accepted":

        return Colors.teal;



      case "rejected":

        return Colors.red;



      case "pending":

        return Colors.grey;



      default:

        return Colors.grey;

    }

  }



  // ============================================================

  // BOOKING TYPE

  // ============================================================



  String getBookingType(

    Map<String, dynamic> order,

  ) {

    final String bookingType =

        order["bookingType"]

                ?.toString()

                .toUpperCase() ??

            "";



    if (bookingType ==

        "PRESCRIPTION") {

      return "prescriptionBooking"

          .tr();

    }



    return "labTestBooking".tr();

  }



  // ============================================================

  // BOOKING ICON

  // ============================================================



  IconData getBookingIcon(

    Map<String, dynamic> order,

  ) {

    final String bookingType =

        order["bookingType"]

                ?.toString()

                .toUpperCase() ??

            "";



    if (bookingType ==

        "PRESCRIPTION") {

      return Icons

          .description_outlined;

    }



    return Icons

        .biotech_outlined;

  }



  // ============================================================

  // COLLECTION OTP CARD

  // ============================================================



  Widget buildCollectionOtpCard(

    Map<String, dynamic> order,

  ) {

    final String orderId =

        order["_id"]

                ?.toString() ??

            order["id"]

                ?.toString() ??

            "";



    final String otp =

        collectionOtps[

                orderId] ??

            "";



    final bool loading =

        loadingOtpOrders

            .contains(orderId);



    final String error =

        otpErrors[orderId] ??

            "";



    return Container(

      width: double.infinity,



      margin:

          const EdgeInsets.only(

        top: 16,

      ),



      padding:

          const EdgeInsets.all(

        18,

      ),



      decoration:

          BoxDecoration(

        gradient:

            const LinearGradient(

          colors: [

            Color(0xffE6FBFC),

            Color(0xffF5FEFE),

          ],

          begin:

              Alignment.topLeft,

          end:

              Alignment.bottomRight,

        ),



        borderRadius:

            BorderRadius.circular(

          18,

        ),



        border:

            Border.all(

          color: primaryColor

              .withOpacity(

            0.35,

          ),

        ),

      ),



      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,



        children: [

          // ======================================================

          // HEADER

          // ======================================================



          Row(

            children: [

              Container(

                width: 46,

                height: 46,



                decoration:

                    BoxDecoration(

                  color: primaryColor

                      .withOpacity(

                    0.12,

                  ),

                  shape:

                      BoxShape.circle,

                ),



                child:

                    const Icon(

                  Icons

                      .lock_outline,

                  color:

                      primaryColor,

                  size: 25,

                ),

              ),



              const SizedBox(

                width: 12,

              ),



              const Expanded(

                child: Column(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,

                  children: [

                    Text(

                      "Collection Verification",

                      style:

                          TextStyle(

                        fontSize: 17,

                        fontWeight:

                            FontWeight.bold,

                        color:

                            darkText,

                      ),

                    ),



                    SizedBox(

                      height: 4,

                    ),



                    Text(

                      "Give this OTP to the sample collector",

                      style:

                          TextStyle(

                        fontSize: 12,

                        color:

                            Colors.black54,

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),



          const SizedBox(

            height: 18,

          ),



          // ======================================================

          // OTP BOX

          // ======================================================



          Container(

            width: double.infinity,



            padding:

                const EdgeInsets

                    .symmetric(

              vertical: 18,

              horizontal: 15,

            ),



            decoration:

                BoxDecoration(

              color:

                  Colors.white,



              borderRadius:

                  BorderRadius.circular(

                15,

              ),



              border:

                  Border.all(

                color: primaryColor

                    .withOpacity(

                  0.22,

                ),

              ),

            ),



            child:

                Column(

              children: [

                const Text(

                  "YOUR COLLECTION OTP",

                  style:

                      TextStyle(

                    fontSize: 11,

                    fontWeight:

                        FontWeight.w700,

                    letterSpacing:

                        1.2,

                    color:

                        Colors.black54,

                  ),

                ),



                const SizedBox(

                  height: 12,

                ),



                if (loading)

                  const Column(

                    children: [

                      SizedBox(

                        width: 28,

                        height: 28,

                        child:

                            CircularProgressIndicator(

                          strokeWidth:

                              3,

                          color:

                              primaryColor,

                        ),

                      ),



                      SizedBox(

                        height: 10,

                      ),



                      Text(

                        "Getting collection OTP...",

                        textAlign:

                            TextAlign

                                .center,

                        style:

                            TextStyle(

                          fontSize:

                              13,

                          color:

                              Colors.orange,

                          fontWeight:

                              FontWeight.w600,

                        ),

                      ),

                    ],

                  )



                else if (otp.isNotEmpty)

                  Column(

                    children: [

                      Text(

                        otp,

                        style:

                            const TextStyle(

                          fontSize:

                              34,

                          fontWeight:

                              FontWeight.bold,

                          letterSpacing:

                              8,

                          color:

                              primaryColor,

                        ),

                      ),



                      const SizedBox(

                        height: 8,

                      ),



                      const Text(

                        "Tell this OTP to the sample collector",

                        textAlign:

                            TextAlign

                                .center,

                        style:

                            TextStyle(

                          fontSize:

                              12,

                          color:

                              Colors.black54,

                        ),

                      ),

                    ],

                  )



                else if (error.isNotEmpty)

                  Column(

                    children: [

                      const Icon(

                        Icons

                            .error_outline,

                        color:

                            Colors.redAccent,

                        size: 32,

                      ),



                      const SizedBox(

                        height: 8,

                      ),



                      Text(

                        error,

                        textAlign:

                            TextAlign

                                .center,

                        style:

                            const TextStyle(

                          fontSize:

                              13,

                          fontWeight:

                              FontWeight.w600,

                          color:

                              Colors.redAccent,

                        ),

                      ),



                      const SizedBox(

                        height: 13,

                      ),



                      OutlinedButton

                          .icon(

                        onPressed:

                            () {

                          fetchCollectionOtp(

                            orderId,

                          );

                        },



                        icon:

                            const Icon(

                          Icons.refresh,

                          size: 18,

                        ),



                        label:

                            const Text(

                          "Try Again",

                        ),



                        style:

                            OutlinedButton

                                .styleFrom(

                          foregroundColor:

                              primaryColor,



                          side:

                              const BorderSide(

                            color:

                                primaryColor,

                          ),



                          shape:

                              RoundedRectangleBorder(

                            borderRadius:

                                BorderRadius.circular(

                              10,

                            ),

                          ),

                        ),

                      ),

                    ],

                  )



                else

                  const Column(

                    children: [

                      Icon(

                        Icons

                            .sms_outlined,

                        color:

                            Colors.orange,

                        size: 30,

                      ),



                      SizedBox(

                        height: 8,

                      ),



                      Text(

                        "Collection OTP is being prepared.",

                        textAlign:

                            TextAlign

                                .center,

                        style:

                            TextStyle(

                          fontSize:

                              13,

                          fontWeight:

                              FontWeight.w600,

                          color:

                              Colors.orange,

                        ),

                      ),

                    ],

                  ),

              ],

            ),

          ),



          const SizedBox(

            height: 12,

          ),



          // ======================================================

          // INFO

          // ======================================================



          Row(

            crossAxisAlignment:

                CrossAxisAlignment

                    .start,



            children: [

              const Icon(

                Icons

                    .info_outline,

                size: 17,

                color:

                    Colors.black54,

              ),



              const SizedBox(

                width: 8,

              ),



              Expanded(

                child: Text(

                  otp.isNotEmpty

                      ? "Share this OTP only when the sample collector arrives."

                      : "The OTP is available only while the collector is On The Way.",



                  style:

                      const TextStyle(

                    fontSize: 12,

                    color:

                        Colors.black54,

                    height: 1.4,

                  ),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  // ============================================================

  // EMPTY ORDERS

  // ============================================================



  Widget buildEmptyOrders() {

    return RefreshIndicator(

      onRefresh:

          refreshOrders,



      color:

          primaryColor,



      child: ListView(

        physics:

            const AlwaysScrollableScrollPhysics(),



        children: [

          const SizedBox(

            height: 150,

          ),



          const Center(

            child: Icon(

              Icons

                  .biotech_outlined,

              size: 75,

              color:

                  Colors.grey,

            ),

          ),



          const SizedBox(

            height: 18,

          ),



          Center(

            child: Text(

              "noLabOrdersFound"

                  .tr(),



              style:

                  const TextStyle(

                fontSize: 18,

                fontWeight:

                    FontWeight.bold,

                color:

                    darkText,

              ),

            ),

          ),



          const SizedBox(

            height: 8,

          ),



          Center(

            child: Text(

              "labBookingsWillAppearHere"

                  .tr(),



              style:

                  const TextStyle(

                color:

                    Colors.black54,

              ),

            ),

          ),

        ],

      ),

    );

  }



  // ============================================================

  // BUILD

  // ============================================================



  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor:

          backgroundColor,



      appBar: AppBar(

        backgroundColor:

            Colors.white,



        foregroundColor:

            darkText,



        elevation: 0,



        title: Text(

          "myLabOrders".tr(),



          style:

              const TextStyle(

            fontWeight:

                FontWeight.bold,

          ),

        ),



        actions: [

          IconButton(

            onPressed:

                refreshOrders,

            icon:

                const Icon(

              Icons.refresh,

            ),

          ),

        ],

      ),



      body: isLoading

          ? const Center(

              child:

                  CircularProgressIndicator(

                color:

                    primaryColor,

              ),

            )



          : myOrders.isEmpty

              ? buildEmptyOrders()



              : RefreshIndicator(

                  onRefresh:

                      refreshOrders,



                  color:

                      primaryColor,



                  child:

                      ListView.builder(

                    physics:

                        const AlwaysScrollableScrollPhysics(),



                    padding:

                        const EdgeInsets

                            .all(

                      16,

                    ),



                    itemCount:

                        myOrders.length,



                    itemBuilder:

                        (

                      context,

                      index,

                    ) {

                      final Map<String,

                              dynamic>

                          order =

                          Map<String,

                              dynamic>.from(

                        myOrders[index],

                      );



                      final String orderId =

                          order["_id"]

                                  ?.toString() ??

                              order["id"]

                                  ?.toString() ??

                              "";



                      final String labName =

                          order["labName"]

                                  ?.toString() ??

                              "laboratory"

                                  .tr();



                      final String status =

                          order["status"]

                                  ?.toString() ??

                              "Pending";



                      final String collectionMode =

                          order["collectionMode"]

                                  ?.toString() ??

                              "Home Collection";



                      final String bookingType =

                          getBookingType(

                        order,

                      );



                      final Color

                          statusColor =

                          getStatusColor(

                        status,

                      );



                      final List<dynamic>

                          tests =

                          order["tests"]

                                  is List

                              ? List<dynamic>

                                  .from(

                                order[

                                    "tests"],

                              )

                              : [];



                      final bool showOtp =

                          isHomeCollection(

                                collectionMode,

                              ) &&

                              isOnTheWay(

                                status,

                              );



                      return Container(

                        margin:

                            const EdgeInsets

                                .only(

                          bottom: 16,

                        ),



                        decoration:

                            BoxDecoration(

                          color:

                              Colors.white,



                          borderRadius:

                              BorderRadius

                                  .circular(

                            20,

                          ),



                          boxShadow: [

                            BoxShadow(

                              color: Colors

                                  .black

                                  .withOpacity(

                                0.05,

                              ),

                              blurRadius:

                                  10,

                              offset:

                                  const Offset(

                                0,

                                4,

                              ),

                            ),

                          ],

                        ),



                        child:

                            Padding(

                          padding:

                              const EdgeInsets

                                  .all(

                            16,

                          ),



                          child:

                              Column(

                            crossAxisAlignment:

                                CrossAxisAlignment

                                    .start,



                            children: [

                              // ==============================================

                              // HEADER

                              // ==============================================



                              Row(

                                children: [

                                  Container(

                                    width:

                                        52,

                                    height:

                                        52,



                                    decoration:

                                        BoxDecoration(

                                      color: primaryColor

                                          .withOpacity(

                                        0.10,

                                      ),

                                      shape:

                                          BoxShape.circle,

                                    ),



                                    child:

                                        Icon(

                                      getBookingIcon(

                                        order,

                                      ),

                                      color:

                                          primaryColor,

                                      size:

                                          27,

                                    ),

                                  ),



                                  const SizedBox(

                                    width:

                                        12,

                                  ),



                                  Expanded(

                                    child:

                                        Column(

                                      crossAxisAlignment:

                                          CrossAxisAlignment

                                              .start,



                                      children: [

                                        Text(

                                          labName,

                                          style:

                                              const TextStyle(

                                            fontSize:

                                                17,

                                            fontWeight:

                                                FontWeight.bold,

                                            color:

                                                darkText,

                                          ),

                                        ),



                                        const SizedBox(

                                          height:

                                              4,

                                        ),



                                        Text(

                                          bookingType,

                                          style:

                                              const TextStyle(

                                            color:

                                                Colors.black54,

                                            fontSize:

                                                13,

                                          ),

                                        ),



                                        const SizedBox(

                                          height:

                                              4,

                                        ),



                                        Text(

                                          orderId.isEmpty

                                              ? "orderIdUnavailable"

                                                  .tr()

                                              : "${"orderIdLabel".tr()}: $orderId",



                                          maxLines:

                                              1,



                                          overflow:

                                              TextOverflow

                                                  .ellipsis,



                                          style:

                                              const TextStyle(

                                            color:

                                                Colors.grey,

                                            fontSize:

                                                11,

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),



                                  const SizedBox(

                                    width:

                                        8,

                                  ),



                                  Container(

                                    padding:

                                        const EdgeInsets

                                            .symmetric(

                                      horizontal:

                                          10,

                                      vertical:

                                          6,

                                    ),



                                    decoration:

                                        BoxDecoration(

                                      color:

                                          statusColor

                                              .withOpacity(

                                        0.12,

                                      ),



                                      borderRadius:

                                          BorderRadius

                                              .circular(

                                        20,

                                      ),

                                    ),



                                    child:

                                        Text(

                                      translateStatus(

                                        status,

                                      ),



                                      style:

                                          TextStyle(

                                        color:

                                            statusColor,

                                        fontWeight:

                                            FontWeight.bold,

                                        fontSize:

                                            11,

                                      ),

                                    ),

                                  ),

                                ],

                              ),



                              const SizedBox(

                                height:

                                    15,

                              ),



                              const Divider(),



                              const SizedBox(

                                height:

                                    10,

                              ),



                              // ==============================================

                              // COLLECTION MODE

                              // ==============================================



                              Row(

                                children: [

                                  const Icon(

                                    Icons

                                        .local_shipping_outlined,

                                    size:

                                        19,

                                    color:

                                        Colors.black54,

                                  ),



                                  const SizedBox(

                                    width:

                                        8,

                                  ),



                                  Expanded(

                                    child:

                                        Text(

                                      collectionMode,



                                      style:

                                          const TextStyle(

                                        color:

                                            Colors.black54,

                                        fontSize:

                                            14,

                                      ),

                                    ),

                                  ),

                                ],

                              ),



                              // ==============================================

                              // TEST COUNT

                              // ==============================================



                              if (tests

                                  .isNotEmpty) ...[

                                const SizedBox(

                                  height:

                                      10,

                                ),



                                Row(

                                  children: [

                                    const Icon(

                                      Icons

                                          .science_outlined,

                                      size:

                                          19,

                                      color:

                                          Colors.black54,

                                    ),



                                    const SizedBox(

                                      width:

                                          8,

                                    ),



                                    Expanded(

                                      child:

                                          Text(

                                        "${tests.length} test${tests.length == 1 ? '' : 's'} booked",



                                        style:

                                            const TextStyle(

                                          color:

                                              Colors.black54,

                                          fontSize:

                                              14,

                                        ),

                                      ),

                                    ),

                                  ],

                                ),

                              ],



                              // ==============================================

                              // COLLECTION OTP

                              // ==============================================



                              if (showOtp)

                                buildCollectionOtpCard(

                                  order,

                                ),



                              const SizedBox(

                                height:

                                    16,

                              ),



                              // ==============================================

                              // TRACK ORDER

                              // ==============================================



                              SizedBox(

                                width:

                                    double.infinity,



                                height:

                                    48,



                                child:

                                    ElevatedButton

                                        .icon(

                                  onPressed:

                                      orderId

                                              .isEmpty

                                          ? null

                                          : () =>

                                              openTracking(

                                                order,

                                              ),



                                  icon:

                                      const Icon(

                                    Icons

                                        .location_on_outlined,

                                  ),



                                  label:

                                      Text(

                                    "trackLabOrder"

                                        .tr(),



                                    style:

                                        const TextStyle(

                                      fontWeight:

                                          FontWeight.bold,

                                    ),

                                  ),



                                  style:

                                      ElevatedButton

                                          .styleFrom(

                                    backgroundColor:

                                        primaryColor,



                                    foregroundColor:

                                        Colors.white,



                                    elevation:

                                        0,



                                    shape:

                                        RoundedRectangleBorder(

                                      borderRadius:

                                          BorderRadius

                                              .circular(

                                        13,

                                      ),

                                    ),

                                  ),

                                ),

                              ),

                              // CANCEL / RESCHEDULE ACTIONS
                              if (canManageBooking(status)) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: orderId.isEmpty ? null : () => rescheduleBooking(order),
                                        icon: const Icon(Icons.edit_calendar_outlined),
                                        label: const Text("Reschedule"),
                                        style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: const BorderSide(color: primaryColor)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: orderId.isEmpty ? null : () => cancelBooking(order),
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text("Cancel booking"),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((order["rescheduleStatus"] ?? "").toString().toLowerCase() == "pending") ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                                  child: const Row(children: [Icon(Icons.hourglass_top, color: Colors.orange), SizedBox(width: 8), Expanded(child: Text("Reschedule request pending laboratory approval."))]),
                                ),
                              ],


                            ],

                          ),

                        ),

                      );

                    },

                  ),

                ),

    );

  }

}