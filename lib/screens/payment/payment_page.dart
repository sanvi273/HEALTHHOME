import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../patient/appointments_page.dart';
import '../patient/lab_orders_page.dart';
import '../patient/medicine_order_page.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String userId;
  final String userName;
  final String userPhone;
  final String serviceType;
  final String serviceId;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.serviceType,
    required this.serviceId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum _PaymentViewStatus {
  idle,
  loading,
  processingVerification,
  success,
  failed,
}

class _PaymentPageState extends State<PaymentPage> {
  // Theme Color
  static const Color primaryTeal = Color(0xFF00C2CB);

  late final Razorpay _razorpay;

  _PaymentViewStatus _viewStatus = _PaymentViewStatus.idle;

  // Selected payment method preference: 'UPI' or 'NETBANKING'
  String _selectedMethod = "UPI";

  // Data received from server
  double _serverAmount = 0.0;
  String _razorpayOrderId = "";
  String _razorpayPaymentId = "";
  String _confirmedPaymentMethod = "";
  String _failureMessage = "";
  DateTime? _paymentTime;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint("================================");
    debugPrint("HEALTHHOME PAYMENT INITIALIZED");
    debugPrint("SERVICE: ${widget.serviceType} | ID: ${widget.serviceId}");
    debugPrint("USER: ${widget.userName} (${widget.userPhone})");
    debugPrint("AMOUNT: ₹${widget.amount}");
    debugPrint("================================");
  }

  @override
  void dispose() {
    try {
      _razorpay.clear();
    } catch (e) {
      debugPrint("Razorpay cleanup error: $e");
    }
    super.dispose();
  }

  String get _paymentTitle {
    switch (widget.serviceType.toLowerCase()) {
      case "doctor":
        return "Doctor Appointment";
      case "lab":
      case "laboratory":
        return "Lab Test Booking";
      case "medicine":
      case "pharmacy":
      default:
        return "Medicine Order";
    }
  }

  String get _paymentSubtitle {
    switch (widget.serviceType.toLowerCase()) {
      case "doctor":
        return "Consultation fee";
      case "lab":
      case "laboratory":
        return "Diagnostic test fee";
      case "medicine":
      case "pharmacy":
      default:
        return "Prescription / Medicine order";
    }
  }

  IconData get _serviceIcon {
    switch (widget.serviceType.toLowerCase()) {
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

  // ============================================================
  // INITIATE PAYMENT FLOW
  // ============================================================

  Future<void> _startPayment() async {
    if (_viewStatus == _PaymentViewStatus.loading ||
        _viewStatus == _PaymentViewStatus.processingVerification) {
      return;
    }

    if (widget.serviceId.trim().isEmpty) {
      _showToast("Booking or order reference is missing.", isError: true);
      return;
    }

    setState(() {
      _viewStatus = _PaymentViewStatus.loading;
      _failureMessage = "";
    });

    try {
      // 1. Create Razorpay order securely on Node.js backend
      final data = await ApiService.createPaymentOrder(
        userId: widget.userId,
        userName: widget.userName,
        userPhone: widget.userPhone,
        serviceType: widget.serviceType,
        serviceId: widget.serviceId,
      );

      if (data["success"] != true) {
        throw Exception(data["message"] ?? "Failed to create payment order.");
      }

      final dynamic orderData = data["order"];
      if (orderData == null || orderData is! Map) {
        throw Exception("Invalid payment order returned by server.");
      }

      final String razorpayOrderId = orderData["id"]?.toString().trim() ?? "";
      final dynamic rawAmount = orderData["amount"];
      final String razorpayKey = data["key"]?.toString().trim() ?? "";
      final String currency = orderData["currency"]?.toString().trim() ?? "INR";

      if (razorpayOrderId.isEmpty) {
        throw Exception("Razorpay Order ID was not returned by server.");
      }
      if (razorpayKey.isEmpty) {
        throw Exception("Razorpay Key was not configured on the server.");
      }

      final int amountInPaise = (rawAmount is int)
          ? rawAmount
          : (rawAmount is num)
              ? rawAmount.toInt()
              : (int.tryParse(rawAmount?.toString() ?? "") ?? 0);

      if (amountInPaise <= 0) {
        throw Exception("Invalid order amount calculated by server.");
      }

      final double serverAmount = amountInPaise / 100.0;
      _razorpayOrderId = razorpayOrderId;
      _serverAmount = serverAmount;

      final preferences = await SharedPreferences.getInstance();
      final email = (preferences.getString("email") ??
              preferences.getString("userEmail") ??
              "")
          .trim();

      if (!mounted) return;
      setState(() {
        _viewStatus = _PaymentViewStatus.idle;
      });

      // 2. Open Official Razorpay Checkout SDK
      // Both UPI and Net Banking are supported natively without restrictions.
      final Map<String, dynamic> options = {
        "key": razorpayKey,
        "amount": amountInPaise,
        "name": "HealthHome",
        "description": "$_paymentTitle (#${widget.serviceId.substring(0, widget.serviceId.length > 8 ? 8 : widget.serviceId.length)})",
        "order_id": razorpayOrderId,
        "currency": currency,
        "prefill": {
          "contact": widget.userPhone,
          "name": widget.userName,
          if (email.isNotEmpty) "email": email,
        },
        // Razorpay uses this to preselect UPI or Netbanking. Both methods
        // remain available in Checkout according to the merchant settings.
        "method": _selectedMethod.toLowerCase(),
        "theme": {
          "color": "#00C2CB",
        },
        "notes": {
          "serviceType": widget.serviceType,
          "serviceId": widget.serviceId,
          "preferredMethod": _selectedMethod,
        },
      };

      debugPrint("OPENING RAZORPAY CHECKOUT: $options");
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewStatus = _PaymentViewStatus.failed;
        _failureMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  // ============================================================
  // RAZORPAY CALLBACKS
  // ============================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("================================");
    debugPrint("RAZORPAY PAYMENT SUCCESS CALLBACK");
    debugPrint("ORDER ID = ${response.orderId}");
    debugPrint("PAYMENT ID = ${response.paymentId}");
    debugPrint("SIGNATURE = ${response.signature != null}");
    debugPrint("================================");

    final String orderId = response.orderId?.toString().trim() ?? "";
    final String paymentId = response.paymentId?.toString().trim() ?? "";
    final String signature = response.signature?.toString().trim() ?? "";

    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      setState(() {
        _viewStatus = _PaymentViewStatus.failed;
        _failureMessage = "Razorpay returned incomplete payment credentials.";
      });
      return;
    }

    setState(() {
      _viewStatus = _PaymentViewStatus.processingVerification;
      _razorpayPaymentId = paymentId;
    });

    try {
      // 3. Verify Razorpay signature & status on the Backend
      final Map<String, dynamic> verifyResult;
      if (widget.serviceType.toLowerCase() == "doctor") {
        verifyResult = await ApiService.verifyDoctorPayment(
          appointmentId: widget.serviceId,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
          patientPhone: widget.userPhone,
        );
      } else {
        verifyResult = await ApiService.verifyPayment(
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: signature,
          serviceType: widget.serviceType,
          serviceId: widget.serviceId,
        );
      }

      if (verifyResult["success"] != true &&
          verifyResult["paid"] != true &&
          verifyResult["paymentVerified"] != true) {
        throw Exception(
          verifyResult["message"] ?? "Server-side payment verification failed.",
        );
      }

      final String method = verifyResult["paymentMethod"]?.toString() ??
          verifyResult["payment"]?["paymentMethod"]?.toString() ??
          _selectedMethod;

      if (!mounted) return;
      setState(() {
        _viewStatus = _PaymentViewStatus.success;
        _confirmedPaymentMethod = method;
        _paymentTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewStatus = _PaymentViewStatus.failed;
        _failureMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("RAZORPAY PAYMENT FAILED: code=${response.code}, msg=${response.message}");
    if (!mounted) return;

    final String msg = response.message?.trim().isNotEmpty == true
        ? response.message!
        : "Payment was cancelled or could not be completed.";

    setState(() {
      _viewStatus = _PaymentViewStatus.failed;
      _failureMessage = msg;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("RAZORPAY EXTERNAL WALLET: ${response.walletName}");
    _showToast("Redirecting to ${response.walletName ?? 'external wallet'}...");
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // NAVIGATION HANDLERS
  // ============================================================

  void _navigateToServiceOrder() {
    switch (widget.serviceType.toLowerCase()) {
      case "doctor":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppointmentsPage()),
        );
        break;
      case "lab":
      case "laboratory":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LabOrdersPage()),
        );
        break;
      case "medicine":
      case "pharmacy":
      default:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MedicineOrdersPage()),
        );
        break;
    }
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_viewStatus == _PaymentViewStatus.success) {
          Navigator.of(context).pop(true);
          return false;
        }
        if (_viewStatus == _PaymentViewStatus.loading ||
            _viewStatus == _PaymentViewStatus.processingVerification) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF101B32)),
          title: Text(
            _viewStatus == _PaymentViewStatus.success
                ? "Payment Successful"
                : _viewStatus == _PaymentViewStatus.failed
                    ? "Payment Failed"
                    : "Complete Payment",
            style: const TextStyle(
              color: Color(0xFF101B32),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (_viewStatus == _PaymentViewStatus.success) {
                Navigator.of(context).pop(true);
              } else if (_viewStatus != _PaymentViewStatus.loading &&
                  _viewStatus != _PaymentViewStatus.processingVerification) {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewStatus) {
      case _PaymentViewStatus.processingVerification:
        return _buildProcessingVerificationView();
      case _PaymentViewStatus.success:
        return _buildSuccessView();
      case _PaymentViewStatus.failed:
        return _buildFailedView();
      case _PaymentViewStatus.loading:
      case _PaymentViewStatus.idle:
      default:
        return _buildCheckoutView();
    }
  }

  // ============================================================
  // 1. CHECKOUT VIEW (Summary + UPI / Net Banking)
  // ============================================================

  Widget _buildCheckoutView() {
    final double displayAmount =
        _serverAmount > 0 ? _serverAmount : widget.amount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Summary Card
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _serviceIcon,
                          color: primaryTeal,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _paymentTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF101B32),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _paymentSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reference ID",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "#${widget.serviceId}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101B32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Patient Name",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101B32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Payable Amount",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF101B32),
                        ),
                      ),
                      Text(
                        "₹${displayAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment Options Heading
          const Text(
            "Choose Your Payment Method",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101B32),
            ),
          ),
          const SizedBox(height: 12),

          // OPTION 1: UPI
          _buildPaymentMethodTile(
            methodKey: "UPI",
            title: "UPI",
            subtitle: "Google Pay, PhonePe, Paytm, BHIM, UPI Intent & QR",
            icon: Icons.account_balance_wallet_rounded,
          ),

          const SizedBox(height: 12),

          // OPTION 2: Net Banking
          _buildPaymentMethodTile(
            methodKey: "NETBANKING",
            title: "Net Banking",
            subtitle: "SBI, HDFC, ICICI, Axis, Kotak & all supported Indian banks",
            icon: Icons.account_balance_rounded,
          ),

          const SizedBox(height: 24),

          // Security Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryTeal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "100% Secure 256-Bit Razorpay Payment Gateway. Server-verified transactions.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Pay Now Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _viewStatus == _PaymentViewStatus.loading
                  ? null
                  : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _viewStatus == _PaymentViewStatus.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Pay ₹${displayAmount.toStringAsFixed(2)} Now",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            "You will be securely redirected to official Razorpay Checkout.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String methodKey,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedMethod == methodKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = methodKey;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryTeal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryTeal.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryTeal : Colors.grey.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryTeal : const Color(0xFF101B32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? primaryTeal : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 2. PROCESSING VERIFICATION VIEW
  // ============================================================

  Widget _buildProcessingVerificationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: primaryTeal,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Verifying Payment...",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF101B32),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Securing your transaction with the HealthHome server and Razorpay.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 3. SUCCESS VIEW
  // ============================================================

  Widget _buildSuccessView() {
    final double displayAmount =
        _serverAmount > 0 ? _serverAmount : widget.amount;
    final dateStr = _paymentTime != null
        ? DateFormat("dd MMM yyyy, hh:mm a").format(_paymentTime!)
        : DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              "Payment Successful!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101B32),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              "Your transaction has been verified and confirmed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Receipt Card
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _receiptRow("Service", _paymentTitle),
                  const Divider(height: 22),
                  _receiptRow("Booking / Order ID", "#${widget.serviceId}"),
                  const Divider(height: 22),
                  _receiptRow("Razorpay Payment ID", _razorpayPaymentId.isNotEmpty ? _razorpayPaymentId : "Verified"),
                  const Divider(height: 22),
                  _receiptRow("Payment Method", _confirmedPaymentMethod.isNotEmpty ? _confirmedPaymentMethod : _selectedMethod),
                  const Divider(height: 22),
                  _receiptRow("Date & Time", dateStr),
                  const Divider(height: 22),
                  _receiptRow(
                    "Amount Paid",
                    "₹${displayAmount.toStringAsFixed(2)}",
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Primary View Order Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _navigateToServiceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "View ${_paymentTitle.replaceAll(' Booking', '').replaceAll(' Order', '')}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Return Home
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF101B32),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              "Done",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? primaryTeal : const Color(0xFF101B32),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 4. FAILED / CANCELLED VIEW
  // ============================================================

  Widget _buildFailedView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade600,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Payment Unsuccessful",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101B32),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _failureMessage.isNotEmpty
                ? _failureMessage
                : "The transaction could not be completed. Your order has not been charged.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),

          // Retry Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _viewStatus = _PaymentViewStatus.idle;
                });
                _startPayment();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Retry Payment",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel / Back Button
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }
}
