import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'lab_cart_page.dart';
import 'lab_orders_page.dart';
import 'my_cart_page.dart';

class MyPrescriptionPage extends StatefulWidget {
  const MyPrescriptionPage({super.key});

  @override
  State<MyPrescriptionPage> createState() =>
      _MyPrescriptionPageState();
}

class _MyPrescriptionPageState
    extends State<MyPrescriptionPage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xff14B8A6);
  static const Color backgroundColor = Color(0xffF5F7FA);

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;

  String patientId = "";

  List<dynamic> prescriptions = [];

  late TabController tabController;

  // Each prescription gets its OWN medicine selection.
  final Map<String, List<Map<String, dynamic>>>
      selectedMedicines = {};

  // Each prescription gets its OWN lab selection.
  final Map<String, List<String>> selectedLabTests = {};

  // Medicine and lab processing are tracked independently.
  //
  // Example:
  // - Patient orders medicines only -> lab tests remain available.
  // - Patient books lab tests only -> medicines remain available.
  // - Both branches are completed -> prescription moves to Past.
  final Set<String> completedMedicinePrescriptionIds = {};
  final Set<String> completedLabPrescriptionIds = {};

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      vsync: this,
    );

    loadPrescriptions();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PRESCRIPTIONS
  // ============================================================

  Future<void> loadPrescriptions() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      patientId =
          prefs.getString("patientPhone") ??
              prefs.getString("phone") ??
              prefs.getString("userPhone") ??
              "";

      if (patientId.isEmpty) {
        patientId =
            prefs.getString("userId") ?? "";
      }

      debugPrint(
        "========== PRESCRIPTION ==========",
      );

      debugPrint(
        "Patient ID = $patientId",
      );

      final result =
          await ApiService.getPatientPrescriptions(
        patientId,
      );

      debugPrint(
        "Prescription count = ${result.length}",
      );

      prescriptions = result;

      await loadPrescriptionCompletionState();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "Prescription loading error: $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOCAL PRESCRIPTION COMPLETION STATE
  // ============================================================

  Future<void> loadPrescriptionCompletionState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMedicine =
        prefs.getStringList("completedMedicinePrescriptionIds") ?? [];

    final savedLab =
        prefs.getStringList("completedLabPrescriptionIds") ?? [];

    completedMedicinePrescriptionIds
      ..clear()
      ..addAll(savedMedicine);

    completedLabPrescriptionIds
      ..clear()
      ..addAll(savedLab);
  }

  Future<void> markMedicinePrescriptionCompleted(
    String id,
  ) async {
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    completedMedicinePrescriptionIds.add(id);

    await prefs.setStringList(
      "completedMedicinePrescriptionIds",
      completedMedicinePrescriptionIds.toList(),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> markLabPrescriptionCompleted(
    String id,
  ) async {
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    completedLabPrescriptionIds.add(id);

    await prefs.setStringList(
      "completedLabPrescriptionIds",
      completedLabPrescriptionIds.toList(),
    );

    if (mounted) {
      setState(() {});
    }
  }

  bool isMedicineBranchCompleted(
    String id,
    List<Map<String, dynamic>> medicines,
  ) {
    if (medicines.isEmpty) {
      return true;
    }

    return completedMedicinePrescriptionIds.contains(id);
  }

  bool isLabBranchCompleted(
    String id,
    List<Map<String, dynamic>> labTests,
  ) {
    if (labTests.isEmpty) {
      return true;
    }

    return completedLabPrescriptionIds.contains(id);
  }

  bool isPrescriptionCompleted(
    Map<String, dynamic> prescription,
  ) {
    final id = prescriptionId(prescription);

    final medicines = getMedicines(prescription);
    final labTests = getLabTests(prescription);

    final medicineDone =
        isMedicineBranchCompleted(id, medicines);

    final labDone =
        isLabBranchCompleted(id, labTests);

    return medicineDone && labDone;
  }

  // ============================================================
  // PRESCRIPTION ID
  // ============================================================

  String prescriptionId(
    Map<String, dynamic> prescription,
  ) {
    return prescription["_id"]?.toString() ??
        prescription["id"]?.toString() ??
        "";
  }

  // ============================================================
  // ACTIVE / PAST
  // ============================================================

  List<dynamic> get activePrescriptions {
    return prescriptions.where((item) {
      final prescription =
          Map<String, dynamic>.from(item);

      return !isPrescriptionCompleted(prescription);
    }).toList();
  }

  List<dynamic> get pastPrescriptions {
    return prescriptions.where((item) {
      final prescription =
          Map<String, dynamic>.from(item);

      return isPrescriptionCompleted(prescription);
    }).toList();
  }

  // ============================================================
  // MEDICINES
  // ============================================================

  List<Map<String, dynamic>> getMedicines(
    Map<String, dynamic> prescription,
  ) {
    final raw =
        prescription["medicines"];

    if (raw is! List) {
      return [];
    }

    return raw.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return {
        "medicine": item.toString(),
      };
    }).toList();
  }

  // ============================================================
  // LAB TESTS
  // ============================================================

  List<Map<String, dynamic>> getLabTests(
    Map<String, dynamic> prescription,
  ) {
    final raw =
        prescription["labTests"];

    if (raw is! List) {
      return [];
    }

    return raw.map<Map<String, dynamic>>((item) {
      // New backend format:
      //
      // {
      //   testName: CBC,
      //   priority: Normal,
      //   note: ...
      // }

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      // Old backend format:
      //
      // "CBC"

      return {
        "testName": item.toString(),
        "priority": "Normal",
        "note": "",
      };
    }).toList();
  }

  // ============================================================
  // MEDICINE UNIQUE SELECTION KEY
  // ============================================================

  String _medicineSelectionKey(
    Map<String, dynamic> medicine,
    int medicineIndex,
  ) {
    final medicineId =
        medicine["medicineId"]
                ?.toString()
                .trim() ??
            "";

    // If backend already provides a real ID,
    // use it.
    if (medicineId.isNotEmpty) {
      return "id_$medicineId";
    }

    // If medicineId is missing/empty,
    // create a unique local key.
    final name =
        medicine["medicine"]
                ?.toString()
                .trim()
                .toLowerCase() ??
            "";

    final dose =
        medicine["dose"]
                ?.toString()
                .trim()
                .toLowerCase() ??
            "";

    final duration =
        medicine["duration"]
                ?.toString()
                .trim()
                .toLowerCase() ??
            "";

    /*
     * medicineIndex is extremely important here.
     *
     * Example:
     *
     * Paracetamol
     * Paracetamol
     *
     * Both may have empty medicineId.
     *
     * Their keys will still be different:
     *
     * local_0_paracetamol_...
     * local_1_paracetamol_...
     */
    return "local_${medicineIndex}_${name}_${dose}_$duration";
  }

  // ============================================================
  // MEDICINE SELECT / UNSELECT
  // ============================================================

  void toggleMedicine(
    String prescriptionId,
    Map<String, dynamic> medicine,
    int medicineIndex,
    bool selected,
  ) {
    final list =
        selectedMedicines.putIfAbsent(
      prescriptionId,
      () => [],
    );

    final medicineKey =
        _medicineSelectionKey(
      medicine,
      medicineIndex,
    );

    if (selected) {
      final alreadyExists =
          list.any(
        (item) =>
            item["_selectionKey"]
                ?.toString() ==
            medicineKey,
      );

      if (!alreadyExists) {
        final medicineCopy =
            Map<String, dynamic>.from(
          medicine,
        );

        // Store unique key only inside
        // local selected copy.
        medicineCopy["_selectionKey"] =
            medicineKey;

        list.add(medicineCopy);
      }
    } else {
      list.removeWhere(
        (item) =>
            item["_selectionKey"]
                ?.toString() ==
            medicineKey,
      );
    }

    setState(() {});
  }

  // ============================================================
  // CHECK WHETHER MEDICINE IS SELECTED
  // ============================================================

  bool isMedicineSelected(
    String prescriptionId,
    Map<String, dynamic> medicine,
    int medicineIndex,
  ) {
    final list =
        selectedMedicines[prescriptionId] ??
            [];

    final medicineKey =
        _medicineSelectionKey(
      medicine,
      medicineIndex,
    );

    return list.any(
      (item) =>
          item["_selectionKey"]
              ?.toString() ==
          medicineKey,
    );
  }

  // ============================================================
  // LAB TEST SELECT / UNSELECT
  // ============================================================

  void toggleLabTest(
    String prescriptionId,
    String testName,
    bool selected,
  ) {
    final list =
        selectedLabTests.putIfAbsent(
      prescriptionId,
      () => [],
    );

    if (selected) {
      if (!list.contains(testName)) {
        list.add(testName);
      }
    } else {
      list.remove(testName);
    }

    setState(() {});
  }

  // ============================================================
  // ORDER MEDICINES
  // ============================================================

  Future<void> orderMedicines(
    Map<String, dynamic> prescription,
  ) async {
    final id = prescriptionId(prescription);

    final selected = selectedMedicines[id] ?? [];

    // Keep this before clearing the selection after a successful
    // cart/checkout flow.
    final selectedMedicineCount = selected.length;

    if (selected.isEmpty) {
      showMessage(
        "selectAtLeastOneMedicine".tr(),
        Colors.orange,
      );
      return;
    }

    if (patientId.isEmpty) {
      showMessage(
        "patientInformationNotFound".tr(),
        Colors.red,
      );
      return;
    }

    try {
      showLoadingDialog(
        "checkingPharmacyInventory".tr(),
      );

      // ========================================================
      // RESOLVE REAL PHARMACY MEDICINE IDs
      // ========================================================

      final List<Map<String, dynamic>> medicinesToAdd = [];

      for (final medicine in selected) {
        String medicineId =
            medicine["medicineId"]?.toString().trim() ?? "";

        final medicineName =
            medicine["medicine"]?.toString().trim() ?? "";

        // ------------------------------------------------------
        // CASE 1:
        // Prescription already contains a real medicine ID.
        // ------------------------------------------------------

        if (medicineId.isNotEmpty) {
          medicinesToAdd.add({
            ...Map<String, dynamic>.from(medicine),
            "medicineId": medicineId,
          });

          continue;
        }

        // ------------------------------------------------------
        // CASE 2:
        // Prescription does not contain medicineId.
        // Search pharmacy inventory by medicine name.
        // ------------------------------------------------------

        if (medicineName.isEmpty) {
          throw Exception(
            "medicineNameMissing".tr(),
          );
        }

        final matches =
            await ApiService.findMedicinesByName(
          medicineName,
        );

        // ------------------------------------------------------
        // No pharmacy has this medicine.
        // ------------------------------------------------------

        if (matches.isEmpty) {
          throw Exception(
            "$medicineName is currently unavailable "
            "in pharmacy inventory.",
          );
        }

        // ------------------------------------------------------
        // One or more pharmacies have the medicine.
        //
        // For the current flow, use the first available
        // inventory record. The real medicine _id is used.
        // ------------------------------------------------------

        final inventoryMedicine =
            Map<String, dynamic>.from(matches.first);

        final realId =
            inventoryMedicine["_id"]?.toString().trim() ?? "";

        if (realId.isEmpty) {
          throw Exception(
            "invalidMedicineId".tr() + " $medicineName.",
          );
        }

        medicinesToAdd.add({
          ...Map<String, dynamic>.from(medicine),
          "medicineId": realId,
          "medicine":
              inventoryMedicine["medicineName"]
                      ?.toString() ??
                  medicineName,
        });
      }

      // ========================================================
      // REPLACE THE ACTIVE CART
      //
      // The cart is a temporary checkout cart in this app.
      // When the patient chooses "Add Selected Medicines"
      // from a prescription, remove any medicines left from
      // a previous app session/order before adding this new
      // selection.
      //
      // This prevents old medicines from appearing again after
      // the app is closed and reopened.
      // ========================================================

      debugPrint("================================");
      debugPrint("CLEARING PREVIOUS CART");
      debugPrint("PATIENT PHONE = $patientId");
      debugPrint("================================");

      final clearResult =
          await ApiService.clearCart(patientId);

      if (clearResult["success"] != true) {
        throw Exception(
          clearResult["message"]?.toString() ??
              "unableToClearPreviousCart".tr(),
        );
      }

      debugPrint(
        "✅ PREVIOUS CART CLEARED SUCCESSFULLY",
      );

      // ========================================================
      // ADD ONLY THE CURRENTLY SELECTED MEDICINES
      // ========================================================

      for (final medicine in medicinesToAdd) {
        final resolvedMedicineId =
            medicine["medicineId"]?.toString().trim() ?? "";

        if (resolvedMedicineId.isEmpty) {
          throw Exception(
            "unableToResolveMedicineId".tr(),
          );
        }

        await ApiService.addMedicineToCart(
          patientId: patientId,

          patientName:
              prescription["patientName"]
                      ?.toString() ??
                  "",

          medicineId: resolvedMedicineId,

          medicine:
              medicine["medicine"]
                      ?.toString() ??
                  "",

          dose:
              medicine["dose"]
                      ?.toString() ??
                  "",

          duration:
              medicine["duration"]
                      ?.toString() ??
                  "",

          food:
              medicine["food"]
                      ?.toString() ??
                  "",

          instruction:
              medicine["instruction"]
                      ?.toString() ??
                  "",

          quantity: 1,
        );
      }

      debugPrint(
        "✅ ONLY CURRENT PRESCRIPTION MEDICINES ADDED TO CART",
      );

      // ========================================================
      // CLOSE LOADING
      // ========================================================

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Clear selected medicines only after all medicines
      // have been successfully added to the cart.
      selectedMedicines[id]?.clear();

      showMessage(
        "selectedMedicinesAddedToCart".tr(),
        Colors.green,
      );

      // ========================================================
      // OPEN CART
      // ========================================================

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MyCartPage(),
        ),
      );

      // ========================================================
      // COMPLETE ONLY THE MEDICINE BRANCH
      // ========================================================
      //
      // If the patient selected all prescribed medicines and the
      // cart flow completed successfully, mark only the medicine
      // branch as completed.
      //
      // Lab tests remain independently available until the lab
      // branch is also completed.
      //

      if (result == true) {
        final totalMedicines =
            getMedicines(prescription).length;

        if (selectedMedicineCount >= totalMedicines &&
            totalMedicines > 0) {
          await markMedicinePrescriptionCompleted(id);
        }
      }
    } catch (e) {
      // Close loading dialog if it is open.
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint(
        "ORDER MEDICINES ERROR = $e",
      );

      showMessage(
        "unableToAddMedicines".tr() + " $e",
        Colors.red,
      );
    }
  }

  // ============================================================
  // BOOK LAB TESTS
  // ============================================================

  Future<void> bookLabTests(
    Map<String, dynamic> prescription,
  ) async {
    final id = prescriptionId(prescription);

    final selected =
        selectedLabTests[id] ?? [];

    final selectedLabTestCount = selected.length;

    if (selected.isEmpty) {
      showMessage(
        "selectAtLeastOneLabTest".tr(),
        Colors.orange,
      );
      return;
    }

    // Open the Lab Cart instead of directly opening
    // BookLabTestPage.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LabCartPage(
          selectedTests: List<String>.from(selected),
        ),
      ),
    );

    if (result == true) {
      selectedLabTests[id]?.clear();

      final totalLabTests =
          getLabTests(prescription).length;

      // Complete the lab branch only when all prescribed
      // lab tests have been successfully ordered.
      if (selectedLabTestCount >= totalLabTests &&
          totalLabTests > 0) {
        await markLabPrescriptionCompleted(id);
      }

      if (!mounted) return;

      showMessage(
        "labOrderPlacedSuccessfully".tr(),
        Colors.green,
      );

      // After successful booking, open My Lab Orders so the
      // patient can immediately track the new order.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LabOrdersPage(),
        ),
      );

      if (mounted) {
        await loadPrescriptions();
      }
    }
  }

  // ============================================================
  // PDF DOWNLOAD
  // ============================================================

  Future<File?> downloadPrescriptionPdf(
    Map<String, dynamic> prescription,
  ) async {
    final id =
        prescriptionId(prescription);

    if (id.isEmpty) {
      showMessage(
        "prescriptionIdNotFound".tr(),
        Colors.red,
      );
      return null;
    }

    try {
      final dir =
          await getApplicationDocumentsDirectory();

      final filePath =
          "${dir.path}/Prescription-$id.pdf";

      final url =
          "${ApiService.baseUrl}/api/prescriptions/pdf/$id";

      await Dio().download(
        url,
        filePath,
      );

      return File(filePath);
    } catch (e) {
      debugPrint(
        "PDF download error: $e",
      );

      showMessage(
        "unableToDownloadPrescriptionPdf".tr(),
        Colors.red,
      );

      return null;
    }
  }

  // ============================================================
  // VIEW PDF
  // ============================================================

  Future<void> viewPrescriptionPdf(
    Map<String, dynamic> prescription,
  ) async {
    showLoadingDialog(
      "openingPrescription".tr(),
    );

    final file =
        await downloadPrescriptionPdf(
      prescription,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (file == null) return;

    await OpenFilex.open(
      file.path,
    );
  }

  // ============================================================
  // SHARE PDF
  // ============================================================

  Future<void> sharePrescription(
    Map<String, dynamic> prescription,
  ) async {
    showLoadingDialog(
      "preparingPrescription".tr(),
    );

    final file =
        await downloadPrescriptionPdf(
      prescription,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (file == null) return;

    await Share.shareXFiles(
      [
        XFile(file.path),
      ],
      text:
          "healthHomePrescription".tr(),
    );
  }

  // ============================================================
  // VIEW DETAILS
  // ============================================================

  void viewPrescriptionDetails(
    Map<String, dynamic> prescription,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PrescriptionDetailsPage(
          prescription: prescription,
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar: AppBar(
        backgroundColor:
            backgroundColor,
        foregroundColor:
            Colors.black,
        elevation: 0,

        title: Text(
          "myPrescriptionsTitle".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),

        bottom: TabBar(
          controller: tabController,
          labelColor:
              primaryColor,
          unselectedLabelColor:
              Colors.grey,
          indicatorColor:
              primaryColor,
          indicatorWeight: 3,

          tabs: [
            Tab(
              text:
                  "activeTab".tr(namedArgs: {"count": activePrescriptions.length.toString()}),
            ),
            Tab(
              text:
                  "pastTab".tr(namedArgs: {"count": pastPrescriptions.length.toString()}),
            ),
          ],
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : TabBarView(
              controller:
                  tabController,
              children: [
                buildPrescriptionList(
                  activePrescriptions,
                  isPast: false,
                ),
                buildPrescriptionList(
                  pastPrescriptions,
                  isPast: true,
                ),
              ],
            ),
    );
  }

  // ============================================================
  // PRESCRIPTION LIST
  // ============================================================

  Widget buildPrescriptionList(
    List<dynamic> list, {
    required bool isPast,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              isPast
                  ? Icons.history
                  : Icons.receipt_long,
              size: 80,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              isPast
                  ? "noPastPrescriptions".tr()
                  : "noActivePrescriptions".tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPast
                  ? "previousPrescriptionsMessage".tr()
                  : "activePrescriptionsMessage".tr(),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          loadPrescriptions,
      child: ListView.builder(
        padding:
            const EdgeInsets.all(16),
        itemCount:
            list.length,
        itemBuilder:
            (context, index) {
          final prescription =
              Map<String, dynamic>.from(
            list[index],
          );

          return buildPrescriptionCard(
            prescription,
            isPast: isPast,
          );
        },
      ),
    );
  }

  // ============================================================
  // PRESCRIPTION CARD
  // ============================================================

  Widget buildPrescriptionCard(
    Map<String, dynamic> prescription, {
    required bool isPast,
  }) {
    final id =
        prescriptionId(prescription);

    final medicines =
        getMedicines(prescription);

    final labTests =
        getLabTests(prescription);

    final selectedMeds =
        selectedMedicines[id] ?? [];

    final selectedTests =
        selectedLabTests[id] ?? [];

    final medicinesCompleted =
        isMedicineBranchCompleted(
      id,
      medicines,
    );

    final labTestsCompleted =
        isLabBranchCompleted(
      id,
      labTests,
    );

    final doctorName =
        prescription["doctorName"]
                ?.toString() ??
            "doctor".tr();

    final diagnosis =
        prescription["diagnosis"]
                ?.toString() ??
            "";

    final createdAt =
        prescription["createdAt"]
                ?.toString() ??
            "";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    color: primaryColor
                        .withOpacity(.12),
                    shape:
                        BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .medical_services_rounded,
                    color:
                        primaryColor,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        doctorName,
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        formatDate(
                          createdAt,
                        ),
                        style: TextStyle(
                          color: Colors
                              .grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                buildStatusBadge(
                  isPast,
                  prescription,
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DIAGNOSIS
            // ==================================================

            if (diagnosis.isNotEmpty)
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xffF8FAFC),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons
                          .medical_information_outlined,
                      color:
                          primaryColor,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            "diagnosis".tr(),
                            style:
                                TextStyle(
                              color: Colors
                                  .grey.shade600,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            diagnosis,
                            style:
                                const TextStyle(
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

            // ==================================================
            // MEDICINES
            // ==================================================

            if (medicines.isNotEmpty) ...[
              const SizedBox(
                height: 22,
              ),

              buildSectionTitle(
                Icons.medication_rounded,
                "prescribedMedicines".tr(),
                "${medicines.length}",
              ),

              const SizedBox(
                height: 10,
              ),

              if (!isPast && !medicinesCompleted)
                ...medicines
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final medicineIndex =
                        entry.key;

                    final medicine =
                        entry.value;

                    return buildMedicineTile(
                      id,
                      medicine,
                      medicineIndex,
                    );
                  },
                )
              else
                ...medicines.map(
                  (medicine) {
                    return buildPastMedicineTile(
                      medicine,
                    );
                  },
                ),

              if (!isPast &&
                  !medicinesCompleted &&
                  selectedMeds.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 10,
                  ),
                  child:
                      buildPrimaryButton(
                    icon:
                        Icons.shopping_cart,
                    text:
                        "orderSelectedMedicines".tr(namedArgs: {"count": selectedMeds.length.toString()}),
                    onPressed:
                        () => orderMedicines(
                      prescription,
                    ),
                  ),
                ),
            ],

            // ==================================================
            // LAB TESTS
            // ==================================================

            if (labTests.isNotEmpty) ...[
              const SizedBox(
                height: 24,
              ),

              buildSectionTitle(
                Icons.science_rounded,
                "recommendedLabTests".tr(),
                "${labTests.length}",
              ),

              const SizedBox(
                height: 10,
              ),

              if (!isPast && !labTestsCompleted)
                ...labTests.map(
                  (test) {
                    return buildLabTestTile(
                      id,
                      test,
                    );
                  },
                )
              else
                ...labTests.map(
                  (test) {
                    return buildPastLabTestTile(
                      test,
                    );
                  },
                ),

              if (!isPast &&
                  !labTestsCompleted &&
                  selectedTests.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 10,
                  ),
                  child:
                      buildPrimaryButton(
                    icon:
                        Icons.science,
                    text:
                        "bookSelectedLabTests".tr(namedArgs: {"count": selectedTests.length.toString()}),
                    color:
                        Colors.deepPurple,
                    onPressed:
                        () => bookLabTests(
                      prescription,
                    ),
                  ),
                ),
            ],

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // ACTIONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        () =>
                            viewPrescriptionDetails(
                      prescription,
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label:
                        Text("details".tr()),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          primaryColor,
                      side:
                          const BorderSide(
                        color:
                            primaryColor,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
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

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        () =>
                            viewPrescriptionPdf(
                      prescription,
                    ),
                    icon: const Icon(
                      Icons
                          .picture_as_pdf_outlined,
                    ),
                    label:
                        Text("pdf".tr()),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.indigo,
                      side:
                          const BorderSide(
                        color:
                            Colors.indigo,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
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

                const SizedBox(
                  width: 10,
                ),

                IconButton(
                  onPressed:
                      () =>
                          sharePrescription(
                    prescription,
                  ),
                  style:
                      IconButton.styleFrom(
                    backgroundColor:
                        Colors.indigo
                            .withOpacity(.10),
                  ),
                  icon: const Icon(
                    Icons.share_outlined,
                    color:
                        Colors.indigo,
                  ),
                ),
              ],
            ),

            // ==================================================
            // PAST MESSAGE
            // ==================================================

            if (isPast) ...[
              const SizedBox(
                height: 15,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(13),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.green.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color:
                          Colors.green,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        "prescriptionProcessedMessage".tr(),
                        style:
                            TextStyle(
                          color:
                              Colors.green.shade800,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE TILE
  // ============================================================

  Widget buildMedicineTile(
    String prescriptionId,
    Map<String, dynamic> medicine,
    int medicineIndex,
  ) {
    final selected =
        isMedicineSelected(
      prescriptionId,
      medicine,
      medicineIndex,
    );

    final name =
        medicine["medicine"]
                ?.toString() ??
            "medicine".tr();

    final dose =
        medicine["dose"]
                ?.toString() ??
            "";

    final duration =
        medicine["duration"]
                ?.toString() ??
            "";

    final food =
        medicine["food"]
                ?.toString() ??
            "";

    final instruction =
        medicine["instruction"]
                ?.toString() ??
            "";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: selected
            ? primaryColor
                .withOpacity(.06)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? primaryColor
              : Colors.grey.shade200,
        ),
      ),
      child:
          CheckboxListTile(
        value: selected,
        onChanged: (value) {
          toggleMedicine(
            prescriptionId,
            medicine,
            medicineIndex,
            value ?? false,
          );
        },
        activeColor:
            primaryColor,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        controlAffinity:
            ListTileControlAffinity.leading,
        title: Text(
          name,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 7,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (dose.isNotEmpty)
                Text(
                  "doseLabel".tr() + ": $dose",
                ),
              if (duration.isNotEmpty)
                Text(
                  "durationLabel".tr() + ": $duration",
                ),
              if (food.isNotEmpty)
                Text(
                  "foodLabel".tr() + ": $food",
                ),
              if (instruction.isNotEmpty)
                Text(
                  "instructionsLabel".tr() + ": $instruction",
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAST MEDICINE
  // ============================================================

  Widget buildPastMedicineTile(
    Map<String, dynamic> medicine,
  ) {
    final name =
        medicine["medicine"]
                ?.toString() ??
            "medicine".tr();

    final dose =
        medicine["dose"]
                ?.toString() ??
            "";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              "$name${dose.isNotEmpty ? " • $dose" : ""}",
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
           Text(
            "ordered".tr(),
            style: TextStyle(
              color:
                  Colors.green,
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAB TEST TILE
  // ============================================================

  Widget buildLabTestTile(
    String prescriptionId,
    Map<String, dynamic> test,
  ) {
    final name =
        test["testName"]
                ?.toString() ??
            "labTest".tr();

    final priority =
        test["priority"]
                ?.toString() ??
            "Normal";

    final note =
        test["note"]
                ?.toString() ??
            "";

    final selected =
        selectedLabTests[
                  prescriptionId]
              ?.contains(name) ??
            false;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: selected
            ? Colors.deepPurple
                .withOpacity(.06)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? Colors.deepPurple
              : Colors.grey.shade200,
        ),
      ),
      child:
          CheckboxListTile(
        value: selected,
        onChanged: (value) {
          toggleLabTest(
            prescriptionId,
            name,
            value ?? false,
          );
        },
        activeColor:
            Colors.deepPurple,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        controlAffinity:
            ListTileControlAffinity.leading,
        title: Text(
          name,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "priorityLabel".tr() + ": $priority",
              ),
              if (note.isNotEmpty)
                Text(
                  "noteLabel".tr() + ": $note",
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAST LAB TEST
  // ============================================================

  Widget buildPastLabTestTile(
    Map<String, dynamic> test,
  ) {
    final name =
        test["testName"]
                ?.toString() ??
            "labTest".tr();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              name,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
           Text(
            "booked".tr(),
            style: TextStyle(
              color:
                  Colors.green,
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget buildSectionTitle(
    IconData icon,
    String title,
    String count,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 4,
          ),
          decoration:
              BoxDecoration(
            color:
                primaryColor.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style:
                const TextStyle(
              color:
                  primaryColor,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget buildStatusBadge(
    bool isPast,
    Map<String, dynamic> prescription,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: isPast
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        isPast ? "past".tr() : "active".tr(),
        style:
            TextStyle(
          color: isPast
              ? Colors.green
              : Colors.orange.shade800,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget buildPrimaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width:
          double.infinity,
      height: 52,
      child:
          ElevatedButton.icon(
        onPressed:
            onPressed,
        icon: Icon(
          icon,
          color:
              Colors.white,
        ),
        label: Text(
          text,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              color ?? primaryColor,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO MESSAGE
  // ============================================================

  void showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            color,
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  void showLoadingDialog(
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 25,
                height: 25,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Expanded(
                child: Text(
                  message,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String formatDate(
    String value,
  ) {
    if (value.isEmpty) {
      return "";
    }

    try {
      final date =
          DateTime.parse(value)
              .toLocal();

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} • "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return value;
    }
  }
}

// ==================================================================
// PRESCRIPTION DETAILS PAGE
// ==================================================================

class PrescriptionDetailsPage
    extends StatelessWidget {
  final Map<String, dynamic>
      prescription;

  final Color primaryColor;

  const PrescriptionDetailsPage({
    super.key,
    required this.prescription,
    required this.primaryColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final medicines =
        prescription["medicines"] is List
            ? prescription["medicines"]
                as List
            : [];

    final labTests =
        prescription["labTests"] is List
            ? prescription["labTests"]
                as List
            : [];

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(
        backgroundColor:
            primaryColor,
        foregroundColor:
            Colors.white,
        title: Text(
          "prescriptionDetails".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          // ==================================================
          // DOCTOR
          // ==================================================

          buildDetailsCard(
            title: "doctor".tr(),
            child: Text(
              prescription["doctorName"]
                      ?.toString() ??
                  "doctor".tr(),
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          // ==================================================
          // PATIENT
          // ==================================================

          buildDetailsCard(
            title: "patient".tr(),
            child: Text(
              prescription["patientName"]
                      ?.toString() ??
                  "-",
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          // ==================================================
          // DIAGNOSIS
          // ==================================================

          buildDetailsCard(
            title: "diagnosis".tr(),
            child: Text(
              prescription["diagnosis"]
                          ?.toString()
                          .isNotEmpty ==
                      true
                  ? prescription[
                          "diagnosis"]
                      .toString()
                  : "-",
            ),
          ),

          // ==================================================
          // SYMPTOMS
          // ==================================================

          buildDetailsCard(
            title: "symptoms".tr(),
            child: Text(
              formatSymptoms(
                prescription["symptoms"],
              ),
            ),
          ),

          // ==================================================
          // MEDICINES
          // ==================================================

          buildDetailsCard(
            title: "medicines".tr(),
            child: Column(
              children:
                  medicines.map<Widget>(
                (item) {
                  final medicine =
                      item is Map
                          ? Map<String,
                              dynamic>.from(
                              item,
                            )
                          : {
                              "medicine":
                                  item.toString()
                            };

                  return Container(
                    width:
                        double.infinity,
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.all(
                      13,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine[
                                      "medicine"]
                                  ?.toString() ??
                              "medicine".tr(),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize:
                                17,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "doseLabel".tr() + ": ${medicine["dose"] ?? "-"}",
                        ),
                        Text(
                          "durationLabel".tr() + ": ${medicine["duration"] ?? "-"}",
                        ),
                        Text(
                          "foodLabel".tr() + ": ${medicine["food"] ?? "-"}",
                        ),
                        Text(
                          "instructionsLabel".tr() + ": ${medicine["instruction"] ?? "-"}",
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ),

          // ==================================================
          // LAB TESTS
          // ==================================================

          if (labTests.isNotEmpty)
            buildDetailsCard(
              title:
                  "recommendedLabTests".tr(),
              child: Column(
                children:
                    labTests.map<Widget>(
                  (item) {
                    if (item is Map) {
                      final test =
                          Map<String,
                              dynamic>.from(
                        item,
                      );

                      return ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading:
                            Icon(
                          Icons.science,
                          color:
                              primaryColor,
                        ),
                        title:
                            Text(
                          test["testName"]
                                  ?.toString() ??
                              "labTest".tr(),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            Text(
                          "priorityLabel".tr() + ": ${test["priority"] ?? "Normal"}"
                          "${(test["note"] ?? "").toString().isNotEmpty ? "\n${test["note"]}" : ""}",
                        ),
                      );
                    }

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          Icon(
                        Icons.science,
                        color:
                            primaryColor,
                      ),
                      title:
                          Text(
                        item.toString(),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS CARD
  // ============================================================

  Widget buildDetailsCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(
              color:
                  primaryColor,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT SYMPTOMS
  // ============================================================

  String formatSymptoms(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (e) => e.toString(),
          )
          .join(", ");
    }

    return value?.toString() ?? "-";
  }
}