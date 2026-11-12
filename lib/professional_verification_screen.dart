import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'doctor_profile_setup.dart';
import 'lab_profile_setup.dart';
import 'lab_dashboard.dart';
import 'pharmacy_profile_setup.dart';
import 'pharmacy_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'services/api_service.dart';
import 'services/incoming_call_service.dart';

class ProfessionalVerificationScreen extends StatefulWidget {
  final String role;

  const ProfessionalVerificationScreen({
    super.key,
    required this.role,
  });

  @override
  State<ProfessionalVerificationScreen> createState() =>
      _ProfessionalVerificationScreenState();
}

class _ProfessionalVerificationScreenState
    extends State<ProfessionalVerificationScreen> {
  bool isLoading = true;

  String status = "PENDING";
  String licenseNumber = "";
  String organizationName = "";
  String address = "";
  String rejectionReason = "";

  List<dynamic> documents = [];

  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseTypeController =
      TextEditingController();
  final TextEditingController _organizationController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _licenseTypeController.text = _defaultDocumentType;
    loadVerification();
  }

  String get _roleKey => widget.role.trim().toLowerCase();

  String get _defaultDocumentType {
    switch (_roleKey) {
      case "pharmacy":
        return "Pharmacy License";
      case "laboratory":
      case "lab":
        return "Laboratory License";
      default:
        return "Medical License";
    }
  }

  List<String> get _documentTypeOptions {
    switch (_roleKey) {
      case "pharmacy":
        return const [
          "Pharmacy License",
          "Business Registration",
          "Government ID",
          "Additional Document",
        ];
      case "laboratory":
      case "lab":
        return const [
          "Laboratory License",
          "Laboratory Registration",
          "Government ID",
          "Additional Document",
        ];
      default:
        return const [
          "Medical License",
          "Medical Registration",
          "Government ID",
          "Additional Document",
        ];
    }
  }

  String get _licenseNumberLabel {
    switch (_roleKey) {
      case "pharmacy":
        return "Pharmacy license number";
      case "laboratory":
      case "lab":
        return "Laboratory license number";
      default:
        return "Medical registration/license number";
    }
  }

  // =========================================================
  // LOAD VERIFICATION DETAILS
  // =========================================================

  Future<void> loadVerification() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token") ?? "";

      if (token.isEmpty) {
        throw Exception(
          "Login session expired. Please login again.",
        );
      }

      debugPrint(
        "======================================",
      );

      debugPrint(
        "LOADING PROFESSIONAL VERIFICATION",
      );

      debugPrint(
        "ROLE = ${widget.role}",
      );

      debugPrint(
        "======================================",
      );

      final response =
          await ApiService.getMyVerification(
        token: token,
      );

      debugPrint(
        "VERIFICATION RESPONSE = $response",
      );

      if (response["success"] == true &&
          response["verification"] != null) {
        final verification =
            Map<String, dynamic>.from(
          response["verification"],
        );

        if (!mounted) return;

        setState(() {
          status =
              verification["status"]
                      ?.toString()
                      .toUpperCase() ??
                  "PENDING";

          licenseNumber =
              verification["licenseNumber"]
                      ?.toString() ??
                  "";
          _licenseNumberController.text = licenseNumber;

          organizationName =
              verification["organizationName"]
                      ?.toString() ??
                  "";
          _organizationController.text = organizationName;
          _registrationNumberController.text =
              verification["registrationNumber"]?.toString() ?? "";
          if (_licenseTypeController.text.trim().isEmpty) {
            _licenseTypeController.text = _defaultDocumentType;
          }

          address =
              verification["address"]
                      ?.toString() ??
                  "";

          rejectionReason =
              verification["rejectionReason"]
                      ?.toString() ??
                  "";

          documents =
              verification["documents"] is List
                  ? verification["documents"]
                  : [];

          isLoading = false;
        });

        if (status == "APPROVED") {
          await _continueAfterApproval();
        }
      } else {
        throw Exception(
          response["message"]?.toString() ??
              "Unable to load verification details",
        );
      }
    } catch (e) {
      debugPrint(
        "VERIFICATION SCREEN ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _continueAfterApproval() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString("userPhone") ?? "";
    final role = widget.role.toLowerCase();
    Widget destination;

    if (role == "doctor") {
      final profile = await ApiService.getDoctorProfile(phone);
      destination = profile["success"] == true && profile["doctor"] != null
          ? const DoctorDashboard()
          : const DoctorProfileSetup();
    } else if (role == "laboratory" || role == "lab") {
      final profile = await ApiService.getLabProfile(phone);
      destination = profile["success"] == true && profile["lab"] != null
          ? const LaboratoryDashboard()
          : const LabProfileSetup();
    } else if (role == "pharmacy") {
      final profile = await ApiService.getPharmacyProfile(phone);
      destination = profile["success"] == true && profile["pharmacy"] != null
          ? const PharmacyDashboard()
          : const PharmacyProfileSetup();
    } else {
      return;
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _submitDocuments() async {
    if (_licenseNumberController.text.trim().isEmpty ||
        _licenseTypeController.text.trim().isEmpty ||
        documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your license number and upload at least one document."),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await ApiService.submitVerification(
        token: prefs.getString("token") ?? "",
        role: widget.role,
        licenseNumber: _licenseNumberController.text.trim(),
        licenseType: _licenseTypeController.text.trim(),
        documentUrl: "",
        businessName: _organizationController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        documents: documents
            .whereType<Map>()
            .map((document) => Map<String, dynamic>.from(document))
            .toList(),
      );
      if (response["success"] != true) {
        throw Exception(response["message"] ?? "Unable to submit documents.");
      }
      await loadVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification details submitted.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ["pdf", "jpg", "jpeg", "png"],
        withData: true,
      );
      if (selection == null || selection.files.isEmpty) return;
      final file = selection.files.single;
      if (file.bytes == null) {
        throw Exception("Unable to read the selected document.");
      }
      final extension = file.extension?.toLowerCase() ?? "";
      if (!["pdf", "jpg", "jpeg", "png"].contains(extension)) {
        throw Exception("Choose a PDF, JPG, JPEG, or PNG document.");
      }
      if (file.bytes!.length > 10 * 1024 * 1024) {
        throw Exception("Document must be 10 MB or smaller.");
      }

      setState(() => _isUploading = true);
      final prefs = await SharedPreferences.getInstance();
      final result = await ApiService.uploadVerificationDocument(
        token: prefs.getString("token") ?? "",
        bytes: file.bytes!,
        filename: file.name,
        documentType: _licenseTypeController.text.trim().isEmpty
            ? _defaultDocumentType
            : _licenseTypeController.text.trim(),
      );
      if (result["success"] != true || result["document"] is! Map) {
        throw Exception(result["message"] ?? "Document upload failed.");
      }
      final duplicate = result["duplicate"] == true;
      if (!mounted) return;
      final uploadedDocument = Map<String, dynamic>.from(
        result["document"] as Map,
      );
      setState(() {
        final uploadedUrl = uploadedDocument["url"]?.toString() ?? "";
        final alreadyListed = documents.whereType<Map>().any(
          (document) =>
              document["url"]?.toString() == uploadedUrl &&
              uploadedUrl.isNotEmpty,
        );
        if (!alreadyListed) documents = [...documents, uploadedDocument];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate
                ? "This document is already attached to your application."
                : "Uploaded ${file.name} to your verification application.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseTypeController.dispose();
    _organizationController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  // =========================================================
  // STATUS TITLE
  // =========================================================

  String get statusTitle {
    switch (status) {
      case "APPROVED":
        return "Verification Approved";

      case "UNDER_REVIEW":
        return "Under Review";

      case "REJECTED":
        return "Verification Rejected";

      default:
        return "Verification Pending";
    }
  }

  // =========================================================
  // STATUS MESSAGE
  // =========================================================

  String get statusMessage {
    switch (status) {
      case "APPROVED":
        return "Your professional account has been approved.";

      case "UNDER_REVIEW":
        return "Your documents are currently being reviewed by the HealthHome admin.";

      case "REJECTED":
        if (rejectionReason.isNotEmpty) {
          return rejectionReason;
        }

        return "Your verification application was rejected.";

      default:
        return "Your verification application is waiting for admin approval.";
    }
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData get statusIcon {
    switch (status) {
      case "APPROVED":
        return Icons.verified;

      case "UNDER_REVIEW":
        return Icons.manage_search;

      case "REJECTED":
        return Icons.cancel;

      default:
        return Icons.hourglass_top;
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await IncomingCallService.unregisterCurrentDevice();
    await prefs.remove("token");

    await prefs.setBool(
      "isLoggedIn",
      false,
    );

    if (!mounted) return;

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7FAFC),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        centerTitle: true,

        title: const Text(
          "Account Verification",
          style: TextStyle(
            color:
                Color(0xff111827),
            fontWeight:
                FontWeight.bold,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color:
              Color(0xff111827),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xff00C2CB),
              ),
            )
          : RefreshIndicator(
              onRefresh:
                  loadVerification,

              color:
                  const Color(0xff00C2CB),

              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                child: Column(
                  children: [

                    const SizedBox(
                      height: 15,
                    ),

                    // =================================================
                    // STATUS CARD
                    // =================================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        25,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                              0.05,
                            ),
                            blurRadius: 15,
                            offset:
                                const Offset(
                              0,
                              6,
                            ),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [

                          Container(
                            width: 75,
                            height: 75,

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xff00C2CB,
                              ).withOpacity(
                                0.10,
                              ),

                              shape:
                                  BoxShape.circle,
                            ),

                            child: Icon(
                              statusIcon,

                              size: 40,

                              color:
                                  const Color(
                                0xff00AAB3,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          Text(
                            statusTitle,

                            textAlign:
                                TextAlign.center,

                            style:
                                const TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(
                                0xff111827,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            statusMessage,

                            textAlign:
                                TextAlign.center,

                            style:
                                const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    if (status == "PENDING" || status == "REJECTED")
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Submit verification documents",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _licenseNumberController,
                              decoration: InputDecoration(
                                labelText: _licenseNumberLabel,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _documentTypeOptions.contains(
                                _licenseTypeController.text,
                              )
                                  ? _licenseTypeController.text
                                  : _defaultDocumentType,
                              decoration: const InputDecoration(
                                labelText: "Document type for the next upload",
                                border: OutlineInputBorder(),
                              ),
                              items: _documentTypeOptions
                                  .map(
                                    (type) => DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _licenseTypeController.text = value;
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _organizationController,
                              decoration: const InputDecoration(
                                labelText: "Organization name (optional)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _registrationNumberController,
                              decoration: const InputDecoration(
                                labelText: "Registration number (optional)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 4),
                            Text(
                              "Upload PDF, JPG, JPEG, or PNG files up to 10 MB. Upload additional documents one at a time.",
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : _pickAndUploadDocument,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                _isUploading
                                    ? "Uploading…"
                                    : "Choose and upload document",
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documents.isEmpty
                                  ? "No documents uploaded yet."
                                  : "${documents.length} document(s) attached to this application.",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _submitDocuments,
                                child: Text(
                                  _isSubmitting
                                      ? "Submitting…"
                                      : "Submit for verification",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // =================================================
                    // LICENSE
                    // =================================================

                    if (licenseNumber
                        .isNotEmpty)
                      _buildInfoCard(
                        icon:
                            Icons
                                .card_membership_outlined,
                        title:
                            "License Number",
                        value:
                            licenseNumber,
                      ),

                    if (licenseNumber
                        .isNotEmpty)
                      const SizedBox(
                        height: 12,
                      ),

                    // =================================================
                    // ORGANIZATION
                    // =================================================

                    if (organizationName
                        .isNotEmpty)
                      _buildInfoCard(
                        icon:
                            Icons
                                .business_outlined,
                        title:
                            "Organization",
                        value:
                            organizationName,
                      ),

                    if (organizationName
                        .isNotEmpty)
                      const SizedBox(
                        height: 12,
                      ),

                    // =================================================
                    // ADDRESS
                    // =================================================

                    if (address
                        .isNotEmpty)
                      _buildInfoCard(
                        icon:
                            Icons
                                .location_on_outlined,
                        title:
                            "Address",
                        value:
                            address,
                      ),

                    if (address
                        .isNotEmpty)
                      const SizedBox(
                        height: 20,
                      ),

                    // =================================================
                    // DOCUMENTS
                    // =================================================

                    if (documents
                        .isNotEmpty)
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
                              Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Submitted Documents",

                              style:
                                  TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            ...documents.map(
                              (document) {

                                final doc =
                                    Map<String,
                                        dynamic>.from(
                                  document,
                                );

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 10,
                                  ),

                                  child: Row(
                                    children: [

                                      const Icon(
                                        Icons
                                            .description_outlined,
                                        color:
                                            Color(
                                          0xff00AAB3,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 10,
                                      ),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc["fileName"]?.toString().isNotEmpty == true
                                                  ? doc["fileName"].toString()
                                                  : doc["type"]?.toString() ?? "Document",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if ((doc["fileName"]?.toString() ?? "").isNotEmpty)
                                              Text(
                                                doc["type"]?.toString() ?? "Verification document",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      const Icon(
                                        Icons
                                            .check_circle,
                                        size: 20,
                                        color:
                                            Colors.green,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(
                      height: 25,
                    ),

                    // =================================================
                    // REFRESH BUTTON
                    // =================================================

                    SizedBox(
                      width:
                          double.infinity,

                      height: 54,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            loadVerification,

                        icon:
                            const Icon(
                          Icons.refresh,
                        ),

                        label:
                            const Text(
                          "Refresh Status",

                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xff00C2CB,
                          ),

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // LOGOUT BUTTON
                    // =================================================

                    SizedBox(
                      width:
                          double.infinity,

                      height: 54,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            logout,

                        icon:
                            const Icon(
                          Icons.logout,
                        ),

                        label:
                            const Text(
                          "Logout",

                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.red,

                          side:
                              const BorderSide(
                            color:
                                Colors.red,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xffE5E7EB,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 44,
            height: 44,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xff00C2CB,
              ).withOpacity(
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,

              color:
                  const Color(
                0xff00AAB3,
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xff111827,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
