import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';

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
  String verificationId = "";
  String professionalName = "";
  String licenseNumber = "";
  String organizationName = "";
  String address = "";
  String rejectionReason = "";

  List<dynamic> documents = [];

  @override
  void initState() {
    super.initState();
    loadVerification();
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

          verificationId =
              verification["verificationId"]
                      ?.toString() ??
                  "";

          professionalName =
              verification["professionalName"]
                      ?.toString() ??
                  "";

          licenseNumber =
              verification["licenseNumber"]
                      ?.toString() ??
                  "";

          organizationName =
              verification["organizationName"]
                      ?.toString() ??
                  "";

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

                    // =================================================
                    // VERIFICATION ID
                    // =================================================

                    _buildInfoCard(
                      icon:
                          Icons.badge_outlined,
                      title:
                          "HealthHome Verification ID",
                      value:
                          verificationId.isEmpty
                              ? "Not available"
                              : verificationId,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // PROFESSIONAL NAME
                    // =================================================

                    _buildInfoCard(
                      icon:
                          Icons.person_outline,
                      title:
                          "Professional Name",
                      value:
                          professionalName.isEmpty
                              ? "Not available"
                              : professionalName,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

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
                                        child: Text(
                                          doc["type"]
                                                  ?.toString() ??
                                              "Document",

                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
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