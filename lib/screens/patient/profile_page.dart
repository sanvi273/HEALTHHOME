import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_screen.dart';
import '../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Patient";
  String age = "";
  String gender = "";
  String bloodGroup = "";
  String height = "";
  String weight = "";
  String bmi = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String userId =
        prefs.getString("userPhone") ?? "";

    if (userId.isEmpty) return;

    final result =
        await ApiService.getProfile(userId);

    if (result["success"] == true) {
      final profile = result["profile"];

      double bmiValue = 0;

      if ((profile["height"] ?? "")
              .toString()
              .isNotEmpty &&
          (profile["weight"] ?? "")
              .toString()
              .isNotEmpty) {
        final double h =
            double.parse(profile["height"]) / 100;

        final double w =
            double.parse(profile["weight"]);

        bmiValue = w / (h * h);
      }

      if (!mounted) return;

      setState(() {
        userName = profile["name"] ?? "";
        age = profile["age"] ?? "";
        gender = profile["gender"] ?? "";
        bloodGroup =
            profile["bloodGroup"] ?? "";
        height = profile["height"] ?? "";
        weight = profile["weight"] ?? "";

        bmi = bmiValue == 0
            ? ""
            : bmiValue.toStringAsFixed(1);
      });
    }
  }

  String _currentLanguageName() {
    switch (context.locale.languageCode) {
      case 'hi':
        return 'हिन्दी';

      case 'gu':
        return 'ગુજરાતી';

      default:
        return 'English';
    }
  }

  Future<void> _changeLanguage(
    String languageCode,
    BuildContext dialogContext,
  ) async {
    final newLocale = Locale(languageCode);

    // Changes only the Patient localization.
    await context.setLocale(newLocale);

    // Save Patient language separately.
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'patient_language',
      languageCode,
    );

    if (!mounted) return;

    Navigator.pop(dialogContext);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'selectLanguage'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(
                dialogContext,
                "English",
                "en",
              ),

              _languageOption(
                dialogContext,
                "हिन्दी",
                "hi",
              ),

              _languageOption(
                dialogContext,
                "ગુજરાતી",
                "gu",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext dialogContext,
    String title,
    String languageCode,
  ) {
    final bool isSelected =
        context.locale.languageCode ==
            languageCode;

    return ListTile(
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked
            : Icons.radio_button_off,

        color:
            const Color(0xff14B8A6),
      ),

      title: Text(title),

      onTap: () {
        _changeLanguage(
          languageCode,
          dialogContext,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        centerTitle: true,

        foregroundColor: Colors.black,

        title: Text(
          'myProfile'.tr(),

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // =========================================
            // PROFILE CARD
            // =========================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color:
                    const Color(0xff14B8A6),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  const CircleAvatar(
                    radius: 45,

                    backgroundColor:
                        Colors.white,

                    child: Icon(
                      Icons.person,

                      size: 50,

                      color:
                          Color(0xff14B8A6),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userName,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 24,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceAround,

                    children: [
                      profileInfo(
                        'age'.tr(),
                        age,
                      ),

                      profileInfo(
                        'gender'.tr(),
                        gender,
                      ),

                      profileInfo(
                        'blood'.tr(),
                        bloodGroup,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================================
            // HEALTH OVERVIEW
            // =========================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'healthOverview'.tr(),

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      healthCard(
                        'blood'.tr(),
                        bloodGroup,
                      ),

                      healthCard(
                        'height'.tr(),
                        '$height cm',
                      ),

                      healthCard(
                        'weight'.tr(),
                        '$weight kg',
                      ),

                      healthCard(
                        'bmi'.tr(),
                        bmi,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =========================================
            // LANGUAGE
            // =========================================

            Card(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),

              child: ListTile(
                leading: const Icon(
                  Icons.language,

                  color:
                      Color(0xff14B8A6),
                ),

                title: Text(
                  'language'.tr(),
                ),

                subtitle: Text(
                  _currentLanguageName(),
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,

                  size: 16,
                ),

                onTap:
                    _showLanguageDialog,
              ),
            ),

            // =========================================
            // OTHER OPTIONS
            // =========================================

            buildTile(
              Icons.notifications,
              'notifications'.tr(),
            ),

            buildTile(
              Icons.lock_outline,
              'privacySecurity'.tr(),
            ),

            buildTile(
              Icons.help_outline,
              'helpSupport'.tr(),
            ),

            buildTile(
              Icons.info_outline,
              'aboutHealthHome'.tr(),
            ),

            const SizedBox(height: 25),

            // =========================================
            // LOGOUT
            // =========================================

            SizedBox(
              width: double.infinity,

              height: 55,

              child:
                  ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red.shade50,

                  elevation: 0,
                ),

                onPressed: () async {
                  final prefs =
                      await SharedPreferences
                          .getInstance();

                  await prefs.setBool(
                    "isLoggedIn",
                    false,
                  );

                  await prefs.remove(
                    "token",
                  );

                  await prefs.remove(
                    "userPhone",
                  );

                  await prefs.remove(
                    "userRole",
                  );

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pushAndRemoveUntil(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(
                        role: "patient",
                      ),
                    ),

                    (route) => false,
                  );
                },

                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),

                label: Text(
                  'logout'.tr(),

                  style: const TextStyle(
                    color: Colors.red,

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

  Widget profileInfo(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,

          style: const TextStyle(
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value.isEmpty ? "-" : value,

          style: const TextStyle(
            color: Colors.white,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget healthCard(
    String title,
    String value,
  ) {
    return Container(
      width: 70,

      padding:
          const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color:
            const Color(0xffF7F8FA),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Column(
        children: [
          Text(title),

          const SizedBox(height: 5),

          Text(
            value.isEmpty ? "-" : value,

            textAlign:
                TextAlign.center,

            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTile(
    IconData icon,
    String title,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        leading: Icon(
          icon,

          color:
              const Color(0xff14B8A6),
        ),

        title: Text(title),

        trailing: const Icon(
          Icons.arrow_forward_ios,

          size: 16,
        ),
      ),
    );
  }
}