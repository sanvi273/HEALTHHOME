import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../payment/payment_page.dart';

class LabCartPage extends StatefulWidget {
  final List<String> selectedTests;

  LabCartPage({
    super.key,
    required this.selectedTests,
  });

  @override
  State<LabCartPage> createState() => _LabCartPageState();
}

class _LabCartPageState extends State<LabCartPage> {
  static Color primaryColor = Color(0xff00C2CB);

  bool isLoading = true;
  bool isPlacingOrder = false;

  String patientName = "";
  String patientPhone = "";

  List<dynamic> labs = [];

  String? selectedLabId;
  String? selectedLabName;

  String collectionMode = "homeCollection".tr();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PATIENT + LABS
  // ============================================================

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      patientName =
          prefs.getString("patientName") ??
          prefs.getString("name") ??
          "";

      patientPhone =
          prefs.getString("patientPhone") ??
          prefs.getString("userPhone") ??
          prefs.getString("phone") ??
          "";

      if (patientPhone.trim().isEmpty) {
        throw Exception("Patient phone number not found.");
      }

      final result = await ApiService.getLabs();

      if (!mounted) return;

      setState(() {
        labs = List<dynamic>.from(result);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("LAB CART LOAD ERROR = $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to load laboratories: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // PLACE LAB ORDER
  // ============================================================

  Future<void> placeLabOrder() async {
    if (widget.selectedTests.isEmpty) {
      showMessage(
        "noLabTestsSelected".tr(),
        Colors.orange,
      );
      return;
    }

    if (selectedLabId == null ||
        selectedLabId!.trim().isEmpty) {
      showMessage(
        "pleaseSelectLaboratory".tr(),
        Colors.orange,
      );
      return;
    }

    if (collectionMode == "homeCollection".tr() &&
        addressController.text.trim().isEmpty) {
      showMessage(
        "pleaseEnterHomeCollectionAddress".tr(),
        Colors.orange,
      );
      return;
    }

    if (patientPhone.trim().isEmpty) {
      showMessage(
        "patientInformationNotFound".tr(),
        Colors.red,
      );
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      final response = await ApiService.placeLabOrder(
        patientId: patientPhone,
        patientName: patientName,
        patientPhone: patientPhone,
        labId: selectedLabId!,
        labName: selectedLabName ?? "laboratory".tr(),
        address: collectionMode == "homeCollection".tr()
            ? addressController.text.trim()
            : "",
        notes: notesController.text.trim(),
        prescriptionImage: "",
        tests: widget.selectedTests,
        collectionMode: collectionMode,
        bookingType: "test".tr(),
      );

      debugPrint("LAB CART ORDER RESPONSE = $response");

      if (response["success"] != true) {
        throw Exception(
          response["message"]?.toString() ??
              "unableToPlaceLabOrder".tr(),
        );
      }

      dynamic orderData = response;

String orderId = "";

// Case 1: response["data"] contains the order
if (response["data"] is Map) {
  orderData = response["data"];
}

// Case 2: response["order"] contains the order
if (response["order"] is Map) {
  orderData = response["order"];
}

// Extract ID from whichever order object we found
if (orderData is Map) {
  orderId =
      orderData["_id"]?.toString().trim() ??
      orderData["id"]?.toString().trim() ??
      orderData["orderId"]?.toString().trim() ??
      "";
}

// Final fallback: root response itself
if (orderId.isEmpty) {
  orderId =
      response["_id"]?.toString().trim() ??
      response["id"]?.toString().trim() ??
      response["orderId"]?.toString().trim() ??
      "";
}

if (orderId.isEmpty) {
  throw Exception(
    "labOrderCreatedNoId".tr(),
  );
}

debugPrint("✅ LAB ORDER ID = $orderId");
      if (!mounted) return;

      setState(() {
        isPlacingOrder = false;
      });

      // ========================================================
      // PAYMENT
      // ========================================================

      final paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            // PaymentPage gets the real amount from the HealthHome
            // backend using serviceType + serviceId.
            amount: 0.0,
            userId: patientPhone,
            userName: patientName,
            userPhone: patientPhone,
            serviceType: "Lab",
            serviceId: orderId,
          ),
        ),
      );

      if (paymentResult == true) {
        if (!mounted) return;

        await showSuccessDialog(orderId);
      }
    } catch (e) {
      debugPrint("PLACE LAB ORDER ERROR = $e");

      if (!mounted) return;

      setState(() {
        isPlacingOrder = false;
      });

      showMessage(
        "Unable to place lab order: $e",
        Colors.red,
      );
    }
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> showSuccessDialog(String orderId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 65,
                ),
              ),

              SizedBox(height: 18),

              Text(
                "labOrderPlaced".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                "labOrderSuccess".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              SizedBox(height: 12),

              Text(
                "Order ID: $orderId",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    "done".tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        title: Text(
          "labCart".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      buildSelectedTestsCard(),

                      SizedBox(height: 18),

                      buildLaboratoryCard(),

                      SizedBox(height: 18),

                      buildCollectionCard(),

                      SizedBox(height: 18),

                      if (collectionMode == "homeCollection".tr())
                        buildAddressCard(),

                      if (collectionMode == "homeCollection".tr())
                        SizedBox(height: 18),

                      buildNotesCard(),

                      SizedBox(height: 100),
                    ],
                  ),
                ),

                buildBottomButton(),
              ],
            ),
    );
  }

  // ============================================================
  // SELECTED TESTS
  // ============================================================

  Widget buildSelectedTestsCard() {
    return buildCard(
      title: "selectedLabTests".tr(),
      icon: Icons.science_outlined,
      child: Column(
        children: [
          ...widget.selectedTests.map(
            (test) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.science,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        test,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 21,
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 4),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${widget.selectedTests.length} test${widget.selectedTests.length == 1 ? '' : 's'} selected",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABORATORY
  // ============================================================

  Widget buildLaboratoryCard() {
    return buildCard(
      title: "selectLaboratory".tr(),
      icon: Icons.local_hospital_outlined,
      child: labs.isEmpty
          ? Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "noLaboratoriesAvailable".tr(),
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            )
          : Column(
              children: labs.map(
                (lab) {
                  final labMap =
                      Map<String, dynamic>.from(lab);

                  final String labId =
                      labMap["_id"]?.toString() ??
                      labMap["id"]?.toString() ??
                      "";

                  final String labName =
                      labMap["labName"]?.toString() ??
                      labMap["name"]?.toString() ??
                      labMap["laboratoryName"]?.toString() ??
                      "laboratory".tr();

                  final bool selected =
                      selectedLabId == labId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLabId = labId;
                        selectedLabName = labName;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: 10,
                      ),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? primaryColor.withOpacity(.07)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: selected
                              ? primaryColor
                              : Colors.grey.shade200,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.biotech_outlined,
                              color: primaryColor,
                            ),
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              labName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? primaryColor
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  // ============================================================
  // COLLECTION MODE
  // ============================================================

  Widget buildCollectionCard() {
    return buildCard(
      title: "collectionMethod".tr(),
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          buildCollectionOption(
            title: "homeCollection".tr(),
            subtitle:
                "sampleCollectedFromAddress".tr(),
            icon: Icons.home_outlined,
          ),

          SizedBox(height: 10),

          buildCollectionOption(
            title: "visitLaboratory".tr(),
            subtitle:
                "visitLaboratoryForSample".tr(),
            icon: Icons.local_hospital_outlined,
          ),
        ],
      ),
    );
  }

  Widget buildCollectionOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = collectionMode == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          collectionMode = title;
        });
      },
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withOpacity(.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor.withOpacity(.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected
                    ? primaryColor
                    : Colors.grey,
              ),
            ),

            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? primaryColor
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget buildAddressCard() {
    return buildCard(
      title: "collectionAddress".tr(),
      icon: Icons.location_on_outlined,
      child: TextField(
        controller: addressController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              "enterSampleCollectionAddress".tr(),
          filled: true,
          fillColor: Color(0xffF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget buildNotesCard() {
    return buildCard(
      title: "additionalNotes".tr(),
      icon: Icons.notes_outlined,
      child: TextField(
        controller: notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "optionalNotes".tr(),
          filled: true,
          fillColor: Color(0xffF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryColor,
              ),

              SizedBox(width: 8),

              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed:
              isPlacingOrder ? null : placeLabOrder,
          icon: isPlacingOrder
              ? SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.payment),

          label: Text(
            isPlacingOrder
                ? "placingOrder".tr()
                : "placeLabOrder".tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}


