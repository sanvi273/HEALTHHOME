import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'book_lab_test_page.dart';
import 'my_cart_page.dart';

class PatientCartOverviewPage extends StatefulWidget {
  const PatientCartOverviewPage({super.key});

  @override
  State<PatientCartOverviewPage> createState() =>
      _PatientCartOverviewPageState();
}

class _PatientCartOverviewPageState extends State<PatientCartOverviewPage> {
  static const _accent = Color(0xff14B8A6);

  bool _isLoading = true;
  bool _isRemovingTest = false;
  String _patientPhone = '';
  String? _medicineError;
  String? _labError;
  List<Map<String, dynamic>> _medicineItems = [];
  List<Map<String, dynamic>> _labItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _patientPhone = prefs.getString('patientPhone') ??
          prefs.getString('userPhone') ??
          prefs.getString('phone') ??
          '';
      if (_patientPhone.trim().isEmpty) {
        throw Exception('Patient phone number was not found. Please sign in again.');
      }

      _medicineError = null;
      _labError = null;
      final medicineFuture = ApiService.getCartItems(_patientPhone).then((items) {
        _medicineItems = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }).catchError((error) {
        _medicineError = error.toString();
        _medicineItems = [];
      });
      final labFuture = ApiService.getMyLabTestCart().then((items) {
        _labItems = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }).catchError((error) {
        _labError = error.toString();
        _labItems = [];
      });
      await Future.wait([medicineFuture, labFuture]);
    } catch (error) {
      _medicineError = error.toString();
      _labError = error.toString();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, List<Map<String, dynamic>>> get _labGroups {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in _labItems) {
      final labId = item['labId']?.toString() ?? '';
      final key = labId.isEmpty ? (item['labName']?.toString() ?? 'lab') : labId;
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  Future<void> _openPharmacyCart() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MyCartPage()),
    );
    await _loadCart();
  }

  Future<void> _bookLabGroup(
    String labId,
    List<Map<String, dynamic>> items,
  ) async {
    final tests = items
        .map((item) => item['testName']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();
    if (tests.isEmpty || labId.isEmpty) return;

    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookLabTestPage(
          selectedTests: tests,
          preferredLabId: labId,
        ),
      ),
    );
    if (booked != true) {
      await _loadCart();
      return;
    }

    if (!mounted) return;
    setState(() => _isRemovingTest = true);
    try {
      for (final item in items) {
        final id = item['_id']?.toString() ?? '';
        if (id.isNotEmpty) await ApiService.removeLabTestFromCart(id);
      }
    } catch (error) {
      _showMessage(
        'Booking succeeded, but some tests could not be removed from the cart: $error',
        isError: true,
      );
    }
    if (!mounted) return;
    setState(() => _isRemovingTest = false);
    await _loadCart();
  }

  Future<void> _removeLabItem(Map<String, dynamic> item) async {
    final id = item['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _isRemovingTest = true);
    try {
      await ApiService.removeLabTestFromCart(id);
      _labItems.removeWhere((entry) => entry['_id']?.toString() == id);
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isRemovingTest = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
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
        title: Text('myCart'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              onRefresh: _loadCart,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _pharmacyCartSection(),
                  const SizedBox(height: 16),
                  _labCartSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard() {
    final itemCount = _medicineItems.length + _labItems.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14B8A6), Color(0xff0F766E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} ${'inYourCart'.tr()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_medicineItems.length} ${'pharmacyItems'.tr()} • '
                  '${_labItems.length} ${'labTestItems'.tr()}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _pharmacyCartSection() {
    final children = <Widget>[];
    if (_medicineError != null) {
      children.add(_errorMessage());
    } else if (_medicineItems.isEmpty) {
      children.add(_emptyMessage('noPharmacyItemsInCart'.tr()));
    } else {
      for (final item in _medicineItems.take(4)) {
        final name = item['medicine']?.toString() ??
            item['medicineName']?.toString() ??
            'Medicine';
        final quantity = item['quantity']?.toString() ?? '1';
        final amount = item['subtotal']?.toString() ?? item['price']?.toString() ?? '';
        children.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xffE7F8F4),
              child: Icon(Icons.medication_outlined, color: _accent),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('cartQuantityValue'.tr(namedArgs: {'quantity': quantity})),
            trailing: amount.isEmpty ? null : Text('₹$amount'),
          ),
        );
      }
      if (_medicineItems.length > 4) {
        children.add(
          _emptyMessage(
            'moreMedicinesInCart'.tr(
              namedArgs: {'count': '${_medicineItems.length - 4}'},
            ),
          ),
        );
      }
    }
    children.add(const SizedBox(height: 8));
    children.add(
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _medicineError == null ? _openPharmacyCart : _loadCart,
          icon: const Icon(Icons.open_in_new),
          label: Text(
            _medicineError == null ? 'managePharmacyCart'.tr() : 'retry'.tr(),
          ),
          style: OutlinedButton.styleFrom(foregroundColor: _accent),
        ),
      ),
    );
    return _sectionCard(
      title: 'pharmacyCartItems'.tr(
        namedArgs: {'count': '${_medicineItems.length}'},
      ),
      subtitle: 'savedMedicineCartSubtitle'.tr(),
      icon: Icons.local_pharmacy_outlined,
      children: children,
    );
  }

  Widget _labCartSection() {
    final children = <Widget>[];
    if (_labError != null) {
      children.add(_errorMessage());
    } else if (_labItems.isEmpty) {
      children.add(_emptyMessage('noLabTestsInCart'.tr()));
    } else {
      for (final entry in _labGroups.entries) {
        final items = entry.value;
        final labName = items.first['labName']?.toString() ?? 'Laboratory';
        final labId = items.first['labId']?.toString() ?? '';
        final groupTotal = items.fold<double>(
          0,
          (total, item) => total + (double.tryParse(item['price']?.toString() ?? '') ?? 0),
        );
        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF7FAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffE6EEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_outlined, color: _accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        labName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('₹${groupTotal.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['testName']?.toString() ?? 'Lab test'),
                    subtitle: Text('₹${item['price'] ?? 0}'),
                    trailing: IconButton(
                      tooltip: 'removeLabTestFromCart'.tr(),
                      onPressed: _isRemovingTest ? null : () => _removeLabItem(item),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRemovingTest ? null : () => _bookLabGroup(labId, items),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('continueLabBooking'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return _sectionCard(
      title: 'labCartTests'.tr(namedArgs: {'count': '${_labItems.length}'}),
      subtitle: 'savedLabCartSubtitle'.tr(),
      icon: Icons.biotech_outlined,
      children: children,
    );
  }

  Widget _emptyMessage(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      );

  Widget _errorMessage() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'cartSectionLoadError'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
      );
}
