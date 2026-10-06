import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';

class LabOrderTrackingPage extends StatefulWidget {
  final String orderId;
  final String labName;

  const LabOrderTrackingPage({
    super.key,
    required this.orderId,
    required this.labName,
  });

  @override
  State<LabOrderTrackingPage> createState() =>
      _LabOrderTrackingPageState();
}

class _LabOrderTrackingPageState
    extends State<LabOrderTrackingPage> {
  static const Color primary = Color(0xff00C2CB);

  bool isLoading = true;
  Map<String, dynamic> order = {};

  @override
  void initState() {
    super.initState();
    loadOrder();
  }

  Future<void> loadOrder() async {
    try {
      final result =
          await ApiService.getLabOrderById(widget.orderId);

      if (!mounted) return;

      setState(() {
        order = result["order"] is Map
            ? Map<String, dynamic>.from(result["order"])
            : result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("LAB TRACKING ERROR = $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to load lab order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> refreshOrder() async {
    setState(() {
      isLoading = true;
    });

    await loadOrder();
  }

  String get currentStatus {
    return order["status"]?.toString() ?? "Pending";
  }

  String get collectionMode {
    return order["collectionMode"]?.toString() ??
        "homeCollection".tr();
  }

  bool get isHomeCollection =>
      collectionMode == "homeCollection".tr();

  List<String> get statuses {
    if (isHomeCollection) {
      return [
        "Pending",
        "accepted".tr(),
        "Collector Assigned",
        "On The Way",
        "Sample Collected",
        "Sample Received",
        "In Progress",
        "Completed",
      ];
    }

    return [
      "Pending",
      "accepted".tr(),
      "Sample Received",
      "In Progress",
      "Completed",
    ];
  }

  int get currentIndex {
    final index = statuses.indexWhere(
      (status) =>
          status.toLowerCase() ==
          currentStatus.toLowerCase(),
    );

    return index;
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;

      case "in progress":
        return Colors.blue;

      case "sample received":
        return Colors.indigo;

      case "sample collected":
        return Colors.teal;

      case "on the way":
        return Colors.orange;

      case "collector assigned":
        return Colors.deepOrange;

      case "accepted":
        return Colors.teal;

      case "rejected":
        return Colors.red;

      case "pending":
      default:
        return Colors.grey;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Icons.hourglass_empty;

      case "accepted":
        return Icons.check_circle_outline;

      case "collector assigned":
        return Icons.person_pin_circle_outlined;

      case "on the way":
        return Icons.directions_car_outlined;

      case "sample collected":
        return Icons.bloodtype_outlined;

      case "sample received":
        return Icons.inventory_2_outlined;

      case "in progress":
        return Icons.biotech_outlined;

      case "completed":
        return Icons.task_alt;

      case "rejected":
        return Icons.cancel_outlined;

      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "labOrderTracking".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: refreshOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: refreshOrder,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  _orderHeader(),

                  const SizedBox(height: 18),

                  if (currentStatus.toLowerCase() ==
                      "rejected")
                    _rejectedCard()
                  else
                    _trackingCard(),

                  const SizedBox(height: 18),

                  _orderDetails(),

                  const SizedBox(height: 18),

                  if (currentStatus.toLowerCase() ==
                      "completed")
                    _completedCard(),
                ],
              ),
            ),
    );
  }

  Widget _orderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              color: primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.labName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Order ID: ${widget.orderId}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(currentStatus)
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStatus,
                    style: TextStyle(
                      color: statusColor(currentStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            "orderStatus".tr(),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isHomeCollection
                ? "homeCollection".tr()
                : "visitLaboratory".tr(),
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 25),

          ...List.generate(
            statuses.length,
            (index) {
              final status = statuses[index];

              final completed =
                  currentIndex >= index &&
                  currentIndex >= 0;

              final active =
                  currentIndex == index;

              return _timelineItem(
                status: status,
                completed: completed,
                active: active,
                isLast:
                    index == statuses.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required String status,
    required bool completed,
    required bool active,
    required bool isLast,
  }) {
    final color =
        completed ? primary : Colors.grey.shade300;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: completed
                    ? primary.withOpacity(0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: active ? 2.5 : 1.5,
                ),
              ),
              child: Icon(
                statusIcon(status),
                color: color,
                size: 22,
              ),
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: color,
              ),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ||
                            completed
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: active
                        ? primary
                        : completed
                            ? Colors.black87
                            : Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _statusDescription(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: completed
                        ? Colors.black54
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusDescription(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "waitingForLabReview".tr();

      case "accepted":
        return "labAcceptedBooking".tr();

      case "collector assigned":
        return "collectorAssignedMessage".tr();

      case "on the way":
        return "collectorOnTheWay".tr();

      case "sample collected":
        return "sampleCollectedMessage".tr();

      case "sample received":
        return "sampleReceivedMessage".tr();

      case "in progress":
        return "testsInProgressMessage".tr();

      case "completed":
        return "labReportReady".tr();

      default:
        return "";
    }
  }

  Widget _orderDetails() {
    final tests = order["tests"];

    final address =
        order["address"]?.toString() ?? "";

    final bookingType =
        order["bookingType"]?.toString() ?? "test".tr();

    final totalAmount =
        order["totalAmount"]?.toString() ?? "0";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            "orderDetails".tr(),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _detailRow(
            Icons.science_outlined,
            "bookingType".tr(),
            bookingType == "PRESCRIPTION"
                ? "prescription".tr()
                : "labTest".tr(),
          ),

          _detailRow(
            Icons.home_outlined,
            "collection".tr(),
            collectionMode,
          ),

          if (address.isNotEmpty)
            _detailRow(
              Icons.location_on_outlined,
              "address".tr(),
              address,
            ),

          _detailRow(
            Icons.currency_rupee,
            "amount".tr(),
            "₹$totalAmount",
          ),

          if (tests is List && tests.isNotEmpty)
            _testsSection(tests),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primary,
            size: 21,
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testsSection(List tests) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Divider(),

        const SizedBox(height: 10),

        Text(
          "selectedTests".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 10),

        ...tests.map(
          (test) => Padding(
            padding:
                const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: primary,
                  size: 17,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    test is Map
                        ? test["testName"]
                                ?.toString() ??
                            test["name"]
                                ?.toString() ??
                            "Test"
                        : test.toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rejectedCard() {
    final reason =
        order["rejectionReason"]?.toString() ??
            "labRejectedBooking".tr();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: Colors.red,
            size: 30,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "bookingRejected".tr(),
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.25),
        ),
      ),
      child: Row(children: [
          Icon(
            Icons.task_alt,
            color: Colors.green,
            size: 30,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              "Your laboratory testing is completed. "
              "reportAvailableLabReports".tr(),
              style: TextStyle(
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}