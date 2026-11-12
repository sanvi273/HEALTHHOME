import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'login_screen.dart';
import 'terms_acceptance_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 600
        ? 18.0
        : screenWidth < 1100
            ? 32.0
            : 48.0;

    final cardSpacing = screenWidth < 600 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),

                      // LOGO
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.10),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/images/app_icon.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TITLE
                      Text(
                        'welcome'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // SUBTITLE
                      Text(
                        'chooseYourRole'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // PATIENT
                      _roleCard(
                        context,
                        icon: Icons.person,
                        iconColor: Colors.blue,
                        iconBg: const Color(0xffEAF4FF),
                        title: 'patient'.tr(),
                        subtitle: 'doctorsAndMedicines'.tr(),
                        role: 'Patient',
                        spacing: cardSpacing,
                      ),

                      // DOCTOR
                      _roleCard(
                        context,
                        icon: Icons.medical_services,
                        iconColor: Colors.green,
                        iconBg: const Color(0xffEAFBF1),
                        title: 'doctor'.tr(),
                        subtitle: 'managePatients'.tr(),
                        role: 'Doctor',
                        spacing: cardSpacing,
                      ),

                      // LABORATORY
                      _roleCard(
                        context,
                        icon: Icons.science,
                        iconColor: Colors.orange,
                        iconBg: const Color(0xffFFF5E6),
                        title: 'laboratory'.tr(),
                        subtitle: 'uploadReports'.tr(),
                        role: 'Laboratory',
                        spacing: cardSpacing,
                      ),

                      // PHARMACY
                      _roleCard(
                        context,
                        icon: Icons.local_pharmacy,
                        iconColor: Colors.purple,
                        iconBg: const Color(0xffF5EEFF),
                        title: 'pharmacy'.tr(),
                        subtitle: 'medicineOrders'.tr(),
                        role: 'Pharmacy',
                        spacing: cardSpacing,
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(role: 'Admin'),
                          ),
                        ),
                        child: const Text('Administrator sign in'),
                      ),

                      // LANGUAGE BUTTONS
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _languageButton(
                            context,
                            "English",
                            const Locale('en'),
                          ),
                          _languageButton(
                            context,
                            "हिंदी",
                            const Locale('hi'),
                          ),
                          _languageButton(
                            context,
                            "ગુજરાતી",
                            const Locale('gu'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ROLE CARD
  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String role,
    required double spacing,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: ValueKey('role-selection-${role.toLowerCase()}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TermsAcceptanceScreen(
                  selectedRole: role.toLowerCase(),
                  roleLabel: role,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(width < 600 ? 14 : 18),
            child: Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LANGUAGE BUTTON
  Widget _languageButton(
    BuildContext context,
    String title,
    Locale locale,
  ) {
    return GestureDetector(
      onTap: () async {
        await context.setLocale(locale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
