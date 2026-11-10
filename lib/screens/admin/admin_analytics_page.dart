import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  static const Color primary = Color(0xFF00AEB8);
  static const Color ink = Color(0xFF18343B);

  String _period = 'today';
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token')?.trim() ?? '';
      if (token.isEmpty) throw Exception('Your admin session has expired. Log in again.');
      final response = await ApiService.getAdminAnalytics(
        token: token,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _analytics = response;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _metric(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 11),
          Text('$value', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
        ],
      ),
    );
  }

  Widget _serviceCard(String title, String key, IconData icon, Color color) {
    final service = _map(_map(_analytics['services'])[key]);
    final providers = service['providers'] is List ? service['providers'] as List : const [];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFE6EEF0)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
        subtitle: Text('${service['totalCount'] ?? 0} bookings/orders • ${service['paidCount'] ?? 0} paid'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          _moneyRow('Gross collected', service['grossCollected']),
          _moneyRow('Platform fee estimate (${_analytics['feePercentage'] ?? 5}%)', service['platformFeeEstimate']),
          _moneyRow('Provider payable estimate', service['providerPayableEstimate'], emphasized: true),
          const Divider(height: 22),
          if (providers.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No provider activity for this period.'),
            )
          else
            ...providers.map((item) {
              final provider = _map(item);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${provider['providerName'] ?? 'Provider'}'),
                subtitle: Text('${provider['bookingCount'] ?? 0} orders/bookings • ${provider['paidCount'] ?? 0} paid'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(provider['providerPayableEstimate']), style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    Text('estimated payable', style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _moneyRow(String title, dynamic amount, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal))),
          Text(_money(amount), style: TextStyle(fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _map(_analytics['totals']);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      appBar: AppBar(
        title: const Text('Business Analytics', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded, color: ink)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Today')),
                ButtonSegment(value: '7d', label: Text('7 days')),
                ButtonSegment(value: '30d', label: Text('30 days')),
              ],
              selected: {_period},
              onSelectionChanged: (selection) {
                setState(() => _period = selection.first);
                _load();
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator(color: primary)),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _metric('Bookings and orders', totals['totalServiceRecords'] ?? 0, Icons.dashboard_outlined, const Color(0xFF2878B8)),
                  _metric('Paid/collected', totals['paidServiceRecords'] ?? 0, Icons.verified_outlined, const Color(0xFF168653)),
                  _metric('Gross collected', _money(totals['grossCollected']), Icons.payments_outlined, primary),
                  _metric('Provider payable estimate', _money(totals['providerPayableEstimate']), Icons.account_balance_outlined, const Color(0xFF7755AA)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3DEAA)),
                ),
                child: Text(
                  'Payable amounts are estimates using a ${_analytics['feePercentage'] ?? 5}% platform fee. This dashboard does not transfer money or mark settlements paid. The date filter uses booking/order creation dates (${_analytics['timezone'] ?? 'Asia/Kolkata'}); payment totals show each record’s current paid/collected state.',
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              _serviceCard('Doctor appointments', 'doctor', Icons.medical_services_outlined, const Color(0xFF2878B8)),
              _serviceCard('Medicine / Pharmacy orders', 'medicine', Icons.medication_outlined, const Color(0xFF168653)),
              _serviceCard('Laboratory bookings', 'laboratory', Icons.science_outlined, const Color(0xFF7755AA)),
            ],
          ],
        ),
      ),
    );
  }
}
