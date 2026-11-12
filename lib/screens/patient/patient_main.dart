import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'patient_dashboard.dart';
import 'doctor_list_page.dart';
import 'pharmacy_page.dart';
import 'lab_home_page.dart';
import 'profile_page.dart';

class PatientMain extends StatefulWidget {
  const PatientMain({super.key});

  @override
  State<PatientMain> createState() => _PatientMainState();
}

class _PatientMainState extends State<PatientMain> {
  Locale? _patientLocale;

  @override
  void initState() {
    super.initState();
    _loadPatientLanguage();
  }

  Future<void> _loadPatientLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final languageCode =
        prefs.getString('patient_language') ?? 'en';

    if (!mounted) return;

    setState(() {
      _patientLocale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_patientLocale == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xff00C2CB),
          ),
        ),
      );
    }

    return EasyLocalization(
      key: ValueKey(_patientLocale!.languageCode),

      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
      ],

      path: 'lib/l10n',

      fallbackLocale: const Locale('en'),

      startLocale: _patientLocale!,

      // Patient language is saved manually.
      // This prevents EasyLocalization from changing
      // the global application language.
      saveLocale: false,

      child: const _PatientMainContent(),
    );
  }
}

class _PatientMainContent extends StatefulWidget {
  const _PatientMainContent();

  @override
  State<_PatientMainContent> createState() =>
      _PatientMainContentState();
}

class _PatientMainContentState
    extends State<_PatientMainContent> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PatientDashboard(),
    DoctorsListPage(),
    PharmacyPage(),
    LabHomePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        selectedItemColor:
            const Color(0xff00C2CB),

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        onTap: _onItemTapped,

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),

          BottomNavigationBarItem(
            icon: const Icon(
              Icons.medical_services_outlined,
            ),
            label: 'doctor'.tr(),
          ),

          BottomNavigationBarItem(
            icon: const Icon(
              Icons.local_pharmacy_outlined,
            ),
            label: 'pharmacy'.tr(),
          ),

          BottomNavigationBarItem(
            icon: const Icon(
              Icons.science_outlined,
            ),
            label: 'labTests'.tr(),
          ),

          BottomNavigationBarItem(
            icon: const Icon(
              Icons.person_outline,
            ),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }
}