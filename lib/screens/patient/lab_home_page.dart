import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'upload_lab_prescription_page.dart';
import 'book_lab_test_page.dart';

class LabHomePage extends StatelessWidget {
  const LabHomePage({super.key});

  static const Color primaryColor =
      Color(0xff00C2CB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

        title: Text(
          "labTests".tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Notification icon removed
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ======================================================
            // TOP ACTION CARDS
            // ======================================================

            Row(
              children: [
                // --------------------------------------------------
                // BOOK LAB TEST
                // --------------------------------------------------

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookLabTestPage(
                            selectedTests: [],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 170,

                    padding:
                        const EdgeInsets.all(18),

                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(0xff00C2CB),
                          Color(0xff24D4BE),
                        ],
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.science,
                          color:
                              Colors.white,
                          size: 42,
                        ),

                        Spacer(),

                        Text(
                          "bookLabTest".tr(),

                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        SizedBox(
                          height: 6,
                        ),

                        Text(
                          "chooseFromHundredsOfTests".tr(),

                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // --------------------------------------------------
                // UPLOAD PRESCRIPTION
                // --------------------------------------------------

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              const UploadLabPrescriptionPage(),
                        ),
                      );
                    },

                    child: Container(
                      height: 170,

                      padding:
                          const EdgeInsets.all(18),

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
                                .withOpacity(0.04),
                            blurRadius: 8,
                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 42,
                            color:
                                primaryColor,
                          ),

                          Spacer(),

                          Text(
                            "uploadPrescription".tr(),

                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          SizedBox(
                            height: 6,
                          ),

                          Text(
                            "quickLabBooking".tr(),

                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // OFFER BANNER
            // ======================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xffDDF8FC),

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child: Row(mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        "flat20Off".tr(),

                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              primaryColor,
                        ),
                      ),

                      SizedBox(
                        height: 8,
                      ),

                      Text(
                        "onYourFirstLabBooking".tr(),
                      ),
                    ],
                  ),

                  Icon(
                    Icons.science,
                    size: 55,
                    color:
                        primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // WHY CHOOSE HEALTHHOME LABS
            // ======================================================

            Text(
              "whyChooseHealthHomeLabs".tr(),

              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

             Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceAround,

              children: [
                _FeatureCard(
                  Icons.verified,
                  "labCertified".tr(),
                ),

                _FeatureCard(
                  Icons.home,
                  "labHome".tr(),
                ),

                _FeatureCard(
                  Icons.schedule,
                  "labFast".tr(),
                ),

                _FeatureCard(
                  Icons.lock,
                  "labSecure".tr(),
                ),
              ],
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // TRACK LAB ORDER
            // ======================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xffDDF8FC),

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child: Row(mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  Expanded(
                    child: Text(
                      "trackYourLabBooking".tr(),

                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.local_hospital,
                    size: 50,
                    color:
                        primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FEATURE CARD
// ================================================================

class _FeatureCard
    extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureCard(
    this.icon,
    this.title,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,

          backgroundColor:
              const Color(
            0xffE8FAFB,
          ),

          child: Icon(
            icon,

            color:
                const Color(
              0xff00C2CB,
            ),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          title,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}