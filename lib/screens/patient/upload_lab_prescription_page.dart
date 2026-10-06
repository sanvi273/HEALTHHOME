import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

import 'lab_order_tracking_page.dart';

class UploadLabPrescriptionPage extends StatefulWidget {
  const UploadLabPrescriptionPage({super.key});

  @override
  State<UploadLabPrescriptionPage> createState() =>
      _UploadLabPrescriptionPageState();
}

class _UploadLabPrescriptionPageState
    extends State<UploadLabPrescriptionPage> {
  // ============================================================
  // CONFIGURATION
  // ============================================================

 

  static const Color primary = Color(0xff00C2CB);
  static const Color background = Color(0xffF7F8FA);

  // ============================================================
  // STATE
  // ============================================================

  bool isSubmitting = false;
  bool isLoading = true;

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  String? selectedLab;
  String? selectedLabId;

  String patientName = "";
  String patientPhone = "";

  String collectionMode = "homeCollection".tr();

  List<dynamic> labs = [];

  File? prescriptionImage;

  // ============================================================
  // CLOUDINARY
  // ============================================================

  final CloudinaryPublic cloudinary = CloudinaryPublic(
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
      final prefs = await SharedPreferences.getInstance();

      patientName =
          prefs.getString("patientName") ??
          prefs.getString("userName") ??
          "patient".tr();

      patientPhone =
          prefs.getString("patientPhone") ??
          prefs.getString("userPhone") ??
          "";

      await loadLabs();
    } catch (e) {
      debugPrint("INITIALIZE ERROR = $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD LABS
  // ============================================================

  Future<void> loadLabs() async {
    try {
      final data = await ApiService.getLabs();

      debugPrint("================================");
      debugPrint("LABS DATA = $data");
      debugPrint("================================");

      labs = data;

      if (labs.isNotEmpty) {
        selectedLabId =
            labs.first["_id"]?.toString();

        selectedLab =
            labs.first["name"]?.toString();
      }
    } catch (e) {
      debugPrint("LOAD LABS ERROR = $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // SELECTED LAB DATA
  // ============================================================

  Map<String, dynamic>? get selectedLabData {
    if (selectedLabId == null) {
      return null;
    }

    for (final lab in labs) {
      if (lab["_id"]?.toString() == selectedLabId) {
        return Map<String, dynamic>.from(lab);
      }
    }

    return null;
  }

  String get selectedLabAddress {
    final lab = selectedLabData;

    if (lab == null) {
      return "";
    }

    return lab["address"]?.toString() ??
        lab["location"]?.toString() ??
        "";
  }

  // ============================================================
  // PICK PRESCRIPTION
  // ============================================================

  Future<void> pickPrescription() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        prescriptionImage = File(image.path);
      });
    } catch (e) {
      debugPrint("PICK PRESCRIPTION ERROR = $e");

      if (!mounted) return;

      _showMessage(
        "unableToSelectPrescription".tr(),
        isError: true,
      );
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitBooking() async {
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

  if (selectedLabId == null ||
      selectedLabId!.trim().isEmpty) {
    _showMessage(
      "pleaseSelectLaboratory".tr(),
      isError: true,
    );
    return;
  }

  if (prescriptionImage == null) {
    _showMessage(
      "Please upload a prescription.",
      isError: true,
    );
    return;
  }

  if (collectionMode == "homeCollection".tr() &&
      addressController.text.trim().isEmpty) {
    _showMessage(
      "Please enter your home collection address.",
      isError: true,
    );
    return;
  }

  setState(() {
    isSubmitting = true;
  });

  try {
    // ============================================
    // STEP 1: UPLOAD PRESCRIPTION
    // ============================================

    final uploadResponse =
        await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        prescriptionImage!.path,
        resourceType:
            CloudinaryResourceType.Image,
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
    // STEP 2: GET COLLECTION ADDRESS
    // ============================================

    final String orderAddress =
        collectionMode == "homeCollection".tr()
            ? addressController.text.trim()
            : selectedLabAddress;

    // ============================================
    // STEP 3: CREATE LAB PRESCRIPTION ORDER
    // ============================================

    final result =
        await ApiService.placeLabOrder(
      patientId: patientPhone,
      patientName: patientName,
      patientPhone: patientPhone,
      labId: selectedLabId!,
      labName: selectedLab ?? "",
      address: orderAddress,
      notes: notesController.text.trim(),
      prescriptionImage: imageUrl,
      tests: const [],
      collectionMode: collectionMode,
      bookingType: "PRESCRIPTION",
    );

    debugPrint(
      "LAB PRESCRIPTION ORDER RESPONSE = $result",
    );

   final bool success =
    result["success"] == true ||
    result["order"] != null;

if (!success) {
  throw Exception(
    result["message"] ??
        "Lab booking could not be created.",
  );
}

// Get created Lab Order ID
final String createdOrderId =
    result["order"]?["_id"]?.toString() ??
    result["order"]?["id"]?.toString() ??
    result["_id"]?.toString() ??
    result["orderId"]?.toString() ??
    "";

if (createdOrderId.isEmpty) {
  throw Exception(
    "Lab Order ID was not returned by server.",
  );
}

debugPrint(
  "CREATED LAB PRESCRIPTION ORDER ID = $createdOrderId",
);

    // ============================================
    // STEP 4: SUCCESS
    // Payment will happen at sample collection.
    // ============================================

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    await _showSuccessDialog(createdOrderId);

  } catch (e) {
    debugPrint(
      "LAB PRESCRIPTION ORDER ERROR = $e",
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    _showMessage(
      "Lab booking failed: $e",
      isError: true,
    );
  }
}


  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

Future<void> _showSuccessDialog(String orderId) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 30,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "bookingSuccessful".tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your prescription has been submitted successfully.",
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You can track your lab order from here.",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Order ID: $orderId",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LabOrderTrackingPage(
                      orderId: orderId,
                      labName: selectedLab ?? "laboratory".tr(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                "Track Lab Order",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00C2CB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff00C2CB),
                side: const BorderSide(
                  color: Color(0xff00C2CB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("done".tr()),
            ),
          ),
        ],
      );
    },
  );
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        title: Text(
          "Upload Lab Prescription",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // SELECT LAB
            // ==================================================

            _sectionCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    "selectLaboratory".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            color: primary,
                          ),
                        )
                      : DropdownButtonFormField<
                          String>(
                          initialValue:
                              selectedLabId,

                          decoration:
                              InputDecoration(
                            filled: true,
                            fillColor:
                                Colors.grey.shade100,

                            prefixIcon:
                                const Icon(
                              Icons
                                  .local_hospital,
                              color: primary,
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),

                              borderSide:
                                  BorderSide.none,
                            ),
                          ),

                          items:
                              labs.map<
                                  DropdownMenuItem<
                                      String>>(
                            (lab) {
                              final id =
                                  lab["_id"]
                                          ?.toString() ??
                                      "";

                              final name =
                                  lab["name"]
                                          ?.toString() ??
                                      "laboratory".tr();

                              return DropdownMenuItem<
                                  String>(
                                value: id,
                                child:
                                    Text(name),
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

                                      final lab =
                                          labs.firstWhere(
                                        (item) =>
                                            item["_id"]
                                                ?.toString() ==
                                            value,
                                      );

                                      setState(() {
                                        selectedLabId =
                                            value;

                                        selectedLab =
                                            lab["name"]
                                                ?.toString();
                                      });
                                    },
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRESCRIPTION
            // ==================================================

            _sectionCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    "uploadPrescription".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap:
                        isSubmitting
                            ? null
                            : pickPrescription,

                    child: Container(
                      width:
                          double.infinity,

                      height: 180,

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
                          color: primary,
                          width: 1.5,
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
                                      size: 55,
                                      color:
                                          primary,
                                    ),

                                    SizedBox(
                                      height: 12,
                                    ),

                                    Text(
                                      "tapToUploadPrescription".tr(),
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            16,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 6,
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
                                      BorderRadius.circular(
                                    18,
                                  ),

                                  child:
                                      Image.file(
                                    prescriptionImage!,
                                    width:
                                        double.infinity,
                                    height:
                                        180,
                                    fit:
                                        BoxFit.cover,
                                  ),
                                ),
                    ),
                  ),

                  if (prescriptionImage !=
                      null) ...[
                    const SizedBox(height: 10),

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

            const SizedBox(height: 25),

            // ==================================================
            // COLLECTION MODE
            // ==================================================

            Text(
              "sampleCollection".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child:
                      _collectionCard(
                    title:
                        "homeCollection".tr(),
                    subtitle:
                        "collectorVisitsHome".tr(),
                    icon:
                        Icons.home_outlined,
                    value:
                        "homeCollection".tr(),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child:
                      _collectionCard(
                    title:
                        "visitLaboratory".tr(),
                    subtitle:
                        "visitTheLaboratory".tr(),
                    icon:
                        Icons
                            .local_hospital_outlined,
                    value:
                        "visitLaboratory".tr(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // HOME ADDRESS
            // ==================================================

            if (collectionMode ==
                "homeCollection".tr()) ...[
              Text(
                "collectionAddress".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    addressController,

                maxLines: 3,

                enabled:
                    !isSubmitting,

                decoration:
                    InputDecoration(
                  hintText:
                      "enterCompleteHomeAddress".tr(),

                  prefixIcon:
                      const Icon(
                    Icons.location_on,
                  ),

                  filled: true,

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

              const SizedBox(height: 12),

              _infoBox(
                icon:
                    Icons.info_outline,
                text:
                    "A sample collector will visit your home.",
              ),
            ],

            // ==================================================
            // VISIT LAB
            // ==================================================

            if (collectionMode ==
                "visitLaboratory".tr()) ...[
              Text(
                "laboratoryDetails".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .local_hospital,
                          color: primary,
                          size: 32,
                        ),

                        const SizedBox(
                            width: 12),

                        Expanded(
                          child: Text(
                            selectedLab ??
                                "laboratory".tr(),
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 15),

                    const Divider(),

                    const SizedBox(
                        height: 12),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Icon(
                          Icons.location_on,
                          color:
                              Colors.redAccent,
                        ),

                        const SizedBox(
                            width: 10),

                        Expanded(
                          child: Text(
                            selectedLabAddress
                                    .isEmpty
                                ? "laboratoryAddressUnavailable".tr()
                                : selectedLabAddress,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            // ==================================================
            // NOTES
            // ==================================================

            Text(
              "notes".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
                  notesController,

              maxLines: 3,

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

                filled: true,

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

            const SizedBox(height: 25),

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
    crossAxisAlignment:
        CrossAxisAlignment.start,
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
              "payAtSampleCollection".tr(),
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
        "The final lab test amount will be determined after the laboratory reviews your prescription. No payment is required now. You will pay the final amount when your sample is collected.",
        style: TextStyle(
          fontSize: 13,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 25),

            // ==================================================
            // BOOK BUTTON
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height: 56,

              child:
                  ElevatedButton.icon(
                onPressed:
                    isSubmitting
                        ? null
                        : _submitBooking,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primary,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.grey.shade400,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                icon:
                    isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
    Icons.local_shipping_outlined,
  ),

                label:
                    Text(
                  isSubmitting
    ? "Booking..."
    : "bookLabTestPayAtCollection".tr(),

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
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
          const EdgeInsets.all(20),

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

      child: child,
    );
  }

  // ============================================================
  // COLLECTION CARD
  // ============================================================

  Widget _collectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected =
        collectionMode == value;

    return GestureDetector(
      onTap: isSubmitting
          ? null
          : () {
              setState(() {
                collectionMode =
                    value;
              });
            },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        padding:
            const EdgeInsets.all(
          15,
        ),

        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xffE8F8F5,
                )
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          border:
              Border.all(
            color: selected
                ? primary
                : Colors.grey.shade300,

            width:
                selected ? 2 : 1,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                Icon(
                  icon,

                  size: 32,

                  color: selected
                      ? primary
                      : Colors.grey,
                ),

                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: primary,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              title,

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,

                color: selected
                    ? primary
                    : Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,

              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  Widget _infoBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xffE8F8F5,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color:
                const Color(
              0xff14B8A6,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }
}