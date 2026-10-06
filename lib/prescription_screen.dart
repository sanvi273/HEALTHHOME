import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class PrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const PrescriptionScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<PrescriptionScreen> createState() =>
      _PrescriptionScreenState();
}

class _PrescriptionScreenState
    extends State<PrescriptionScreen> {

  // ============================================================
  // CLINICAL
  // ============================================================

  final symptomsController =
      TextEditingController();

  final diagnosisController =
      TextEditingController();

  final notesController =
      TextEditingController();

  // ============================================================
  // MEDICINE
  // ============================================================

  final medicineNameController =
      TextEditingController();

  final doseController =
      TextEditingController();

  final durationController =
      TextEditingController();

  final instructionController =
      TextEditingController();

  // ============================================================
  // LAB TEST
  // ============================================================

  final labTestNameController =
      TextEditingController();

  final labTestNoteController =
      TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  final List<Map<String, dynamic>> medicines = [];

  final List<Map<String, dynamic>> labTests = [];

  // ============================================================
  // MEDICINE OPTIONS
  // ============================================================

  bool morning = true;
  bool afternoon = false;
  bool night = true;

  String foodTiming = "After Food";

  // ============================================================
  // LAB TEST OPTIONS
  // ============================================================

  String labPriority = "Normal";

  // ============================================================
  // PRESCRIPTION
  // ============================================================

  String? prescriptionId;

  bool isSaving = false;
  bool isDownloading = false;
  bool isSending = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    symptomsController.dispose();
    diagnosisController.dispose();
    notesController.dispose();

    medicineNameController.dispose();
    doseController.dispose();
    durationController.dispose();
    instructionController.dispose();

    labTestNameController.dispose();
    labTestNoteController.dispose();

    super.dispose();
  }

  // ============================================================
  // ADD MEDICINE
  // ============================================================

  void addMedicine() {

    final medicineName =
        medicineNameController.text.trim();

    final dose =
        doseController.text.trim();

    final duration =
        durationController.text.trim();

    if (medicineName.isEmpty) {
      showMessage(
        "Please enter medicine name.",
      );
      return;
    }

    if (dose.isEmpty) {
      showMessage(
        "Please enter dosage.",
      );
      return;
    }

    if (duration.isEmpty) {
      showMessage(
        "Please enter duration.",
      );
      return;
    }

    if (!morning &&
        !afternoon &&
        !night) {
      showMessage(
        "Please select at least one time.",
      );
      return;
    }

    final medicine =
        <String, dynamic>{
      "medicine":
          medicineName,

      "dose":
          dose,

      "morning":
          morning,

      "afternoon":
          afternoon,

      "night":
          night,

      "food":
          foodTiming,

      "duration":
          duration,

      "instruction":
          instructionController.text.trim(),
    };

    setState(() {
      medicines.add(medicine);

      medicineNameController.clear();
      doseController.clear();
      durationController.clear();
      instructionController.clear();

      morning = true;
      afternoon = false;
      night = true;

      foodTiming = "After Food";
    });

    FocusScope.of(context).unfocus();

    showMessage(
      "Medicine added.",
      success: true,
    );
  }

  // ============================================================
  // REMOVE MEDICINE
  // ============================================================

  void removeMedicine(int index) {

    if (index < 0 ||
        index >= medicines.length) {
      return;
    }

    setState(() {
      medicines.removeAt(index);
    });
  }

  // ============================================================
  // ADD LAB TEST
  // ============================================================

  void addLabTest() {

    final testName =
        labTestNameController.text.trim();

    final note =
        labTestNoteController.text.trim();

    if (testName.isEmpty) {
      showMessage(
        "Please enter lab test name.",
      );
      return;
    }

    final test =
        <String, dynamic>{
      "testName":
          testName,

      "priority":
          labPriority,

      "note":
          note,
    };

    setState(() {
      labTests.add(test);

      labTestNameController.clear();
      labTestNoteController.clear();

      labPriority = "Normal";
    });

    FocusScope.of(context).unfocus();

    showMessage(
      "Lab test added.",
      success: true,
    );
  }

  // ============================================================
  // REMOVE LAB TEST
  // ============================================================

  void removeLabTest(int index) {

    if (index < 0 ||
        index >= labTests.length) {
      return;
    }

    setState(() {
      labTests.removeAt(index);
    });
  }

  // ============================================================
  // SAVE PRESCRIPTION
  // ============================================================

  Future<void> savePrescription() async {

    if (diagnosisController.text
        .trim()
        .isEmpty) {

      showMessage(
        "Please enter diagnosis.",
      );
      return;
    }

    if (medicines.isEmpty &&
        labTests.isEmpty) {

      showMessage(
        "Add at least one medicine or lab test.",
      );
      return;
    }

    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {

      final prescription =
          <String, dynamic>{

        "appointmentId":
            widget.appointment["_id"]
                ?.toString(),

        "patientId":
            widget.appointment[
                    "patientPhone"]
                ?.toString(),

        "doctorId":
            widget.appointment[
                    "doctorId"]
                ?.toString(),

        "patientName":
            widget.appointment[
                    "patientName"]
                ?.toString() ??
                "",

        "patientPhone":
            widget.appointment[
                    "patientPhone"]
                ?.toString() ??
                "",

        "doctorName":
            widget.appointment[
                    "doctorName"]
                ?.toString() ??
                "",

        "appointmentDate":
            widget.appointment[
                    "appointmentDate"]
                ?.toString() ??
                "",

        "appointmentTime":
            widget.appointment[
                    "appointmentTime"]
                ?.toString() ??
                "",

        "diagnosis":
            diagnosisController.text.trim(),

        "symptoms":
            symptomsController.text.trim(),

        "medicines":
            medicines,

        "labTests":
            labTests,

        "advice":
            notesController.text.trim(),
      };

      debugPrint(
        "================================",
      );

      debugPrint(
        "SAVING PRESCRIPTION",
      );

      debugPrint(
        "MEDICINES: $medicines",
      );

      debugPrint(
        "LAB TESTS: $labTests",
      );

      debugPrint(
        "================================",
      );

      final result =
          await ApiService.savePrescription(
        prescription:
            prescription,
      );

      debugPrint(
        "SAVE RESPONSE: $result",
      );

      if (!mounted) {
        return;
      }

      if (result["success"] == true) {

        final saved =
            result["prescription"];

        if (saved is Map) {

          final id =
              saved["_id"];

          if (id != null) {
            prescriptionId =
                id.toString();
          }
        }

        showMessage(
          "Prescription saved successfully.",
          success: true,
        );

        setState(() {});
      } else {

        throw Exception(
          result["message"] ??
              "Unable to save prescription.",
        );
      }

    } catch (e) {

      debugPrint(
        "SAVE PRESCRIPTION ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      showMessage(
        "Failed to save prescription: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // GENERATE PDF
  // ============================================================

  Future<void> generatePdf() async {

    if (prescriptionId == null ||
        prescriptionId!.isEmpty) {

      showMessage(
        "Save the prescription first.",
      );
      return;
    }

    if (isDownloading) {
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {

      await ApiService.downloadPrescription(
        prescriptionId!,
      );

      if (!mounted) {
        return;
      }

      showMessage(
        "Prescription PDF generated.",
        success: true,
      );

    } catch (e) {

      debugPrint(
        "PDF ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      showMessage(
        "Unable to generate PDF: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // ============================================================
  // SEND TO PATIENT
  // ============================================================

  Future<void> sendToPatient() async {

    if (prescriptionId == null ||
        prescriptionId!.isEmpty) {

      showMessage(
        "Save the prescription first.",
      );
      return;
    }

    if (isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {

      final response =
          await ApiService.sendPrescription(
        prescriptionId!,
      );

      if (!mounted) {
        return;
      }

      if (response["success"] == true) {

        showMessage(
          "Prescription sent to patient.",
          success: true,
        );

        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);

      } else {

        throw Exception(
          response["message"] ??
              "Unable to send prescription.",
        );
      }

    } catch (e) {

      debugPrint(
        "SEND PRESCRIPTION ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      showMessage(
        "Failed to send prescription: $e",
      );

    } finally {

      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool success = false,
  }) {

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              success
                  ? const Color(0xff14B8A6)
                  : Colors.redAccent,
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
          const Color(0xffF4F7FB),

      appBar: AppBar(

        backgroundColor:
            const Color(0xff14B8A6),

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          "Doctor Prescription",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(

        child: ListView(

          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              const EdgeInsets.all(16),

          children: [

            buildPatientCard(),

            const SizedBox(
              height: 18,
            ),

            buildTextCard(
              controller:
                  symptomsController,
              title:
                  "Symptoms",
              hint:
                  "Enter patient symptoms...",
              icon:
                  Icons.sick_outlined,
              maxLines: 4,
            ),

            const SizedBox(
              height: 16,
            ),

            buildTextCard(
              controller:
                  diagnosisController,
              title:
                  "Diagnosis",
              hint:
                  "Enter diagnosis...",
              icon:
                  Icons.medical_information_outlined,
              maxLines: 4,
            ),

            const SizedBox(
              height: 16,
            ),

            buildTextCard(
              controller:
                  notesController,
              title:
                  "Clinical Notes",
              hint:
                  "Enter clinical notes and advice...",
              icon:
                  Icons.notes_outlined,
              maxLines: 5,
            ),

            const SizedBox(
              height: 22,
            ),

            buildMedicineSection(),

            const SizedBox(
              height: 22,
            ),

            buildLabTestSection(),

            const SizedBox(
              height: 28,
            ),

            buildActionButtons(),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PATIENT CARD
  // ============================================================

  Widget buildPatientCard() {

    return Container(

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [

          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 8,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.person_outline,
                color:
                    Color(0xff14B8A6),
                size: 28,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                "Patient Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          const Divider(),

          patientTile(
            Icons.person,
            "Patient Name",
            widget.appointment[
                    "patientName"]
                ?.toString() ??
                "",
          ),

          patientTile(
            Icons.phone,
            "Phone",
            widget.appointment[
                    "patientPhone"]
                ?.toString() ??
                "",
          ),

          patientTile(
            Icons.calendar_today,
            "Appointment Date",
            widget.appointment[
                    "appointmentDate"]
                ?.toString() ??
                "",
          ),

          patientTile(
            Icons.access_time,
            "Appointment Time",
            widget.appointment[
                    "appointmentTime"]
                ?.toString() ??
                "",
          ),

          patientTile(
            Icons.medical_services,
            "Reason",
            widget.appointment[
                    "reason"]
                ?.toString() ??
                "Not specified",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT CARD
  // ============================================================

  Widget buildTextCard({
    required TextEditingController controller,
    required String title,
    required String hint,
    required IconData icon,
    required int maxLines,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [

          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 7,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Icon(
                icon,
                color:
                    const Color(
                  0xff14B8A6,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(

            controller:
                controller,

            maxLines:
                maxLines,

            textCapitalization:
                TextCapitalization.sentences,

            decoration:
                InputDecoration(

              hintText:
                  hint,

              filled: true,

              fillColor:
                  const Color(
                0xffF7F9FA,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE SECTION
  // ============================================================

  Widget buildMedicineSection() {

    return Container(

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [

          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 8,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          sectionHeader(
            icon:
                Icons.medication_outlined,
            title:
                "Medicines",
            subtitle:
                "Enter prescribed medicines",
          ),

          const SizedBox(
            height: 18,
          ),

          // ----------------------------------------------------
          // MEDICINE NAME
          // ----------------------------------------------------

          TextField(

            controller:
                medicineNameController,

            textCapitalization:
                TextCapitalization.words,

            decoration:
                inputDecoration(
              label:
                  "Medicine Name",
              hint:
                  "e.g. Paracetamol 650",
              icon:
                  Icons.medication,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // DOSE
          // ----------------------------------------------------

          TextField(

            controller:
                doseController,

            decoration:
                inputDecoration(
              label:
                  "Dosage",
              hint:
                  "e.g. 650 mg",
              icon:
                  Icons.medical_information,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            "When to take",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [

              Expanded(
                child:
                    buildCheck(
                  "Morning",
                  morning,
                  (value) {
                    setState(() {
                      morning =
                          value;
                    });
                  },
                ),
              ),

              Expanded(
                child:
                    buildCheck(
                  "Afternoon",
                  afternoon,
                  (value) {
                    setState(() {
                      afternoon =
                          value;
                    });
                  },
                ),
              ),

              Expanded(
                child:
                    buildCheck(
                  "Night",
                  night,
                  (value) {
                    setState(() {
                      night =
                          value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ----------------------------------------------------
          // FOOD
          // ----------------------------------------------------

          DropdownButtonFormField<String>(

            initialValue:
                foodTiming,

            decoration:
                inputDecoration(
              label:
                  "Food Timing",
              hint:
                  "",
              icon:
                  Icons.restaurant,
            ),

            items: const [

              DropdownMenuItem(
                value:
                    "Before Food",
                child:
                    Text(
                  "Before Food",
                ),
              ),

              DropdownMenuItem(
                value:
                    "After Food",
                child:
                    Text(
                  "After Food",
                ),
              ),
            ],

            onChanged:
                (value) {

              if (value == null) {
                return;
              }

              setState(() {
                foodTiming =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // DURATION
          // ----------------------------------------------------

          TextField(

            controller:
                durationController,

            decoration:
                inputDecoration(
              label:
                  "Duration",
              hint:
                  "e.g. 5 Days",
              icon:
                  Icons.calendar_month,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // INSTRUCTIONS
          // ----------------------------------------------------

          TextField(

            controller:
                instructionController,

            maxLines:
                3,

            decoration:
                inputDecoration(
              label:
                  "Instructions",
              hint:
                  "e.g. Take with warm water",
              icon:
                  Icons.notes_outlined,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ----------------------------------------------------
          // ADD
          // ----------------------------------------------------

          SizedBox(

            width:
                double.infinity,

            height:
                50,

            child:
                ElevatedButton.icon(

              onPressed:
                  addMedicine,

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(
                  0xff14B8A6,
                ),

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              icon:
                  const Icon(
                Icons.add,
              ),

              label:
                  const Text(
                "Add Medicine",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ----------------------------------------------------
          // ADDED MEDICINES
          // ----------------------------------------------------

          if (medicines.isNotEmpty)
            Column(
              children:
                  List.generate(
                medicines.length,
                (index) {

                  return buildMedicineCard(
                    medicines[index],
                    index,
                  );
                },
              ),
            ),

          if (medicines.isEmpty)
            emptyBox(
              icon:
                  Icons.medication_outlined,
              text:
                  "No medicines added yet",
            ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE CARD
  // ============================================================

  Widget buildMedicineCard(
    Map<String, dynamic> medicine,
    int index,
  ) {

    return Container(

      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(

        color:
            const Color(0xffF9FBFB),

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              Colors.black12,
        ),
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(

            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffE8FAF8,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Icon(
              Icons.medication,
              color:
                  Color(0xff14B8A6),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  medicine["medicine"]
                          ?.toString() ??
                      "",

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  "${medicine["dose"]} • ${medicine["duration"]}",
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  "${medicine["food"]} • ${medicineTimes(medicine)}",
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                ),

                if ((medicine["instruction"]
                            ?.toString() ??
                        "")
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child:
                        Text(
                      medicine[
                              "instruction"]
                          .toString(),
                      style:
                          const TextStyle(
                        color:
                            Colors.black45,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          IconButton(

            onPressed:
                () {
              removeMedicine(
                index,
              );
            },

            icon:
                const Icon(
              Icons.delete_outline,
              color:
                  Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE TIME
  // ============================================================

  String medicineTimes(
    Map<String, dynamic> medicine,
  ) {

    final times =
        <String>[];

    if (medicine["morning"] ==
        true) {
      times.add(
        "Morning",
      );
    }

    if (medicine["afternoon"] ==
        true) {
      times.add(
        "Afternoon",
      );
    }

    if (medicine["night"] ==
        true) {
      times.add(
        "Night",
      );
    }

    return times.isEmpty
        ? "No time selected"
        : times.join(", ");
  }

  // ============================================================
  // LAB TEST SECTION
  // ============================================================

  Widget buildLabTestSection() {

    return Container(

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [

          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 8,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          sectionHeader(
            icon:
                Icons.science_outlined,
            title:
                "Lab Tests",
            subtitle:
                "Add recommended investigations",
          ),

          const SizedBox(
            height: 18,
          ),

          // ----------------------------------------------------
          // TEST NAME
          // ----------------------------------------------------

          TextField(

            controller:
                labTestNameController,

            textCapitalization:
                TextCapitalization.words,

            decoration:
                inputDecoration(
              label:
                  "Test Name",
              hint:
                  "e.g. CBC",
              icon:
                  Icons.science,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // PRIORITY
          // ----------------------------------------------------

          DropdownButtonFormField<String>(

            initialValue:
                labPriority,

            decoration:
                inputDecoration(
              label:
                  "Priority",
              hint:
                  "",
              icon:
                  Icons.flag_outlined,
            ),

            items: const [

              DropdownMenuItem(
                value:
                    "Normal",
                child:
                    Text(
                  "Normal",
                ),
              ),

              DropdownMenuItem(
                value:
                    "High",
                child:
                    Text(
                  "High",
                ),
              ),

              DropdownMenuItem(
                value:
                    "Urgent",
                child:
                    Text(
                  "Urgent",
                ),
              ),
            ],

            onChanged:
                (value) {

              if (value == null) {
                return;
              }

              setState(() {
                labPriority =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // TEST NOTE
          // ----------------------------------------------------

          TextField(

            controller:
                labTestNoteController,

            maxLines:
                3,

            decoration:
                inputDecoration(
              label:
                  "Test Instructions",
              hint:
                  "e.g. Fasting required",
              icon:
                  Icons.notes_outlined,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ----------------------------------------------------
          // ADD TEST
          // ----------------------------------------------------

          SizedBox(

            width:
                double.infinity,

            height:
                50,

            child:
                ElevatedButton.icon(

              onPressed:
                  addLabTest,

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(
                  0xff14B8A6,
                ),

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              icon:
                  const Icon(
                Icons.add,
              ),

              label:
                  const Text(
                "Add Lab Test",
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ----------------------------------------------------
          // LIST
          // ----------------------------------------------------

          if (labTests.isNotEmpty)
            Column(
              children:
                  List.generate(
                labTests.length,
                (index) {

                  return buildLabTestCard(
                    labTests[index],
                    index,
                  );
                },
              ),
            ),

          if (labTests.isEmpty)
            emptyBox(
              icon:
                  Icons.science_outlined,
              text:
                  "No lab tests added yet",
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LAB TEST CARD
  // ============================================================

  Widget buildLabTestCard(
    Map<String, dynamic> test,
    int index,
  ) {

    final priority =
        test["priority"]
                ?.toString() ??
            "Normal";

    Color priorityColor;

    if (priority ==
        "Urgent") {
      priorityColor =
          Colors.red;
    } else if (priority ==
        "High") {
      priorityColor =
          Colors.orange;
    } else {
      priorityColor =
          Colors.green;
    }

    return Container(

      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(

        color:
            const Color(0xffF9FBFB),

        borderRadius:
            BorderRadius.circular(16),

        border:
            Border.all(
          color:
              Colors.black12,
        ),
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(

            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffE8FAF8,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Icon(
              Icons.science,
              color:
                  Color(0xff14B8A6),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  test["testName"]
                          ?.toString() ??
                      "",

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Container(

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        priorityColor
                            .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child:
                      Text(
                    priority,
                    style:
                        TextStyle(
                      color:
                          priorityColor,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                if ((test["note"]
                            ?.toString() ??
                        "")
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 7,
                    ),
                    child:
                        Text(
                      test["note"]
                          .toString(),
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          IconButton(

            onPressed:
                () {
              removeLabTest(
                index,
              );
            },

            icon:
                const Icon(
              Icons.delete_outline,
              color:
                  Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget buildActionButtons() {

    return Column(
      children: [

        SizedBox(

          width:
              double.infinity,

          height:
              56,

          child:
              ElevatedButton.icon(

            onPressed:
                isSaving
                    ? null
                    : savePrescription,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(
                0xff14B8A6,
              ),

              disabledBackgroundColor:
                  Colors.grey,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),

            icon:
                isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                        color:
                            Colors.white,
                      ),

            label:
                Text(
              isSaving
                  ? "Saving..."
                  : "Save Prescription",

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        SizedBox(

          width:
              double.infinity,

          height:
              56,

          child:
              ElevatedButton.icon(

            onPressed:
                isDownloading
                    ? null
                    : generatePdf,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.blue,

              disabledBackgroundColor:
                  Colors.grey,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),

            icon:
                isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf,
                        color:
                            Colors.white,
                      ),

            label:
                Text(
              isDownloading
                  ? "Generating..."
                  : "Generate PDF",

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        SizedBox(

          width:
              double.infinity,

          height:
              56,

          child:
              ElevatedButton.icon(

            onPressed:
                isSending
                    ? null
                    : sendToPatient,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.green,

              disabledBackgroundColor:
                  Colors.grey,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),

            icon:
                isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color:
                            Colors.white,
                      ),

            label:
                Text(
              isSending
                  ? "Sending..."
                  : "Send To Patient",

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {

    return Row(
      children: [

        Container(

          width: 44,
          height: 44,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xffE8FAF8,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child:
              Icon(
            icon,
            color:
                const Color(
              0xff14B8A6,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {

    return InputDecoration(

      labelText:
          label,

      hintText:
          hint.isEmpty
              ? null
              : hint,

      prefixIcon:
          Icon(icon),

      filled:
          true,

      fillColor:
          const Color(
        0xffF7F9FA,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.black12,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xff14B8A6),
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // CHECKBOX
  // ============================================================

  Widget buildCheck(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {

    return CheckboxListTile(

      contentPadding:
          EdgeInsets.zero,

      dense:
          true,

      value:
          value,

      title:
          Text(
        title,
        style:
            const TextStyle(
          fontSize: 13,
        ),
      ),

      activeColor:
          const Color(
        0xff14B8A6,
      ),

      onChanged:
          (newValue) {

        if (newValue == null) {
          return;
        }

        onChanged(
          newValue,
        );
      },
    );
  }

  // ============================================================
  // EMPTY BOX
  // ============================================================

  Widget emptyBox({
    required IconData icon,
    required String text,
  }) {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(

        color:
            const Color(
          0xffF7F9FA,
        ),

        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),

      child:
          Column(
        children: [

          Icon(
            icon,
            size: 38,
            color:
                Colors.black38,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            text,
            style:
                const TextStyle(
              color:
                  Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PATIENT TILE
  // ============================================================

  Widget patientTile(
    IconData icon,
    String title,
    String value,
  ) {

    return Padding(

      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child:
          Row(
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

          const SizedBox(
            width: 12,
          ),

          Text(
            "$title : ",

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Expanded(
            child:
                Text(
              value.isEmpty
                  ? "Not specified"
                  : value,
            ),
          ),
        ],
      ),
    );
  }
}