import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';


class UploadPrescriptionPage extends StatefulWidget {
  const UploadPrescriptionPage({super.key});

  @override
  State<UploadPrescriptionPage> createState() =>
      _UploadPrescriptionPageState();
}

class _UploadPrescriptionPageState
    extends State<UploadPrescriptionPage> {

  // ============================================================
  // CONFIG
  // ============================================================

  static const Color primary =
      Color(0xff00C2CB);

  

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController
      addressController =
      TextEditingController();

  final TextEditingController
      notesController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String? selectedPharmacy;
  String? selectedPharmacyId;

  List pharmacies = [];

  bool isLoading = true;
  bool isSubmitting = false;

  File? prescriptionImage;

  String patientName = "";
  String patientPhone = "";

  // ============================================================
  // CLOUDINARY
  // ============================================================

  final CloudinaryPublic cloudinary =
      CloudinaryPublic(
    'dvjvp5bu7',
    'healthhome_prescriptions',
    cache: false,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      patientName =
          prefs.getString(
                "patientName",
              ) ??
              prefs.getString(
                "userName",
              ) ??
              "patient".tr();

      patientPhone =
          prefs.getString(
                "patientPhone",
              ) ??
              prefs.getString(
                "userPhone",
              ) ??
              "";

      await loadPharmacies();

    } catch (e) {

      debugPrint(
        "INITIALIZE ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD PHARMACIES
  // ============================================================

  Future<void> loadPharmacies() async {
    try {

      final data =
          await ApiService.getPharmacies();

      debugPrint(
        "================================",
      );

      debugPrint(
        "PHARMACIES = $data",
      );

      debugPrint(
        "================================",
      );

      if (!mounted) return;

      setState(() {

        pharmacies = data;

        isLoading = false;

        if (data.isNotEmpty) {

          selectedPharmacy =
              data[0]["name"]
                  ?.toString();

          selectedPharmacyId =
              data[0]["_id"]
                  ?.toString();
        }
      });

    } catch (e) {

      debugPrint(
        "LOAD PHARMACIES ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        "unableToLoadPharmacies".tr(),
        isError: true,
      );
    }
  }

  // ============================================================
  // PICK PRESCRIPTION
  // ============================================================

  Future<void>
      pickPrescription() async {

    try {

      final picker =
          ImagePicker();

      final image =
          await picker.pickImage(
        source:
            ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {

        prescriptionImage =
            File(image.path);
      });

    } catch (e) {

      debugPrint(
        "PICK IMAGE ERROR = $e",
      );

      _showMessage(
        "unableToSelectPrescription".tr(),
        isError: true,
      );
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================
Future<void> submitOrder() async {
  if (isSubmitting) {
    return;
  }

  if (patientPhone.trim().isEmpty) {
    _showMessage(
      "patientInformationNotFound".tr(),
      isError: true,
    );
    return;
  }

  if (selectedPharmacyId == null ||
      selectedPharmacyId!.trim().isEmpty) {
    _showMessage(
      "pleaseSelectPharmacy".tr(),
      isError: true,
    );
    return;
  }

  if (prescriptionImage == null) {
    _showMessage(
      "pleaseUploadPrescription".tr(),
      isError: true,
    );
    return;
  }

  if (addressController.text.trim().isEmpty) {
    _showMessage(
      "pleaseEnterDeliveryAddress".tr(),
      isError: true,
    );
    return;
  }

  setState(() {
    isSubmitting = true;
  });

  try {
    // ============================================
    // STEP 1: Upload prescription to Cloudinary
    // ============================================

    final CloudinaryResponse uploadResponse =
        await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        prescriptionImage!.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    final String imageUrl =
        uploadResponse.secureUrl;

    if (imageUrl.isEmpty) {
      throw Exception(
        "prescriptionUploadFailed".tr(),
      );
    }

    debugPrint(
      "PRESCRIPTION URL = $imageUrl",
    );

    // ============================================
    // STEP 2: Create prescription order
    // ============================================

    final result =
        await ApiService.placePrescriptionOrder(
      patientName: patientName,
      patientPhone: patientPhone,
      pharmacyId: selectedPharmacyId!,
      pharmacyName: selectedPharmacy ?? "",
      address: addressController.text.trim(),
      notes: notesController.text.trim(),
      prescriptionImage: imageUrl,
    );

    debugPrint(
      "PRESCRIPTION ORDER RESPONSE = $result",
    );

    final bool success =
        result["success"] == true ||
        result["order"] != null;

    if (!success) {
      throw Exception(
        result["message"] ??
            "medicineOrderCouldNotBeCreated".tr(),
      );
    }

    // ============================================
    // STEP 3: Order successfully submitted
    // Payment will happen at delivery
    // ============================================

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    await showSuccessDialog();

  } catch (e) {
    debugPrint(
      "PRESCRIPTION ORDER ERROR = $e",
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    _showMessage(
      "Medicine order failed: $e",
      isError: true,
    );
  }
}

  // ============================================================
  // CLOUDINARY → RAZORPAY → ORDER
  // ============================================================



  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void>
      showSuccessDialog() async {

    await showDialog(
      context: context,
      barrierDismissible: false,

      builder:
          (dialogContext) {

        return AlertDialog(

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title:
              Row(children: [

              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "prescriptionSubmitted".tr(),
                ),
              ),
            ],
          ),

         content:
    Text(
  "prescriptionSentToPharmacy".tr(
    namedArgs: {"pharmacy": selectedPharmacy ?? ""},
  ),
),


          actions: [

            ElevatedButton(

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primary,
                foregroundColor:
                    Colors.white,
              ),

              onPressed: () {

                Navigator.pop(
                  dialogContext,
                );

                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  Text(
                "done".tr(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(

        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,

        content:
            Text(message),
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
          const Color(
        0xffF7F8FA,
      ),

      appBar:
          AppBar(

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation: 0,

        title:
            Text(
          "uploadPrescription".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          20,
        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [

            // ==================================================
            // SELECT PHARMACY
            // ==================================================

            _sectionCard(

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    "selectPharmacy".tr(),
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  isLoading

                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                primary,
                          ),
                        )

                      : DropdownButtonFormField<
                          String>(

                          initialValue:
                              selectedPharmacy,

                          decoration:
                              InputDecoration(

                            filled:
                                true,

                            fillColor:
                                Colors.grey
                                    .shade100,

                            prefixIcon:
                                const Icon(
                              Icons
                                  .local_pharmacy,
                              color:
                                  primary,
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),

                              borderSide:
                                  BorderSide
                                      .none,
                            ),
                          ),

                          items:
                              pharmacies.map<
                                  DropdownMenuItem<
                                      String>>(
                            (pharmacy) {

                              final name =
                                  pharmacy[
                                          "name"]
                                      ?.toString() ??
                                      "pharmacy".tr();

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    name,

                                child:
                                    Text(
                                  name,
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              isSubmitting
                                  ? null
                                  : (value) {

                                      if (value ==
                                          null) {
                                        return;
                                      }

                                      final pharmacy =
                                          pharmacies.firstWhere(
                                        (p) =>
                                            p[
                                                    "name"]
                                                ?.toString() ==
                                            value,
                                      );

                                      setState(
                                        () {

                                          selectedPharmacy =
                                              value;

                                          selectedPharmacyId =
                                              pharmacy[
                                                      "_id"]
                                                  ?.toString();
                                        },
                                      );
                                    },
                        ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // PRESCRIPTION
            // ==================================================

            _sectionCard(

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    "prescription".tr(),
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  GestureDetector(

                    onTap:
                        isSubmitting
                            ? null
                            : pickPrescription,

                    child:
                        Container(

                      width:
                          double.infinity,

                      height:
                          190,

                      decoration:
                          BoxDecoration(

                        color:
                            const Color(
                          0xffF5FBFB,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),

                        border:
                            Border.all(
                          color:
                              primary,
                          width:
                              1.5,
                        ),
                      ),

                      child:

                          prescriptionImage ==
                                  null

                              ? Column(

                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,

                                  children: [

                                    Icon(
                                      Icons
                                          .cloud_upload_outlined,
                                      size:
                                          55,
                                      color:
                                          primary,
                                    ),

                                    SizedBox(
                                      height:
                                          10,
                                    ),

                                    Text(
                                      "uploadPrescription".tr(),
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(
                                      height:
                                          5,
                                    ),

                                    Text(
                                      "jpgPng".tr(),
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.black54,
                                      ),
                                    ),
                                  ],
                                )

                              : ClipRRect(

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),

                                  child:
                                      Image.file(
                                    prescriptionImage!,
                                    width:
                                        double.infinity,
                                    height:
                                        190,
                                    fit:
                                        BoxFit.cover,
                                  ),
                                ),
                    ),
                  ),

                  if (prescriptionImage !=
                      null) ...[

                    const SizedBox(
                      height: 10,
                    ),

                    TextButton.icon(

                      onPressed:
                          isSubmitting
                              ? null
                              : pickPrescription,

                      icon:
                          const Icon(
                        Icons.refresh,
                      ),

                      label:
                          Text(
                        "changePrescription".tr(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // ADDRESS
            // ==================================================

            Text(
              "deliveryAddress".tr(),
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(

              controller:
                  addressController,

              maxLines:
                  3,

              enabled:
                  !isSubmitting,

              decoration:
                  InputDecoration(

                hintText:
                    "enterCompleteDeliveryAddress".tr(),

                prefixIcon:
                    const Icon(
                  Icons.location_on,
                ),

                filled:
                    true,

                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // NOTES
            // ==================================================

            Text(
              "notes".tr(),
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(

              controller:
                  notesController,

              maxLines:
                  3,

              enabled:
                  !isSubmitting,

              decoration:
                  InputDecoration(

                hintText:
                    "additionalInstructions".tr(),

                prefixIcon:
                    const Icon(
                  Icons.notes,
                ),

                filled:
                    true,

                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // PAYMENT SUMMARY
            // ==================================================

            Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: const Color(0xffEAFBF8),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: primary.withOpacity(0.25),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
          Icon(
            Icons.payments_outlined,
            color: primary,
          ),
          SizedBox(width: 10),
          Text(
            "payment".tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 15),

      Row(children: [
          Icon(
            Icons.local_shipping_outlined,
            color: Colors.green,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "paymentOnDelivery".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Text(
        "finalMedicineAmountAfterReview".tr(),
        style: TextStyle(
          fontSize: 13,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
    ],
  ),
),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // PLACE ORDER
            // ==================================================

            SizedBox(

              width:
                  double.infinity,

              height:
                  56,

              child:
                  ElevatedButton.icon(

                onPressed:
                    isSubmitting
                        ? null
                        : submitOrder,

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      primary,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.grey
                          .shade400,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                icon: isSubmitting
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
    : const Icon(
        Icons.local_shipping_outlined,
      ),

label: Text(
  isSubmitting
      ? "submitting".tr()
      : "placeOrderPayOnDelivery".tr(),

                  style:
                      const TextStyle(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required Widget child,
  }) {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        boxShadow: const [

          BoxShadow(
            color:
                Colors.black12,
            blurRadius:
                8,
            offset:
                Offset(0, 2),
          ),
        ],
      ),

      child:
          child,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {

    addressController.dispose();

    notesController.dispose();

    super.dispose();
  }
}