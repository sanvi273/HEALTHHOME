import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  static const Color primaryTeal = Color(0xFF00C2CB);
  static const Color textDark = Color(0xFF101B32);

  bool _isLoading = true;
  String _errorMessage = "";
  List<dynamic> _payments = [];
  String _selectedFilter = "ALL"; // ALL, Doctor, Medicine, Lab

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final res = await ApiService.getPaymentHistory();
      if (!mounted) return;

      if (res["success"] == true) {
        setState(() {
          _payments = res["payments"] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res["message"] ?? "Failed to load payment history.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredPayments {
    if (_selectedFilter == "ALL") return _payments;
    return _payments.where((p) {
      final String sType = (p["serviceType"] ?? "").toString().toLowerCase();
      return sType == _selectedFilter.toLowerCase();
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "SUCCESS":
      case "PAID":
        return const Color(0xFF10B981);
      case "FAILED":
        return Colors.red.shade600;
      case "CANCELLED":
        return Colors.orange.shade700;
      case "PENDING":
      case "CREATED":
      default:
        return Colors.amber.shade800;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case "doctor":
        return Icons.medical_services_rounded;
      case "lab":
      case "laboratory":
        return Icons.science_rounded;
      case "medicine":
      case "pharmacy":
      default:
        return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          "Payment History",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPaymentHistory,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip("All", "ALL"),
                    const SizedBox(width: 8),
                    _filterChip("Doctors", "Doctor"),
                    const SizedBox(width: 8),
                    _filterChip("Medicines", "Medicine"),
                    const SizedBox(width: 8),
                    _filterChip("Lab Tests", "Lab"),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: primaryTeal.withOpacity(0.18),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryTeal : Colors.grey.shade700,
      ),
      side: BorderSide(
        color: isSelected ? primaryTeal : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryTeal),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPaymentHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredPayments;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 12),
            Text(
              "No payments found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Transactions will appear here after booking services.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final serviceType = item["serviceType"] ?? "Service";
        final amount = (item["amount"] as num?)?.toDouble() ?? 0.0;
        final status = (item["paymentStatus"] ?? item["status"] ?? "PENDING").toString();
        final method = item["paymentMethod"] ?? "ONLINE";
        final transId = item["transactionId"] ?? item["orderId"] ?? "N/A";
        final refId = item["referenceId"] ?? "";

        DateTime? date;
        try {
          if (item["createdAt"] != null) {
            date = DateTime.parse(item["createdAt"].toString());
          }
        } catch (_) {}

        final formattedDate = date != null
            ? DateFormat("dd MMM yyyy, hh:mm a").format(date.toLocal())
            : "Recent";

        final statusColor = _getStatusColor(status);

        return Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getServiceIcon(serviceType),
                        color: primaryTeal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$serviceType Payment",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "ID: $transId",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          method,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        if (refId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text("•", style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 8),
                          Text(
                            "#${refId.length > 8 ? refId.substring(0, 8) : refId}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

