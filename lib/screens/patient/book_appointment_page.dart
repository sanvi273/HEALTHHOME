import 'dart:io';



import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_picker/image_picker.dart';

import 'package:file_picker/file_picker.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';



import '../../services/api_service.dart';



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



class _BookAppointmentPageState

  extends State<BookAppointmentPage> {

 // ============================================================

 // CONTROLLERS

 // ============================================================



 final TextEditingController dateController =

   TextEditingController();



 final TextEditingController timeController =

   TextEditingController();



 // ============================================================

 // RAZORPAY

 // ============================================================



 late Razorpay _razorpay;



 String _pendingAppointmentId = "";

 String _pendingRazorpayOrderId = "";



 // ============================================================

 // STATE

 // ============================================================



 bool loading = false;

 bool loadingSlots = false;



 String consultationType = "Video Consultation";



 final ImagePicker picker = ImagePicker();



 List<File> reports = [];



 List<Map<String, dynamic>> availableSlots = [];



 // ============================================================

 // INIT STATE

 // ============================================================



 @override

 void initState() {

  super.initState();



  _razorpay = Razorpay();



  _razorpay.on(

   Razorpay.EVENT_PAYMENT_SUCCESS,

   _handlePaymentSuccess,

  );



  _razorpay.on(

   Razorpay.EVENT_PAYMENT_ERROR,

   _handlePaymentError,

  );



  _razorpay.on(

   Razorpay.EVENT_EXTERNAL_WALLET,

   _handleExternalWallet,

  );

 }



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

       // --------------------------------------------------

       // GALLERY

       // --------------------------------------------------



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

           reports.add(

            File(image.path),

           );

          });

         }

        },

       ),



       // --------------------------------------------------

       // PDF

       // --------------------------------------------------



       ListTile(

        leading: const Icon(

         Icons.picture_as_pdf,

        ),

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

            File(

             result.files.single.path!,

            ),

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



 Future<void> loadAvailableSlots(

  String date,

 ) async {

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

    throw Exception(

     "Doctor ID is missing",

    );

   }



   debugPrint(

    "========================================",

   );

   debugPrint(

    "LOADING AVAILABLE SLOTS",

   );

   debugPrint(

    "DOCTOR ID = $doctorId",

   );

   debugPrint(

    "DATE = $date",

   );

   debugPrint(

    "========================================",

   );



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

    "AVAILABLE SLOT COUNT = "

    "${availableSlots.length}",

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
// Date format used by the backend: YYYY-MM-DD
String selectedDateApi = '';

Future<void> selectDate() async {
  final now = DateTime.now();

  final date = await showDatePicker(
    context: context,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(2030),
    initialDate: DateTime(now.year, now.month, now.day),
    helpText: "selectAppointmentDate".tr(),
    cancelText: "cancel".tr(),
    confirmText: "ok".tr(),
    fieldLabelText: "appointmentDate".tr(),
    fieldHintText: "dateFormatHint".tr(),
  );

  if (date == null || !mounted) return;

  // Display format for the patient.
  final displayDate =
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';

  // API format for the backend.
  final apiDate =
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  setState(() {
    dateController.text = displayDate;
    selectedDateApi = apiDate;
    timeController.clear();
    availableSlots = [];
  });

  await loadAvailableSlots(selectedDateApi);
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

 //

 // NEW FLOW:

 //

 // 1. Backend creates Pending appointment

 // 2. Backend creates Razorpay order

 // 3. Razorpay Checkout opens

 // 4. User pays using UPI

 // 5. Flutter receives payment callback

 // 6. Backend verifies payment

 // 7. Backend marks appointment Paid

 //

 // IMPORTANT:

 // We DO NOT call old bookAppointment() after payment.

 // ============================================================



 Future<void> bookAppointment() async {

  // ==========================================================

  // VALIDATION

  // ==========================================================



  
if (selectedDateApi.isEmpty ||
    dateController.text.trim().isEmpty ||
    timeController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("pleaseSelectDateAndTime".tr()),
    ),
  );
  return;
}




  if (loading) {

   return;

  }



  // ==========================================================

  // PATIENT DATA

  // ==========================================================



  final prefs =

    await SharedPreferences.getInstance();



  final String patientName =

    prefs.getString("patientName") ??

      "Patient";



  final String patientPhone =

    prefs.getString("patientPhone") ??

      "";



  if (patientPhone.trim().isEmpty) {

   ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

     content: Text(

      "patientPhoneNotFound".tr(),

     ),

    ),

   );



   return;

  }



  // ==========================================================

  // DOCTOR DATA

  // ==========================================================



  final String doctorId =

    widget.doctor["_id"]?.toString() ?? "";



  final String doctorName =

    widget.doctor["name"]?.toString() ?? "";



  final String specialization =

    widget.doctor["specialization"]

        ?.toString() ??

      "";



  final String hospital =

    widget.doctor["hospital"]?.toString() ??

      "";



  final String fees =

    widget.doctor["fees"]?.toString() ??

      "0";



  // ==========================================================

  // VALIDATE DOCTOR

  // ==========================================================



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



  // ==========================================================

  // CONSULTATION FEE

  //

  // This is ONLY used for UI validation.

  //

  // Backend MUST calculate the real amount.

  // ==========================================================



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



  // ==========================================================

  // RESET PREVIOUS PAYMENT STATE

  // ==========================================================



  _pendingAppointmentId = "";

  _pendingRazorpayOrderId = "";



  // ==========================================================

  // START LOADING

  // ==========================================================



  setState(() {

   loading = true;

  });



  try {

   debugPrint(

    "========================================",

   );

   debugPrint(

    "CREATE DOCTOR PAYMENT",

   );

   debugPrint(

    "========================================",

   );



   debugPrint(

    "PATIENT = $patientName",

   );



   debugPrint(

    "PHONE = $patientPhone",

   );



   debugPrint(

    "DOCTOR ID = $doctorId",

   );



   debugPrint(

    "DOCTOR NAME = $doctorName",

   );



   debugPrint(

    "SPECIALIZATION = $specialization",

   );



   debugPrint(

    "HOSPITAL = $hospital",

   );



   debugPrint(

    "CONSULTATION TYPE = "

    "$consultationType",

   );



   debugPrint(

    "DATE = ${dateController.text}",

   );



   debugPrint(

    "TIME = ${timeController.text}",

   );



   debugPrint(

    "DISPLAY FEE = ₹$consultationFee",

   );



   // ========================================================

   // STEP 1

   // CREATE PENDING APPOINTMENT +

   // RAZORPAY ORDER

   // ========================================================



   final Map<String, dynamic>

     orderResponse =

     await ApiService

       .createDoctorPaymentOrder(

    patientName: patientName,

    patientPhone: patientPhone,

    doctorId: doctorId,

    doctorName: doctorName,

    specialization: specialization,

    hospital: hospital,

    consultationType:

      consultationType,

    appointmentDate: selectedDateApi,

    appointmentTime:

      timeController.text.trim(),

   
        reports: reports,
      );



   debugPrint(

    "========================================",

   );



   debugPrint(

    "CREATE DOCTOR PAYMENT RESPONSE",

   );



   debugPrint(

    "$orderResponse",

   );



   debugPrint(

    "========================================",

   );



   // ========================================================

   // CHECK SUCCESS

   // ========================================================



   if (orderResponse["success"] != true) {

    throw Exception(

     orderResponse["message"] ??

       "Unable to create payment order.",

    );

   }



   // ========================================================

   // GET APPOINTMENT ID

   // ========================================================



    _pendingAppointmentId =
  
      orderResponse[
  
            "appointmentId"]
  
          ?.toString() ??
  
        orderResponse["appointment"]
  
          ?["_id"]
  
          ?.toString() ??
  
        ""; 



   // ========================================================

   // GET RAZORPAY ORDER ID

   // ========================================================



   _pendingRazorpayOrderId =

     orderResponse[

           "razorpayOrderId"]

         ?.toString() ??

       orderResponse["order"]

         ?["id"]

         ?.toString() ??

       "";



   // ========================================================

   // GET RAZORPAY PUBLIC KEY

   // ========================================================



   final String razorpayKey =

     orderResponse["key"]

         ?.toString() ??

       orderResponse["keyId"]

         ?.toString() ??

       "";



   // ========================================================

   // GET AMOUNT

   // ========================================================



   final int amountInPaise =

     int.tryParse(

        orderResponse["amount"]

            ?.toString() ??

          "",

       ) ??

       (consultationFee * 100)

         .round();



   // ========================================================

   // GET CURRENCY

   // ========================================================



   final String currency =

     orderResponse["currency"]

         ?.toString() ??

       "INR";



   // ========================================================

   // VALIDATE SERVER RESPONSE

   // ========================================================



   if (_pendingAppointmentId

     .isEmpty) {

    throw Exception(

     "Appointment ID was not returned by server.",

    );

   }



   if (_pendingRazorpayOrderId

     .isEmpty) {

    throw Exception(

     "Razorpay Order ID was not returned by server.",

    );

   }



   if (razorpayKey.isEmpty) {

    throw Exception(

     "Razorpay Key ID was not returned by server.",

    );

   }



   // ========================================================

   // STOP PAGE LOADING

   // ========================================================



   if (mounted) {

    setState(() {

     loading = false;

    });

   }



   // ========================================================

   // STEP 2

   // RAZORPAY CHECKOUT

   // ========================================================


final Map<String, dynamic> options = {
  "key": razorpayKey,
  "amount": amountInPaise,
  "currency": currency,
  "name": "HealthHome",
  "description": "Doctor Consultation",
  "order_id": _pendingRazorpayOrderId,

  "prefill": {
    "name": patientName,
    "contact": patientPhone,
  },

  "notes": {
    "appointmentId": _pendingAppointmentId,
    "doctorId": doctorId,
    "doctorName": doctorName,
  },

  "theme": {
    "color": "#10BEC4",
  },


    // ------------------------------------------------------

    // UPI-FIRST CHECKOUT CONFIGURATION

    //

    // Razorpay controls actual available methods.

    // Backend still verifies that the successful payment

    // method is UPI.

    // ------------------------------------------------------



    "config": {

     "display": {

      "blocks": {

       "upi": {

        "name": "Pay using UPI",

        "instruments": [

         {

          "method": "upi",

         },

        ],

       },

      },

      "sequence": [

       "block.upi",

      ],

      "preferences": {

       "show_default_blocks":

         false,

      },

     },

    },

   };



   debugPrint(

    "========================================",

   );



   debugPrint(

    "OPENING RAZORPAY",

   );



   debugPrint(

    "APPOINTMENT ID = "

    "$_pendingAppointmentId",

   );



   debugPrint(

    "RAZORPAY ORDER ID = "

    "$_pendingRazorpayOrderId",

   );



   debugPrint(

    "AMOUNT = $amountInPaise",

   );



   debugPrint(

    "CURRENCY = $currency",

   );



   debugPrint(

    "========================================",

   );



   try {
        _razorpay.open(options);
      } catch (openError) {
        debugPrint("RAZORPAY OPEN ERROR: $openError");

        if (_pendingAppointmentId.isNotEmpty &&
            _pendingRazorpayOrderId.isNotEmpty) {
          try {
            await ApiService.cancelDoctorPayment(
              appointmentId: _pendingAppointmentId,
              razorpayOrderId: _pendingRazorpayOrderId,
              patientPhone: patientPhone,
            );
          } catch (cancelError) {
            debugPrint("CANCEL AFTER OPEN ERROR: $cancelError");
          }
        }

        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        rethrow;
      }
    } catch (e) {

   debugPrint(

    "========================================",

   );



   debugPrint(

    "CREATE DOCTOR PAYMENT ERROR",

   );



   debugPrint("$e");



   debugPrint(

    "========================================",

   );



   if (!mounted) return;



   setState(() {

    loading = false;

   });



   ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(

     backgroundColor: Colors.red,

     content: Text(

      "Unable to start payment: $e",

     ),

    ),

   );

  }

 }



 // ============================================================

 // RAZORPAY SUCCESS

 // ============================================================



 Future<void> _handlePaymentSuccess(

  PaymentSuccessResponse response,

 ) async {

  final String razorpayPaymentId =

    response.paymentId?.toString() ?? "";



  final String razorpayOrderId =

    response.orderId?.toString() ?? "";



  final String razorpaySignature =

    response.signature?.toString() ?? "";



  debugPrint(

   "========================================",

  );



  debugPrint(

   "RAZORPAY SUCCESS CALLBACK",

  );



  debugPrint(

   "PAYMENT ID = $razorpayPaymentId",

  );



  debugPrint(

   "ORDER ID = $razorpayOrderId",

  );



  debugPrint(

   "SIGNATURE RECEIVED = "

   "${razorpaySignature.isNotEmpty}",

  );



  debugPrint(

   "APPOINTMENT ID = "

   "$_pendingAppointmentId",

  );



  debugPrint(

   "========================================",

  );



  // ==========================================================

  // NEVER TRUST SUCCESS CALLBACK ALONE

  // ==========================================================



  if (razorpayPaymentId.isEmpty ||

    razorpayOrderId.isEmpty ||

    razorpaySignature.isEmpty) {

   if (!mounted) return;



   ScaffoldMessenger.of(context)

     .showSnackBar(

    const SnackBar(

     backgroundColor: Colors.red,

     content: Text(

      "Payment information is incomplete.",

     ),

    ),

   );



   return;

  }



  if (_pendingAppointmentId.isEmpty) {

   if (!mounted) return;



   ScaffoldMessenger.of(context)

     .showSnackBar(

    const SnackBar(

     backgroundColor: Colors.red,

     content: Text(

      "Appointment information is missing.",

     ),

    ),

   );



   return;

  }



  // ==========================================================

  // VERIFYING

  // ==========================================================



  if (mounted) {

   setState(() {

    loading = true;

   });

  }



  try {

   debugPrint(

    "========================================",

   );



   debugPrint(

    "VERIFYING PAYMENT ON BACKEND",

   );



   debugPrint(

    "========================================",

   );



   
final prefs = await SharedPreferences.getInstance();

final String patientPhone =
    prefs.getString("patientPhone") ?? "";

if (patientPhone.trim().isEmpty) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "Patient phone number is missing.",
      ),
    ),
  );

  return;
}
// ========================================================
// STEP 3
// BACKEND VERIFICATION
// ========================================================

final Map<String, dynamic> result =
    await ApiService.verifyDoctorPayment(
  appointmentId: _pendingAppointmentId,
  razorpayOrderId: razorpayOrderId,
  razorpayPaymentId: razorpayPaymentId,
  razorpaySignature: razorpaySignature,
  patientPhone: patientPhone,
);

debugPrint(
  "========================================",
);

debugPrint(
  "VERIFY PAYMENT RESPONSE",
);

debugPrint(
  "$result",
);

debugPrint(
  "========================================",
);
   // ========================================================

   // CHECK SERVER RESULT

   // ========================================================



   final bool verified =

     result["success"] == true ||

       result["verified"] == true ||

       result["paymentVerified"] ==

         true;



   if (!verified) {

    throw Exception(

     result["message"] ??

       "Payment verification failed.",

    );

   }



   // ========================================================

   // PAYMENT VERIFIED

   // ========================================================



   if (!mounted) return;



   setState(() {

    loading = false;

   });



   // ========================================================

   // SUCCESS MESSAGE

   // ========================================================



   ScaffoldMessenger.of(context)

     .showSnackBar(

    const SnackBar(

     backgroundColor: Colors.green,

     content: Text(

      "Appointment booked successfully. "

      "Payment verified.",

     ),

    ),

   );



   // ========================================================

   // SUCCESS DIALOG

   // ========================================================



   await showDialog(

    context: context,

    barrierDismissible: false,

    builder: (_) {

     return AlertDialog(

      shape: RoundedRectangleBorder(

       borderRadius:

         BorderRadius.circular(16),

      ),

      title: Row(

       children: [

        const Icon(

         Icons.check_circle,

         color: Colors.green,

         size: 30,

        ),

        const SizedBox(width: 10),

        Expanded(

         child: Text(

          "appointmentBooked"

            .tr(),

         ),

        ),

       ],

      ),

      content: Text(

       "appointmentBookedMessage"

         .tr(

        args: [

         widget.doctor["name"]

             ?.toString() ??

           "",

        ],

       ),

      ),

      actions: [

       TextButton(

        onPressed: () {

         Navigator.pop(context);

        },

        child: Text(

         "ok".tr(),

        ),

       ),

      ],

     );

    },

   );



   // ========================================================

   // RETURN TO PREVIOUS PAGE

   // ========================================================



   if (mounted) {

    Navigator.pop(

     context,

     true,

    );

   }

  } catch (e) {

   debugPrint(

    "========================================",

   );



   debugPrint(

    "PAYMENT VERIFICATION ERROR",

   );



   debugPrint("$e");



   debugPrint(

    "========================================",

   );



   if (!mounted) return;



   setState(() {

    loading = false;

   });



   ScaffoldMessenger.of(context)

     .showSnackBar(

    SnackBar(

     backgroundColor: Colors.red,

     content: Text(

      "Payment verification failed: $e",

     ),

    ),

   );

  }

 }



 // ============================================================

 // RAZORPAY PAYMENT ERROR

 // ============================================================



Future<void> _handlePaymentError(
  PaymentFailureResponse response,
) async {
  final prefs = await SharedPreferences.getInstance();

  final String patientPhone =
      prefs.getString("patientPhone") ?? "";

  debugPrint(
    "========================================",
  );

  debugPrint(
    "RAZORPAY PAYMENT FAILED",
  );

  // rest of your existing code...


  debugPrint(

   "CODE = ${response.code}",

  );



  debugPrint(

   "MESSAGE = ${response.message}",

  );



  debugPrint(

   "========================================",

  );



  // ==========================================================

  // CANCEL PENDING APPOINTMENT

  // ==========================================================



  if (_pendingAppointmentId.isNotEmpty &&

    _pendingRazorpayOrderId.isNotEmpty) {

   try {

    await ApiService

      .cancelDoctorPayment(

     appointmentId:

       _pendingAppointmentId,

     razorpayOrderId:

       _pendingRazorpayOrderId,
          patientPhone: patientPhone,

    );



    debugPrint(

     "Pending appointment cancelled.",

    );

   } catch (e) {

    debugPrint(

     "Cancel pending appointment error: "

     "$e",

    );

   }

  }



  if (!mounted) return;



  setState(() {

   loading = false;

  });



  ScaffoldMessenger.of(context)

    .showSnackBar(

   SnackBar(

    backgroundColor: Colors.red,

    content: Text(

     response.message?.isNotEmpty ==

         true

       ? "Payment failed: "

         "${response.message}"

       : "Payment failed.",

    ),

   ),

  );

 }



 // ============================================================

 // EXTERNAL WALLET

 // ============================================================



 Future<void> _handleExternalWallet(

  ExternalWalletResponse response,

 ) async {

  debugPrint(

   "EXTERNAL WALLET = "

   "${response.walletName}",

  );



  if (!mounted) return;



  ScaffoldMessenger.of(context)

    .showSnackBar(

   const SnackBar(

    backgroundColor: Colors.orange,

    content: Text(

     "Please use UPI for doctor appointment payment.",

    ),

   ),

  );

 }



 // ============================================================

 // BUILD

 // ============================================================



 @override

 Widget build(BuildContext context) {

  final String doctorName =

    widget.doctor["name"]?.toString() ??

      "";



  final String specialization =

    widget.doctor["specialization"]

        ?.toString() ??

      "";



  final String fees =

    widget.doctor["fees"]?.toString() ??

      "0";



  return Scaffold(

   resizeToAvoidBottomInset: true,



   // ========================================================

   // APP BAR

   // ========================================================



   appBar: AppBar(

    title: Text(

     "bookAppointment".tr(),

    ),

   ),



   // ========================================================

   // BODY

   // ========================================================



   body: SingleChildScrollView(

    padding:

      const EdgeInsets.all(20),



    child: Column(

     children: [

      // ==================================================

      // DOCTOR INFORMATION

      // ==================================================



      Container(

       width: double.infinity,

       padding:

         const EdgeInsets.all(16),



       decoration:

         BoxDecoration(

        borderRadius:

          BorderRadius.circular(14),

        border: Border.all(

         color:

           Colors.grey.shade300,

        ),

       ),



       child: Row(

        children: [

         CircleAvatar(

          radius: 28,

          backgroundColor:

            const Color(

           0xff10BEC4,

          ).withOpacity(0.12),



          child: const Icon(

           Icons.person,

           color:

             Color(0xff10BEC4),

           size: 30,

          ),

         ),



         const SizedBox(width: 14),



         Expanded(

          child: Column(

           crossAxisAlignment:

             CrossAxisAlignment

               .start,



           children: [

            Text(

             "Dr. $doctorName",

             style:

               const TextStyle(

              fontSize: 17,

              fontWeight:

                FontWeight.bold,

             ),

            ),



            const SizedBox(

             height: 4,

            ),



            Text(

             specialization,

             style: TextStyle(

              color: Colors

                .grey

                .shade600,

             ),

            ),



            const SizedBox(

             height: 4,

            ),



            Text(

             "₹$fees",

             style:

               const TextStyle(

              color:

                Color(

               0xff10BEC4,

              ),

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

        style:

          const TextStyle(

         fontSize: 16,

         fontWeight:

           FontWeight.bold,

        ),

       ),

      ),



      const SizedBox(height: 10),



      Container(

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

         // ------------------------------------------------

         // VIDEO CONSULTATION

         // ------------------------------------------------



         RadioListTile<String>(

          value:

            "Video Consultation",



          groupValue:

            consultationType,



          activeColor:

            const Color(

           0xff10BEC4,

          ),



          title: Text(

           "videoConsultation"

             .tr(),

          ),



          subtitle: Text(

           "consultDoctorVideoCall"

             .tr(),

          ),



          secondary:

            const Icon(

           Icons

             .video_camera_front,

          ),



          onChanged:

            (value) {

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



         // ------------------------------------------------

         // HOSPITAL VISIT

         // ------------------------------------------------



         RadioListTile<String>(

          value:

            "Hospital Visit",



          groupValue:

            consultationType,



          activeColor:

            const Color(

           0xff10BEC4,

          ),



          title: Text(

           "hospitalVisit".tr(),

          ),



          subtitle: Text(

           "visitDoctorHospital"

             .tr(),

          ),



          secondary:

            const Icon(

           Icons.local_hospital,

          ),



          onChanged:

            (value) {

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

        "selectAppointmentDate"

          .tr(),



        style:

          const TextStyle(

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

          "appointmentDate"

            .tr(),



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



         style:

           const TextStyle(

          fontSize: 16,

          fontWeight:

            FontWeight.bold,

         ),

        ),

       ),



       const SizedBox(height: 10),



       // ------------------------------------------------

       // LOADING SLOTS

       // ------------------------------------------------



       if (loadingSlots)

        Container(

         width:

           double.infinity,



         padding:

           const EdgeInsets.all(

          25,

         ),



         decoration:

           BoxDecoration(

          border: Border.all(

           color: Colors

             .grey

             .shade300,

          ),

          borderRadius:

            BorderRadius.circular(

           12,

          ),

         ),



         child: Column(

          children: [

           const CircularProgressIndicator(

            color:

              Color(

             0xff10BEC4,

            ),

           ),



           const SizedBox(

            height: 12,

           ),



           Text(

            "loadingAvailableSlots"

              .tr(),

           ),

          ],

         ),

        )



       // ------------------------------------------------

       // NO SLOTS

       // ------------------------------------------------



       else if (availableSlots

         .isEmpty)

        Container(

         width:

           double.infinity,



         padding:

           const EdgeInsets.all(

          18,

         ),



         decoration:

           BoxDecoration(

          color:

            Colors.red.shade50,



          borderRadius:

            BorderRadius.circular(

           12,

          ),



          border:

            Border.all(

           color:

             Colors.red.shade200,

          ),

         ),



         child: Row(

          children: [

           const Icon(

            Icons.info_outline,

            color:

              Colors.red,

           ),



           const SizedBox(

            width: 10,

           ),



           Expanded(

            child: Text(

             "noAvailableSlots"

               .tr(),



             style:

               const TextStyle(

              color:

                Colors.red,

             ),

            ),

           ),

          ],

         ),

        )



       // ------------------------------------------------

       // AVAILABLE SLOTS

       // ------------------------------------------------



       else

        Wrap(

         spacing: 10,

         runSpacing: 10,



         children:

           availableSlots

             .map(

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

                .circular(

             10,

            ),



            onTap: () {

             selectSlot(

              time,

             );

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

                  0xff10BEC4,

                 )

                : Colors.white,



              borderRadius:

                BorderRadius

                  .circular(

               10,

              ),



              border:

                Border.all(

               color: selected

                 ? const Color(

                   0xff10BEC4,

                  )

                 : Colors

                   .grey

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

                    0xff10BEC4,

                   ),

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



       // =================================================

       // SELECTED TIME

       // =================================================



       TextField(

        controller:

          timeController,



        readOnly: true,



        decoration:

          InputDecoration(

         labelText:

           "selectedAppointmentTime"

             .tr(),



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

        "uploadReportsOptional"

          .tr(),



        style:

          const TextStyle(

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

        width:

          double.infinity,



        padding:

          const EdgeInsets.all(

         16,

        ),



        decoration:

          BoxDecoration(

         border: Border.all(

          color: Colors.grey,

         ),



         borderRadius:

           BorderRadius.circular(

          10,

         ),

        ),



        child: Row(

         children: [

          const Icon(

           Icons.upload_file,

          ),



          const SizedBox(

           width: 10,

          ),



          Text(

           "uploadReport".tr(),

          ),

         ],

        ),

       ),

      ),



      const SizedBox(height: 15),



      // ==================================================

      // SELECTED REPORTS

      // ==================================================



      if (reports.isNotEmpty)

       Column(

        children:

          reports

            .asMap()

            .entries

            .map(

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

             color:

               Colors.red,

            ),



            onPressed: () {

             setState(() {

              reports

                .removeAt(

               entry.key,

              );

             });

            },

           ),

          );

         },

        ).toList(),

       ),



      const SizedBox(height: 20),



      // ==================================================

      // PAYMENT INFORMATION

      // ==================================================



      Container(

       width:

         double.infinity,



       padding:

         const EdgeInsets.all(

        16,

       ),



       decoration:

         BoxDecoration(

        color:

          const Color(

         0xff10BEC4,

        ).withOpacity(0.08),



        borderRadius:

          BorderRadius.circular(

         12,

        ),



        border:

          Border.all(

         color:

           const Color(

          0xff10BEC4,

         ).withOpacity(0.25),

        ),

       ),



       child: Row(

        children: [

         const Icon(

          Icons

            .account_balance_wallet,

          color:

            Color(0xff10BEC4),

         ),



         const SizedBox(

          width: 12,

         ),



         Expanded(

          child: Column(

           crossAxisAlignment:

             CrossAxisAlignment

               .start,



           children: [

            const Text(

             "Payment",

             style:

               TextStyle(

              fontWeight:

                FontWeight.bold,

             ),

            ),



            const SizedBox(

             height: 4,

            ),



            const Text(

             "Secure payment through Razorpay",

             style:

               TextStyle(

              fontSize: 13,

             ),

            ),



            const SizedBox(

             height: 4,

            ),



            Text(

             "UPI • ₹$fees",

             style:

               const TextStyle(

              color:

                Color(

               0xff10BEC4,

              ),

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

      // CONFIRM BOOKING / PAY NOW

      // ==================================================



      SizedBox(

       width:

         double.infinity,



       height: 55,



       child:

         ElevatedButton(

        onPressed:

          loading

            ? null

            : bookAppointment,



        style:

          ElevatedButton.styleFrom(

         backgroundColor:

           const Color(

          0xff10BEC4,

         ),



         foregroundColor:

           Colors.white,



         shape:

           RoundedRectangleBorder(

          borderRadius:

            BorderRadius.circular(

           12,

          ),

         ),

        ),



        child: loading

          ? const SizedBox(

            height: 24,

            width: 24,



            child:

              CircularProgressIndicator(

             color:

               Colors.white,

             strokeWidth:

               2,

            ),

           )



          : Text(

            "confirmBooking"

              .tr(),



            style:

              const TextStyle(

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



 // ============================================================

 // DISPOSE

 // ============================================================



 @override

 void dispose() {

  _razorpay.clear();



  dateController.dispose();

  timeController.dispose();



  super.dispose();

 }

}