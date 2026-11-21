import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'appointments_page.dart';
import 'doctor_list_page.dart';
import 'lab_home_page.dart';
import 'lab_orders_page.dart';
import 'medicine_order_page.dart';
import 'pharmacy_page.dart';
import 'reports_page.dart';

const Color _familyAccent = Color(0xff0D9488);

class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final members = await ApiService.getMyFamilyMembers();
      if (!mounted) return;
      setState(() => _members = members);
    } catch (error) {
      if (!mounted) return;
      setState(
          () => _loadError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMember(Map<String, dynamic> member) async {
    final wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FamilyMemberDetailsPage(member: member),
      ),
    );
    if (mounted) await _loadMembers();
    if (wasDeleted == true && mounted) _showMessage('familyMemberDeleted'.tr());
  }

  Future<void> _addMember() async {
    final member = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => const FamilyMemberFormPage(),
      ),
    );
    if (!mounted || member == null) return;
    await _loadMembers();
    if (mounted) _showMessage('familyMemberAdded'.tr());
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: Text('familyMembers'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        backgroundColor: _familyAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('addFamilyMember'.tr()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _errorView()
              : _members.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _memberCard(_members[index]),
                      ),
                    ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: Colors.black45),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.people_alt_outlined, size: 72, color: _familyAccent),
          const SizedBox(height: 18),
          Text(
            'noFamilyMembers'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'familyMembersSubtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text('addFirstFamilyMember'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final name = member['name']?.toString() ?? '';
    final relationship = member['relationship']?.toString() ?? 'Other';
    final age = _ageFromDate(member['dateOfBirth']);
    final subtitle = [
      _relationshipLabel(relationship),
      if (age != null) '$age ${'memberYears'.tr()}',
      if ((member['bloodGroup']?.toString() ?? '').trim().isNotEmpty)
        member['bloodGroup'].toString(),
    ].join(' • ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffE5EEEE)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xffE8F8F5),
          foregroundColor: _familyAccent,
          child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase()),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openMember(member),
      ),
    );
  }
}

class FamilyMemberDetailsPage extends StatefulWidget {
  const FamilyMemberDetailsPage({super.key, required this.member});

  final Map<String, dynamic> member;

  @override
  State<FamilyMemberDetailsPage> createState() =>
      _FamilyMemberDetailsPageState();
}

class _FamilyMemberDetailsPageState extends State<FamilyMemberDetailsPage> {
  late Map<String, dynamic> _member;
  Map<String, dynamic> _overview = {};
  bool _isLoadingOverview = true;
  String? _overviewError;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(widget.member);
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final overview = await ApiService.getFamilyMemberOverview(
        memberId: _member['_id'].toString(),
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        final refreshed = overview['familyMember'];
        if (refreshed is Map) _member = Map<String, dynamic>.from(refreshed);
        _isLoadingOverview = false;
        _overviewError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _overviewError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingOverview = false;
      });
    }
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) await _loadOverview();
  }

  List<dynamic> _overviewList(String key) =>
      _overview[key] is List ? List<dynamic>.from(_overview[key] as List) : [];

  void _openReports() => _openPage(ReportsPage(familyMember: _member));

  Future<void> _editMember() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => FamilyMemberFormPage(member: _member),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _member = updated);
      await _loadOverview();
    }
  }

  Future<void> _deleteMember() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('deleteFamilyMember'.tr()),
        content: Text('deleteFamilyMemberConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ApiService.deleteFamilyMember(
        memberId: _member['_id'].toString(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _member['name']?.toString() ?? '';
    final age = _ageFromDate(_member['dateOfBirth']);
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: Text(_member['name']?.toString() ?? 'familyMemberDetails'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'edit'.tr(),
            onPressed: _editMember,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'delete'.tr(),
            onPressed: _isDeleting ? null : _deleteMember,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _familyAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  foregroundColor: _familyAccent,
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _relationshipLabel(
                            _member['relationship']?.toString() ?? 'Other'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildActions(),
          const SizedBox(height: 14),
          _buildActivityOverview(),
          const SizedBox(height: 14),
          _detailCard('personalDetails'.tr(), [
            _detailRow('dateOfBirth'.tr(), _dateLabel(_member['dateOfBirth'])),
            _detailRow(
              'age'.tr(),
              age == null ? null : '$age ${'memberYears'.tr()}',
            ),
            _detailRow('gender'.tr(),
                _genderLabel(_member['gender']?.toString() ?? '')),
            _detailRow('phone'.tr(), _member['phone']?.toString()),
            _detailRow('bloodGroup'.tr(), _member['bloodGroup']?.toString()),
            _detailRow('heightCm'.tr(), _numberLabel(_member['height'])),
            _detailRow('weightKg'.tr(), _numberLabel(_member['weight'])),
            _detailRow('address'.tr(), _member['address']?.toString()),
          ]),
          const SizedBox(height: 14),
          _detailCard('healthDetails'.tr(), [
            _detailRow('allergies'.tr(), _member['allergies']?.toString()),
            _detailRow('medicalConditions'.tr(),
                _member['medicalConditions']?.toString()),
            _detailRow('notes'.tr(), _member['notes']?.toString()),
          ]),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('careServices'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(Icons.medical_services_outlined, 'bookAppointment'.tr(),
                    () => _openPage(DoctorsListPage(familyMember: _member))),
                _actionButton(Icons.medication_outlined, 'pharmacy'.tr(),
                    () => _openPage(PharmacyPage(familyMember: _member))),
                _actionButton(Icons.science_outlined, 'labTests'.tr(),
                    () => _openPage(LabHomePage(familyMember: _member))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(foregroundColor: _familyAccent),
      );

  Widget _buildActivityOverview() {
    if (_isLoadingOverview) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_overviewError != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined, color: Colors.red),
          title: Text(_overviewError!),
          trailing: IconButton(
            onPressed: _loadOverview,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    final appointments = _overviewList('appointments');
    final medicines = _overviewList('medicineOrders');
    final labs = _overviewList('labOrders');
    final prescriptions = _overviewList('prescriptions');
    final reportCount = labs.fold<int>(0, (total, raw) {
      if (raw is! Map || raw['reports'] is! List) return total;
      return total + (raw['reports'] as List).length;
    });
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('healthOverview'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _activityTile('myAppointments'.tr(), appointments.length,
                Icons.calendar_month_outlined,
                () => _openPage(AppointmentsPage(familyMember: _member))),
            _activityTile('myMedicineOrders'.tr(), medicines.length,
                Icons.medication_outlined,
                () => _openPage(MedicineOrdersPage(familyMember: _member))),
            _activityTile('labTests'.tr(), labs.length,
                Icons.science_outlined,
                () => _openPage(LabOrdersPage(familyMember: _member))),
            _activityTile('myLabReports'.tr(), reportCount,
                Icons.description_outlined, _openReports),
            _activityTile('myPrescriptions'.tr(), prescriptions.length,
                Icons.receipt_long_outlined,
                () => _openPage(FamilyMemberPrescriptionPage(
                      memberName: _member['name']?.toString() ?? '',
                      prescriptions: prescriptions,
                    ))),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(
    String title,
    int count,
    IconData icon,
    VoidCallback onTap,
  ) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: _familyAccent),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      );

  Widget _detailCard(String title, List<Widget> rows) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String? rawValue) {
    final value = rawValue?.trim().isNotEmpty == true
        ? rawValue!.trim()
        : 'notProvided'.tr();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(title, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SelectableText(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class FamilyMemberPrescriptionPage extends StatelessWidget {
  const FamilyMemberPrescriptionPage({
    super.key,
    required this.memberName,
    required this.prescriptions,
  });

  final String memberName;
  final List<dynamic> prescriptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: Text('$memberName • ${'myPrescriptions'.tr()}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: prescriptions.isEmpty
          ? Center(child: Text('noPrescriptionsFound'.tr()))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final raw = prescriptions[index];
                final prescription = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final medicines = prescription['medicines'] is List
                    ? List<dynamic>.from(prescription['medicines'])
                    : <dynamic>[];
                final tests = prescription['labTests'] is List
                    ? List<dynamic>.from(prescription['labTests'])
                    : <dynamic>[];
                final symptoms = prescription['symptoms'] is List
                    ? List<dynamic>.from(prescription['symptoms'])
                    : <dynamic>[];
                final doctor = prescription['doctorName']?.toString() ?? '';
                final diagnosis = prescription['diagnosis']?.toString() ?? '';
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diagnosis.isEmpty ? 'myPrescriptions'.tr() : diagnosis,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        if (doctor.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(doctor,
                              style: const TextStyle(color: Colors.black54)),
                        ],
                        if (symptoms.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('${'symptoms'.tr()}: ${symptoms.join(', ')}'),
                        ],
                        if (prescription['advice']?.toString().trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 8),
                          Text('${'advice'.tr()}: ${prescription['advice']}'),
                        ],
                        if (medicines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('medicines'.tr(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          ...medicines.map((rawMedicine) {
                            final medicine = rawMedicine is Map
                                ? Map<String, dynamic>.from(rawMedicine)
                                : <String, dynamic>{};
                            final name = medicine['medicine']?.toString() ??
                                medicine['medicineName']?.toString() ??
                                '';
                            final dose = medicine['dose']?.toString() ?? '';
                            final duration =
                                medicine['duration']?.toString() ?? '';
                            final details = [dose, duration]
                                .where((value) => value.trim().isNotEmpty)
                                .join(' • ');
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.medication_outlined,
                                  color: _familyAccent),
                              title: Text(name),
                              subtitle:
                                  details.isEmpty ? null : Text(details),
                            );
                          }),
                        ],
                        if (tests.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('labTests'.tr(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          ...tests.map((rawTest) {
                            final testName = rawTest is Map
                                ? rawTest['testName']?.toString() ?? ''
                                : rawTest.toString();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('• $testName'),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FamilyMemberFormPage extends StatefulWidget {
  const FamilyMemberFormPage({super.key, this.member});

  final Map<String, dynamic>? member;

  @override
  State<FamilyMemberFormPage> createState() => _FamilyMemberFormPageState();
}

class _FamilyMemberFormPageState extends State<FamilyMemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _addressController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _notesController;
  late String _relationship;
  String _gender = '';
  DateTime? _dateOfBirth;
  bool _isSaving = false;

  static const List<String> _relationships = [
    'Mother',
    'Father',
    'Spouse',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Grandparent',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final member = widget.member ?? <String, dynamic>{};
    _nameController =
        TextEditingController(text: member['name']?.toString() ?? '');
    _phoneController =
        TextEditingController(text: member['phone']?.toString() ?? '');
    _bloodGroupController =
        TextEditingController(text: member['bloodGroup']?.toString() ?? '');
    _heightController =
        TextEditingController(text: _numberLabel(member['height']) ?? '');
    _weightController =
        TextEditingController(text: _numberLabel(member['weight']) ?? '');
    _addressController =
        TextEditingController(text: member['address']?.toString() ?? '');
    _allergiesController =
        TextEditingController(text: member['allergies']?.toString() ?? '');
    _conditionsController = TextEditingController(
        text: member['medicalConditions']?.toString() ?? '');
    _notesController =
        TextEditingController(text: member['notes']?.toString() ?? '');
    final relation = member['relationship']?.toString() ?? 'Other';
    _relationship = _relationships.contains(relation) ? relation : 'Other';
    final gender = member['gender']?.toString() ?? '';
    _gender = const ['', 'Male', 'Female', 'Other', 'Prefer not to say']
            .contains(gender)
        ? gender
        : '';
    _dateOfBirth = DateTime.tryParse(member['dateOfBirth']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDateOfBirth() async {
    final today = DateTime.now();
    final initialDate =
        _dateOfBirth ?? DateTime(today.year - 30, today.month, today.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(today.year - 120, today.month, today.day),
      lastDate: today,
    );
    if (date != null && mounted) setState(() => _dateOfBirth = date);
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'relationship': _relationship,
      'dateOfBirth': _dateOfBirth == null
          ? null
          : DateTime.utc(
                  _dateOfBirth!.year, _dateOfBirth!.month, _dateOfBirth!.day)
              .toIso8601String(),
      'gender': _gender,
      'phone': _phoneController.text.trim(),
      'bloodGroup': _bloodGroupController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'address': _addressController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'medicalConditions': _conditionsController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    try {
      final response = widget.member == null
          ? await ApiService.createFamilyMember(member: payload)
          : await ApiService.updateFamilyMember(
              memberId: widget.member!['_id'].toString(),
              member: payload,
            );
      final savedMember = response['member'];
      if (!mounted) return;
      if (savedMember is Map) {
        Navigator.pop(context, Map<String, dynamic>.from(savedMember));
      } else {
        throw Exception('familyMemberSaveFailed'.tr());
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title:
            Text(isEditing ? 'editFamilyMember'.tr() : 'addFamilyMember'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('personalDetails'.tr()),
            _textField(
              controller: _nameController,
              label: 'familyMemberName'.tr(),
              icon: Icons.person_outline,
              requiredField: true,
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: InputDecoration(
                labelText: 'relationship'.tr(),
                prefixIcon: const Icon(Icons.people_outline),
                border: const OutlineInputBorder(),
              ),
              items: _relationships
                  .map((relation) => DropdownMenuItem(
                        value: relation,
                        child: Text(_relationshipLabel(relation)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _relationship = value);
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _chooseDateOfBirth,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'dateOfBirth'.tr(),
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  border: const OutlineInputBorder(),
                ),
                child:
                    Text(_dateLabel(_dateOfBirth) ?? 'selectDateOfBirth'.tr()),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'gender'.tr(),
                prefixIcon: const Icon(Icons.wc_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text('genderNotSet'.tr())),
                DropdownMenuItem(value: 'Male', child: Text('genderMale'.tr())),
                DropdownMenuItem(
                    value: 'Female', child: Text('genderFemale'.tr())),
                DropdownMenuItem(
                    value: 'Other', child: Text('genderOther'.tr())),
                DropdownMenuItem(
                  value: 'Prefer not to say',
                  child: Text('genderPreferNotToSay'.tr()),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value ?? ''),
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _phoneController,
              label: 'phone'.tr(),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 20,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _bloodGroupController,
              label: 'bloodGroup'.tr(),
              icon: Icons.bloodtype_outlined,
              maxLength: 10,
            ),
            const SizedBox(height: 20),
            _sectionTitle('healthDetails'.tr()),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _heightController,
                    label: 'heightCm'.tr(),
                    icon: Icons.height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _weightController,
                    label: 'weightKg'.tr(),
                    icon: Icons.monitor_weight_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _allergiesController,
              label: 'allergies'.tr(),
              icon: Icons.warning_amber_outlined,
              maxLength: 2000,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _conditionsController,
              label: 'medicalConditions'.tr(),
              icon: Icons.medical_information_outlined,
              maxLength: 2000,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _addressController,
              label: 'address'.tr(),
              icon: Icons.location_on_outlined,
              maxLength: 1000,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _textField(
              controller: _notesController,
              label: 'notes'.tr(),
              icon: Icons.notes_outlined,
              maxLength: 2000,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveMember,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label:
                    Text(_isSaving ? 'saving'.tr() : 'saveFamilyMember'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _familyAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool requiredField = false,
    int maxLength = 2000,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: requiredField
          ? (value) =>
              (value?.trim().isNotEmpty ?? false) ? null : 'requiredField'.tr()
          : null,
    );
  }
}

String _relationshipLabel(String relationship) {
  final key = switch (relationship) {
    'Mother' => 'relationMother',
    'Father' => 'relationFather',
    'Spouse' => 'relationSpouse',
    'Son' => 'relationSon',
    'Daughter' => 'relationDaughter',
    'Brother' => 'relationBrother',
    'Sister' => 'relationSister',
    'Grandparent' => 'relationGrandparent',
    _ => 'relationOther',
  };
  return key.tr();
}

String _genderLabel(String gender) {
  if (gender.isEmpty) return 'genderNotSet'.tr();
  return switch (gender) {
    'Male' => 'genderMale'.tr(),
    'Female' => 'genderFemale'.tr(),
    'Other' => 'genderOther'.tr(),
    'Prefer not to say' => 'genderPreferNotToSay'.tr(),
    _ => gender,
  };
}

String? _dateLabel(dynamic value) {
  final date =
      value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String? _numberLabel(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  final number = num.tryParse(value.toString());
  if (number == null) return null;
  return number % 1 == 0 ? number.toInt().toString() : number.toString();
}

int? _ageFromDate(dynamic value) {
  final date =
      value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return null;
  final today = DateTime.now();
  var age = today.year - date.year;
  if (today.month < date.month ||
      (today.month == date.month && today.day < date.day)) {
    age--;
  }
  return age < 0 ? null : age;
}
