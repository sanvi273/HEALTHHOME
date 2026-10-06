import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'upload_prescription_page.dart';
import 'order_medicines_page.dart';

class PharmacyPage extends StatelessWidget {
  const PharmacyPage({super.key});

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
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(0xff0F172A),

        title: Text(
          "pharmacy".tr(),
          style: TextStyle(
            color: Color(0xff0F172A),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            // SUBTITLE
            // ======================================================

            Text(
              "healthDeliveredToDoor".tr(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================================
            // TOP ACTION CARDS
            // ======================================================

            Row(
              children: [

                // --------------------------------------------------
                // MEDICINE DELIVERY
                // --------------------------------------------------

                Expanded(
                  child: _topCard(
                    title: "medicineDelivery".tr(),
                    subtitle: "orderMedicines".tr(),
                    icon: Icons.local_shipping,
                    color: Colors.green,
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrderMedicinesPage(),
    ),
  );
},
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // --------------------------------------------------
                // UPLOAD PRESCRIPTION
                // --------------------------------------------------

                Expanded(
                  child: _topCard(
                    title: "uploadPrescription".tr(),
                    subtitle: "uploadRx".tr(),
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UploadPrescriptionPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================================
            // OFFER BANNER
            // ======================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xffE8FAFB),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          "flat20Off".tr(),

                          style:
                              TextStyle(
                            fontSize: 24,
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
                          "onYourFirstOrder".tr(),
                          style:
                              TextStyle(
                            fontSize: 15,
                            color:
                                Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.local_pharmacy,
                    size: 70,
                    color: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // WHY CHOOSE HEALTHHOME
            // ======================================================

            Text(
              "whyChooseHealthHome".tr(),

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
                  MainAxisAlignment.spaceBetween,

              children: [

                FeatureItem(
                  Icons.verified,
                  "genuine".tr(),
                ),

                FeatureItem(
                  Icons.delivery_dining,
                  "delivery".tr(),
                ),

                FeatureItem(
                  Icons.refresh,
                  "returns".tr(),
                ),

                FeatureItem(
                  Icons.lock,
                  "secure".tr(),
                ),
              ],
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // TRACK ORDER
            // ======================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xffE8FAFB),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          "trackYourOrder".tr(),

                          style:
                              TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(
                          height: 8,
                        ),

                        Text(
                          "viewMedicineDeliveryStatus".tr(),
                          style:
                              TextStyle(
                            color:
                                Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.delivery_dining,
                    size: 60,
                    color: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ======================================================
            // PRESCRIPTION INFORMATION
            // ======================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(0.04),
                    blurRadius: 8,
                    offset:
                        const Offset(0, 3),
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
                        Icons.medication,
                        color:
                            primaryColor,
                        size: 30,
                      ),

                      SizedBox(
                        width: 10,
                      ),

                      Text(
                        "prescriptionOrders".tr(),

                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 12,
                  ),

                  Text(
                    "orderMedicinesThroughPrescription".tr(),
                    style:
                        TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  Text(
                    "selectPrescribedMedicinesFromMyPrescriptions".tr(),
                    style:
                        TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // TOP CARD
  // ==============================================================

  static Widget _topCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 150,

        padding:
            const EdgeInsets.all(16),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(0.04),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Icon(
              icon,
              size: 40,
              color: color,
            ),

            const Spacer(),

            Text(
              title,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,

              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FEATURE ITEM
// ================================================================

class FeatureItem
    extends StatelessWidget {

  final IconData icon;
  final String title;

  const FeatureItem(
    this.icon,
    this.title, {
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [

        Container(
          width: 55,
          height: 55,

          decoration:
              const BoxDecoration(
            color:
                Color(0xffE8FAFB),
            shape:
                BoxShape.circle,
          ),

          child: Icon(
            icon,
            color:
                const Color(
              0xff00C2CB,
            ),
            size: 27,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        Text(
          title,

          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}