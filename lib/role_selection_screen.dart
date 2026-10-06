import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),

          child: Column(
            children: [

              const SizedBox(height: 4),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                height: 72,
                width: 72,

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.blue.withOpacity(0.10),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),

                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                'welcome'.tr(),

                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // SUBTITLE
              // ==================================================

              Text(
                'chooseYourRole'.tr(),

                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // PATIENT
              // ==================================================

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                        role: "Patient",
                      ),
                    ),
                  );
                },

                child: buildCard(
                  icon: Icons.person,
                  iconColor: Colors.blue,

                  iconBg:
                      const Color(0xffEAF4FF),

                  title:
                      'patient'.tr(),

                  subtitle:
                      'doctorsAndMedicines'.tr(),
                ),
              ),

              // ==================================================
              // DOCTOR
              // ==================================================

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                        role: "Doctor",
                      ),
                    ),
                  );
                },

                child: buildCard(
                  icon:
                      Icons.medical_services,

                  iconColor:
                      Colors.green,

                  iconBg:
                      const Color(0xffEAFBF1),

                  title:
                      'doctor'.tr(),

                  subtitle:
                      'managePatients'.tr(),
                ),
              ),

              // ==================================================
              // LABORATORY
              // ==================================================

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                        role: "Laboratory",
                      ),
                    ),
                  );
                },

                child: buildCard(
                  icon:
                      Icons.science,

                  iconColor:
                      Colors.orange,

                  iconBg:
                      const Color(0xffFFF5E6),

                  title:
                      'laboratory'.tr(),

                  subtitle:
                      'uploadReports'.tr(),
                ),
              ),

              // ==================================================
              // PHARMACY
              // ==================================================

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                        role: "Pharmacy",
                      ),
                    ),
                  );
                },

                child: buildCard(
                  icon:
                      Icons.local_pharmacy,

                  iconColor:
                      Colors.purple,

                  iconBg:
                      const Color(0xffF5EEFF),

                  title:
                      'pharmacy'.tr(),

                  subtitle:
                      'medicineOrders'.tr(),
                ),
              ),

              const Spacer(),

              // ==================================================
              // LANGUAGE BUTTONS
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,

                children: [

                  // =================================================
                  // ENGLISH
                  // =================================================

                  languageButton(
                    title: "English",

                    onTap: () async {
                      await context.setLocale(
                        const Locale('en'),
                      );
                    },
                  ),

                  // =================================================
                  // HINDI
                  // =================================================

                  languageButton(
                    title: "हिंदी",

                    onTap: () async {
                      await context.setLocale(
                        const Locale('hi'),
                      );
                    },
                  ),

                  // =================================================
                  // GUJARATI
                  // =================================================

                  languageButton(
                    title: "ગુજરાતી",

                    onTap: () async {
                      await context.setLocale(
                        const Locale('gu'),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ROLE CARD
  // ============================================================

  Widget buildCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),

            blurRadius: 8,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [

          // ==================================================
          // ICON
          // ==================================================

          Container(
            height: 58,
            width: 58,

            decoration:
                BoxDecoration(
              color: iconBg,

              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 14),

          // ==================================================
          // TEXT
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 3),

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

          // ==================================================
          // ARROW
          // ==================================================

          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE BUTTON
  // ============================================================

  Widget languageButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.03),

              blurRadius: 5,
            ),
          ],
        ),

        child: Text(
          title,

          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}