import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_screen.dart';
import '../../services/api_service.dart';
import '../../services/incoming_call_service.dart';
import '../payment/payment_history_page.dart';
import '../../widgets/help_support_card.dart';
import '../../widgets/profile_image.dart';
import '../edit_profile_screen.dart';
import 'patient_cart_overview_page.dart';

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
  int medicineCartCount = 0;
  int labTestCartCount = 0;
  List<String> medicineCartPreview = [];
  List<String> labTestCartPreview = [];
  bool isLoadingCartSummary = true;
  bool hasCartSummaryError = false;

  @override
  void initState() {
    super.initState();
    loadData();
    loadCartSummary();
  }

  Future<void> loadCartSummary() async {
    var loadedMedicineCount = 0;
    var loadedLabCount = 0;
    var loadedMedicinePreview = <String>[];
    var loadedLabPreview = <String>[];
    var hadError = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('patientPhone') ??
          prefs.getString('userPhone') ??
          prefs.getString('phone') ??
          '';
      if (phone.trim().isEmpty) {
        hadError = true;
      } else {
        await Future.wait<void>([
          ApiService.getCartItems(phone).then<void>((items) {
            loadedMedicineCount = items.length;
            loadedMedicinePreview = items
                .whereType<Map>()
                .take(2)
                .map((item) =>
                    (item['medicine'] ?? item['medicineName'] ?? 'Medicine')
                        .toString())
                .toList();
          }).catchError((_) {
            hadError = true;
          }),
          ApiService.getMyLabTestCart().then<void>((items) {
            loadedLabCount = items.length;
            loadedLabPreview = items
                .whereType<Map>()
                .take(2)
                .map((item) => (item['testName'] ?? 'Lab test').toString())
                .toList();
          }).catchError((_) {
            hadError = true;
          }),
        ]);
      }
    } catch (_) {
      hadError = true;
    }

    if (!mounted) return;
    setState(() {
      medicineCartCount = loadedMedicineCount;
      labTestCartCount = loadedLabCount;
      medicineCartPreview = loadedMedicinePreview;
      labTestCartPreview = loadedLabPreview;
      hasCartSummaryError = hadError;
      isLoadingCartSummary = false;
    });
  }

  Future<void> openMyCart() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PatientCartOverviewPage(),
      ),
    );
    if (!mounted) return;
    await loadCartSummary();
  }

  Widget myCartCard() {
    return InkWell(
      onTap: openMyCart,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE5EEEE)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xffE8F8F5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xff0D9488),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'myCart'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (isLoadingCartSummary)
                    Text('loadingCart'.tr())
                  else if (hasCartSummaryError)
                    Text(
                      'cartSummaryLoadError'.tr(),
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    )
                  else ...[
                    Text(
                      '$medicineCartCount ${'pharmacyItems'.tr()}  •  '
                      '$labTestCartCount ${'labTestItems'.tr()}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    if (medicineCartPreview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'cartMedicinePreview'.tr(
                          namedArgs: {'items': medicineCartPreview.join(', ')},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                    if (labTestCartPreview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'cartLabPreview'.tr(
                          namedArgs: {'items': labTestCartPreview.join(', ')},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (isLoadingCartSummary)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String userId =
        prefs.getString("userPhone") ?? "";
    final String token = prefs.getString("token") ?? "";

    if (userId.isEmpty || token.isEmpty) return;

    final result = await ApiService.getMyProfile(token: token);

    if (result["success"] == true) {
      final profile = result["profile"];
      if (profile is! Map) return;

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

                  const ProfileImageEditor(
                    accentColor: Color(0xff075F57),
                    backgroundColor: Colors.white,
                    fallbackIcon: Icons.person,
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

            EditProfileButton(
              role: 'patient',
              initialProfile: {
                'name': userName,
                'age': age,
                'gender': gender,
                'bloodGroup': bloodGroup,
                'height': height,
                'weight': weight,
              },
              onProfileUpdated: (profile) async {
                final updatedHeight = profile['height']?.toString() ?? '';
                final updatedWeight = profile['weight']?.toString() ?? '';
                final heightMeters =
                    (double.tryParse(updatedHeight) ?? 0) / 100;
                final weightKg = double.tryParse(updatedWeight) ?? 0;
                final bmiValue = heightMeters > 0 && weightKg > 0
                    ? weightKg / (heightMeters * heightMeters)
                    : 0.0;
                if (!mounted) return;
                setState(() {
                  userName = profile['name']?.toString() ?? userName;
                  age = profile['age']?.toString() ?? '';
                  gender = profile['gender']?.toString() ?? '';
                  bloodGroup = profile['bloodGroup']?.toString() ?? '';
                  height = updatedHeight;
                  weight = updatedWeight;
                  bmi = bmiValue == 0 ? '' : bmiValue.toStringAsFixed(1);
                });
              },
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
                    children: [
                      Expanded(child: healthCard('blood'.tr(), bloodGroup)),
                      const SizedBox(width: 6),
                      Expanded(child: healthCard('height'.tr(), '$height cm')),
                      const SizedBox(width: 6),
                      Expanded(child: healthCard('weight'.tr(), '$weight kg')),
                      const SizedBox(width: 6),
                      Expanded(child: healthCard('bmi'.tr(), bmi)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            myCartCard(),

            const SizedBox(height: 20),

            // =========================================
            // PAYMENT HISTORY
            // =========================================

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff14B8A6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xff14B8A6),
                  ),
                ),
                title: const Text(
                  "Payment History",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  "View past transactions and receipts",
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentHistoryPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            const HelpSupportCard(),

            const SizedBox(height: 30),

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

                  await IncomingCallService.unregisterCurrentDevice();
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
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),

      decoration: BoxDecoration(
        color:
            const Color(0xffF7F8FA),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.isEmpty ? "-" : value,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
