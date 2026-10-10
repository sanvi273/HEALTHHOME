import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'appointments_page.dart';
import 'doctor_list_page.dart';
import 'lab_home_page.dart';
import 'pharmacy_page.dart';
import 'my_prescription_page.dart' as prescription;
import 'profile_page.dart';
import 'reports_page.dart';
import 'medicine_order_page.dart';
import 'lab_orders_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String userName = 'Patient';
  String patientPhone = '';

  static const Color teal = Color(0xFF00B8B8);
  static const Color ink = Color(0xFF101B32);
  static const Color muted = Color(0xFF697789);
  static const Color pageBackground = Color(0xFFF7F9FC);

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userName = prefs.getString('patientName') ?? 'Patient';
      patientPhone = prefs.getString('patientPhone') ?? '';
    });
  }

  void openProfile() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );

  void openDoctors() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorsListPage()),
      );

  void openPharmacy() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PharmacyPage()),
      );

  void openLabTests() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LabHomePage()),
      );

  void openAppointments() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppointmentsPage()),
      );

  void openPrescriptions() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => prescription.MyPrescriptionPage()),
      );

  void openReports() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsPage()),
      );

  void openMedicineOrders() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicineOrdersPage()),
      );

  void openLabOrders() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LabOrdersPage()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // This dashboard is intentionally non-scrollable. The sections
            // share the available height so they remain visible on one screen.
            final height = constraints.maxHeight;
            final horizontalPadding = constraints.maxWidth < 380 ? 14.0 : 18.0;
            final compact = height < 650;
            final gap = compact ? 7.0 : 10.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 5 : 9,
                horizontalPadding,
                compact ? 5 : 9,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: height * (compact ? 0.145 : 0.15),
                    child: _buildHeader(compact),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    flex: 28,
                    child: _buildServiceCards(compact),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    flex: 21,
                    child: _buildDeliveryBanner(compact),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: compact ? 29 : 34,
                    child: _buildQuickAccessHeader(),
                  ),
                  SizedBox(height: gap * 0.55),
                  Expanded(
                    flex: 22,
                    child: _buildQuickAccessGrid(compact),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    final trimmedName = userName.trim();
    final firstName = trimmedName.isEmpty
        ? 'Patient'
        : trimmedName.split(RegExp(r'\s+')).first;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()},',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: teal,
                        fontSize: compact ? 27 : 31,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('👋', style: TextStyle(fontSize: compact ? 22 : 25)),
                ],
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                'Take care of your health today!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: compact ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFFD8F8F7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: openProfile,
            child: SizedBox(
              width: compact ? 46 : 54,
              height: compact ? 46 : 54,
              child: Icon(
                Icons.person_rounded,
                color: ink,
                size: compact ? 25 : 29,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCards(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ServiceCard(
            title: 'Doctor\nConsultation',
            subtitle: 'Book appointments\nwith specialists',
            icon: Icons.medical_services_rounded,
            background: const Color(0xFFE8F2FF),
            iconBackground: const Color(0xFFD5E8FF),
            accent: const Color(0xFF159BD7),
            compact: compact,
            onTap: openDoctors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ServiceCard(
            title: 'Home\nLab Tests',
            subtitle: 'Book tests at\nyour home',
            icon: Icons.science_rounded,
            background: const Color(0xFFE5FAF6),
            iconBackground: const Color(0xFFCFF5EE),
            accent: const Color(0xFF00AFAF),
            compact: compact,
            onTap: openLabTests,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ServiceCard(
            title: 'Medicine\nDelivery',
            subtitle: 'Order medicines\nto your home',
            icon: Icons.medication_rounded,
            background: const Color(0xFFF4EAFF),
            iconBackground: const Color(0xFFEBD9FF),
            accent: const Color(0xFF9451D6),
            compact: compact,
            onTap: openPharmacy,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryBanner(bool compact) {
    return Material(
      color: const Color(0xFFE2F8F4),
      borderRadius: BorderRadius.circular(compact ? 18 : 23),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 18 : 23),
        onTap: openPharmacy,
        child: Padding(
          padding: EdgeInsets.all(compact ? 11 : 14),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAST & SAFE',
                      style: TextStyle(
                        color: teal,
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      'Get Medicines\nDelivered to Your Home',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      'Trusted pharmacies • Genuine medicines • Safe delivery',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: compact ? 9 : 11,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 8),
                    SizedBox(
                      height: compact ? 30 : 35,
                      child: FilledButton(
                        onPressed: openPharmacy,
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 13,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: TextStyle(
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Order Now'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: box.maxHeight * 0.82,
                        height: box.maxHeight * 0.82,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.42),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 0,
                        child: Icon(
                          Icons.location_on_rounded,
                          size: compact ? 22 : 28,
                          color: const Color(0xFF70D8CC),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        right: 0,
                        child: Icon(
                          Icons.medical_services_rounded,
                          size: compact ? 39 : 48,
                          color: const Color(0xFF00AFAF),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          size: compact ? 58 : 72,
                          color: const Color(0xFF008F99),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 2,
                        child: Icon(
                          Icons.add_circle,
                          size: compact ? 17 : 22,
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quick Access',
            maxLines: 1,
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: _showAllQuickAccess,
          style: TextButton.styleFrom(
            foregroundColor: teal,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Icon(Icons.chevron_right_rounded, size: 19),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(bool compact) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  title: 'My\nAppointments',
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF079DD0),
                  iconBackground: const Color(0xFFE1F5FC),
                  compact: compact,
                  onTap: openAppointments,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: _QuickAccessCard(
                  title: 'My\nPrescriptions',
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFFF04470),
                  iconBackground: const Color(0xFFFFE6ED),
                  compact: compact,
                  onTap: openPrescriptions,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: _QuickAccessCard(
                  title: 'Lab Reports',
                  icon: Icons.science_rounded,
                  iconColor: const Color(0xFF9255D8),
                  iconBackground: const Color(0xFFF0E5FF),
                  compact: compact,
                  onTap: openReports,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  title: 'My Medicine Orders',
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFFF0A000),
                  iconBackground: const Color(0xFFFFF0D9),
                  compact: compact,
                  onTap: openMedicineOrders,
                  horizontal: true,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: _QuickAccessCard(
                  title: 'My Lab Orders',
                  icon: Icons.assignment_rounded,
                  iconColor: const Color(0xFF19A66A),
                  iconBackground: const Color(0xFFE0F8EB),
                  compact: compact,
                  onTap: openLabOrders,
                  horizontal: true,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllQuickAccess() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              _SheetLink(
                icon: Icons.calendar_month_rounded,
                title: 'My Appointments',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openAppointments();
                },
              ),
              _SheetLink(
                icon: Icons.description_rounded,
                title: 'My Prescriptions',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openPrescriptions();
                },
              ),
              _SheetLink(
                icon: Icons.science_rounded,
                title: 'Lab Reports',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openReports();
                },
              ),
              _SheetLink(
                icon: Icons.medication_rounded,
                title: 'My Medicine Orders',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openMedicineOrders();
                },
              ),
              _SheetLink(
                icon: Icons.biotech_rounded,
                title: 'My Lab Orders',
                onTap: () {
                  Navigator.pop(sheetContext);
                  openLabOrders();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'goodMorning'.tr();
    if (hour < 17) return 'goodAfternoon'.tr();
    return 'goodEvening'.tr();
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.iconBackground,
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color iconBackground;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(compact ? 18 : 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: Padding(
          padding: EdgeInsets.all(compact ? 9 : 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 39 : 48,
                height: compact ? 39 : 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(compact ? 13 : 16),
                ),
                child: Icon(
                  icon,
                  size: compact ? 24 : 29,
                  color: accent,
                ),
              ),
              SizedBox(height: compact ? 7 : 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF101B32),
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF536276),
                    fontSize: compact ? 9 : 10,
                    height: 1.22,
                  ),
                ),
              ),
              Container(
                width: compact ? 31 : 36,
                height: compact ? 31 : 36,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: compact ? 18 : 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.compact,
    required this.onTap,
    this.horizontal = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool compact;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 15 : 19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 15 : 19),
        child: Container(
          padding: EdgeInsets.all(compact ? 6 : 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 15 : 19),
            border: Border.all(color: const Color(0xFFF0F2F5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14213D).withOpacity(0.035),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: horizontal
              ? Row(
                  children: [
                    Container(
                      width: compact ? 30 : 37,
                      height: compact ? 30 : 37,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: compact ? 19 : 23,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 7),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF101B32),
                          fontSize: compact ? 9 : 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: compact ? 15 : 18,
                      color: const Color(0xFF8A96A6),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: compact ? 32 : 39,
                      height: compact ? 32 : 39,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: compact ? 20 : 24,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF101B32),
                                fontSize: compact ? 9 : 11,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: compact ? 14 : 17,
                            color: const Color(0xFF8A96A6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SheetLink extends StatelessWidget {
  const _SheetLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF00B8B8)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
