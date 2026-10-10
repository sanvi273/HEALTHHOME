import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:healthhome/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upload_lab_report_page.dart';


class LaboratoryDashboard extends StatefulWidget {
  const LaboratoryDashboard({super.key});

  @override
  State<LaboratoryDashboard> createState() =>
      _LaboratoryDashboardState();
}

class _LaboratoryDashboardState
    extends State<LaboratoryDashboard> {
      

  int currentIndex = 0;
  Map<String, dynamic>? labData;

// ============================================================
// SHOW MESSAGE
// ============================================================

void _showMessage(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

bool isLoading = true;

String labName = "";

String labPhone = "";

  // ============================================================
  // MSG91 WIDGET STATE
  // ============================================================


Future<void> loadLab() async {
  try {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String phone =
        prefs.getString("userPhone") ?? "";

    final labs = await ApiService.getLabs();

    final currentLab = labs.firstWhere(
      (lab) => lab["phone"] == phone,
      orElse: () => {},
    );

   labData = currentLab;

await loadLabOrders();
await loadSampleCollectors();
await loadLabTests();

if (!mounted) return;

    setState(() {
      isLoading = false;
    });

  } catch (e) {
    debugPrint("LOAD LAB ERROR = $e");

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}


 Future<void> loadLabInfo() async {

  SharedPreferences prefs =
      await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    labName =
        prefs.getString("userName") ?? "";

    labPhone =
        prefs.getString("userPhone") ?? "";
  });
}


// ============================================================
// LOAD LAB ORDERS
// ============================================================

Future<void> loadLabOrders() async {
  try {

    final data =
        await ApiService.getLabOrders();

    final currentLabId =
        labData?["_id"]?.toString() ?? "";

    debugPrint(
      "================================",
    );

    debugPrint(
      "LAB ORDERS LOADED",
    );

    debugPrint(
      "TOTAL ORDERS = ${data.length}",
    );

    debugPrint(
      "CURRENT LAB ID = $currentLabId",
    );

    // ========================================================
    // FILTER ORDERS FOR CURRENT LAB
    // ========================================================

    final labOrders =
        List<Map<String, dynamic>>.from(data)
            .where((order) {

      final rawLabId = order["labId"];
      final orderLabId = rawLabId is Map
          ? (rawLabId["_id"] ?? rawLabId["id"] ?? "").toString()
          : (rawLabId?.toString() ?? "");

      return currentLabId.isEmpty ||
          orderLabId == currentLabId;

    }).toList();

// ========================================================
// SORT NEWEST ORDERS FIRST
// ========================================================

labOrders.sort((a, b) {
  final aId = a["_id"]?.toString() ?? "";
  final bId = b["_id"]?.toString() ?? "";

  return bId.compareTo(aId);
});

    // ========================================================
    // PENDING BOOKINGS
    // ========================================================

    final newBookings =
        labOrders.where((order) {

      final status =
          order["status"]
              ?.toString()
              .trim()
              .toLowerCase() ??
          "";
      final rescheduleStatus =
          order["rescheduleStatus"]?.toString().trim().toLowerCase() ?? "";

      // Requests waiting for the laboratory's decision are handled in the
      // Reschedule Requests section, not in the normal booking action row.
      return status == "pending" && rescheduleStatus != "pending";

    }).toList();


// ========================================================
// COLLECTION ORDERS
// ========================================================

final collection =
    labOrders.where((order) {

  final status =
      order["status"]
          ?.toString()
          .trim()
          .toLowerCase() ??
      "";

  final collectionMode =
      order["collectionMode"]
          ?.toString()
          .trim() ??
      "Home Collection";

  // Sample collector workflow is ONLY for Home Collection.
  if (collectionMode != "Home Collection") {
    return false;
  }

  return status == "accepted" ||
      status == "collector assigned" ||
      status == "on the way" ||
      status == "sample collected";

}).toList();

// ========================================================
// IN PROGRESS
// ========================================================

final progressOrders =
    labOrders.where((order) {

  final status =
      order["status"]
          ?.toString()
          .trim()
          .toLowerCase() ??
      "";

  return status == "sample received" ||
      status == "in progress" ||
      status == "report ready";

}).toList();


// ========================================================
// COMPLETED
// ========================================================

final completedOrders =
    labOrders.where((order) {

  final status =
      order["status"]
          ?.toString()
          .trim()
          .toLowerCase() ??
      "";

  return status == "completed";

}).toList();


// ========================================================
// REJECTED
// ========================================================

final rejectedOrders =
    labOrders.where((order) {

  final status =
      order["status"]
          ?.toString()
          .trim()
          .toLowerCase() ??
      "";

  return status == "rejected";

}).toList();

    // ========================================================
    // PATIENT RESCHEDULE REQUESTS
    // ========================================================

    final patientRescheduleRequests = labOrders.where((order) {
      final rescheduleStatus =
          order["rescheduleStatus"]?.toString().trim().toLowerCase() ?? "";
      final proposedBy =
          order["rescheduleProposedBy"]?.toString().trim().toLowerCase() ?? "";

      // Older records / responses may not include rescheduleProposedBy.
      // Treat an unspecified proposer as a patient request, but never show
      // requests explicitly proposed by the laboratory.
      final isPatientRequest =
          proposedBy.isEmpty || proposedBy == "patient";

      final isPending = rescheduleStatus == "pending";
      if (isPending) {
        debugPrint(
          "RESCHEDULE REQUEST: id=${order["_id"]}, "
          "status=${order["rescheduleStatus"]}, "
          "proposedBy=${order["rescheduleProposedBy"]}, "
          "labId=${order["labId"]}",
        );
      }

      return isPending && isPatientRequest;
    }).toList();

    // ========================================================
    // UPDATE UI
    // ========================================================

    if (!mounted) return;

 setState(() {

  bookings =
      newBookings;

  rescheduleRequests =
      patientRescheduleRequests;

  collectionOrders =
      collection;

  inProgress =
      progressOrders;

  reports =
      completedOrders;

  rejected =
      rejectedOrders;

});


    debugPrint(
      "PENDING = ${bookings.length}",
    );

    debugPrint(
      "IN PROGRESS = ${inProgress.length}",
    );

    debugPrint(
      "COMPLETED = ${reports.length}",
    );

    debugPrint(
      "REJECTED = ${rejected.length}",
    );

    debugPrint(
      "================================",
    );

  } catch (e) {

    debugPrint(
      "LOAD LAB ORDERS ERROR = $e",
    );
  }
}


List<Map<String, dynamic>> bookings = [];
List<Map<String, dynamic>> rescheduleRequests = [];
final Set<String> processingRescheduleIds = <String>{};

String _formatSchedule(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return "Not specified";
  }

  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();

  final local = parsed.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, "0");
  final period = local.hour >= 12 ? "PM" : "AM";
  final day = local.day.toString().padLeft(2, "0");
  final month = local.month.toString().padLeft(2, "0");

  return "$day/$month/${local.year} • $hour:$minute $period";
}

Future<void> _decidePatientReschedule(
  Map<String, dynamic> order,
  String decision,
) async {
  final orderId = order["_id"]?.toString() ?? "";
  final labId = labData?["_id"]?.toString() ?? "";

  if (orderId.isEmpty || labId.isEmpty) {
    _showMessage("Booking ID or laboratory ID is missing.");
    return;
  }

  if (processingRescheduleIds.contains(orderId)) return;

  setState(() {
    processingRescheduleIds.add(orderId);
  });

  try {
    final result = await ApiService.decideLabReschedule(
      orderId: orderId,
      labId: labId,
      decision: decision,
    );

    if (result["success"] == false) {
      throw Exception(
        result["message"]?.toString() ?? "Unable to process request.",
      );
    }

    await loadLabOrders();

    if (!mounted) return;
    _showMessage(
      decision == "Approved"
          ? "Reschedule request approved. The requested date is confirmed."
          : "Reschedule request cancelled. The original booking time is unchanged.",
    );
  } catch (e) {
    if (!mounted) return;
    _showMessage(e.toString().replaceFirst("Exception: ", ""));
  } finally {
    if (mounted) {
      setState(() {
        processingRescheduleIds.remove(orderId);
      });
    }
  }
}

Future<void> loadSampleCollectors() async {
  try {
    final labId =
        labData?["_id"]?.toString() ?? "";

    if (labId.isEmpty) {
      debugPrint("Lab ID not found");
      return;
    }

    if (mounted) {
      setState(() {
        loadingCollectors = true;
      });
    }

    final collectors =
        await ApiService.getSampleCollectors(
      labId,
    );

    if (!mounted) return;

    setState(() {
      sampleCollectors = collectors;
      loadingCollectors = false;
    });

  } catch (e) {
    if (!mounted) return;

    setState(() {
      loadingCollectors = false;
    });

    debugPrint(
      "LOAD COLLECTORS ERROR: $e",
    );
  }
}

List<Map<String, dynamic>> collectionOrders = [];

// ============================================================
// LOAD LAB TESTS
// ============================================================

Future<void> loadLabTests() async {
  try {
    final labId = labData?["_id"]?.toString() ?? "";

    if (labId.isEmpty) {
      debugPrint("Lab ID not found for tests");
      return;
    }

    final data = await ApiService.getLabTestsByLab(labId);

    if (!mounted) return;

    setState(() {
      tests = data;
    });

    debugPrint("LAB TESTS LOADED = ${tests.length}");
  } catch (e) {
    debugPrint("LOAD LAB TESTS ERROR = $e");
  }
}

List<Map<String, dynamic>> sampleCollectors = [];

bool loadingCollectors = false;
  List<Map<String, dynamic>> inProgress = [];

List<Map<String, dynamic>> reports = [];

List<Map<String, dynamic>> tests = [];
List<Map<String, dynamic>> rejected = [];


// ============================================================
// COLLECTION OTP
// ============================================================
// OTP is generated and sent by the backend through MSG91.
// This Flutter screen does NOT use the MSG91 Widget SDK.
// ============================================================

@override
void initState() {
  super.initState();

  loadLab();
  loadLabInfo();
}

  @override
  Widget build(BuildContext context) {
     if (isLoading) {

    return const Scaffold(

      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
final pages = <Widget>[
  bookingsPage(),
  sampleCollectionPage(),
  inProgressPage(),
  reportsPage(),
  profilePage(),
];

    return Scaffold(
      backgroundColor:
      const Color(0xffF4F7FB),

     body: IndexedStack(
  index: currentIndex,
  children: pages,
),

      bottomNavigationBar:
      BottomNavigationBar(
type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,

        selectedItemColor:
        const Color(0xFF20C6D3),

        unselectedItemColor:
        Colors.grey,

        onTap: (value) async {
  await loadLabOrders();

  setState(() {
    currentIndex = value;
  });
},
       items: const [

  // ============================================================
  // 1. BOOKINGS
  // ============================================================

  BottomNavigationBarItem(
    icon: Icon(
      Icons.book_outlined,
    ),
    activeIcon: Icon(
      Icons.book,
    ),
    label: "Bookings",
  ),

  // ============================================================
  // 2. COLLECTION
  // ============================================================

  BottomNavigationBarItem(
    icon: Icon(
      Icons.person_pin_outlined,
    ),
    activeIcon: Icon(
      Icons.person_pin,
    ),
    label: "Collection",
  ),

  // ============================================================
  // 3. IN PROGRESS
  // ============================================================

  BottomNavigationBarItem(
    icon: Icon(
      Icons.hourglass_empty,
    ),
    activeIcon: Icon(
      Icons.hourglass_top,
    ),
    label: "In Progress",
  ),

  // ============================================================
  // 4. COMPLETED
  // ============================================================

  BottomNavigationBarItem(
    icon: Icon(
      Icons.check_circle_outline,
    ),
    activeIcon: Icon(
      Icons.check_circle,
    ),
    label: "Completed",
  ),

  // ============================================================
  // 5. PROFILE
  // ============================================================

  BottomNavigationBarItem(
    icon: Icon(
      Icons.person_outline,
    ),
    activeIcon: Icon(
      Icons.person,
    ),
    label: "Profile",
  ),
],
      ),
    );
  }

  // ================= DASHBOARD =================

  Widget bookingsPage() {

    return SafeArea(
      child: ListView(
        padding:
        const EdgeInsets.all(20),

        children: [

          Container(
            padding:
            const EdgeInsets.all(24),

            decoration: BoxDecoration(
              gradient:
              const LinearGradient(
  colors: [
    Color(0xFF20C6D3),
    Color(0xFF13D8B6),
  ],
),

              borderRadius:
              BorderRadius.circular(30),
            ),

            child: Column(
              children: [

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

                  children: [

                     Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(
                            "Lab Module",

                            style: TextStyle(
                              color:
                              Colors
                                  .white70,

                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            labName,

                            style: TextStyle(
                              color:
                              Colors
                                  .white,

                              fontSize: 28,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          SizedBox(height: 8),

                        ],
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .all(14),

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white24,

                        borderRadius:
                        BorderRadius
                            .circular(
                            20),
                      ),

                      child: const Icon(
                        Icons.science,
                        color:
                        Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

                  children: [

                    dashboardItem(
                      bookings.length
                          .toString(),
                      "Pending",
                    ),

                    dashboardItem(
                      inProgress.length
                          .toString(),
                      "In Progress",
                    ),

                    dashboardItem(
                      reports.length
                          .toString(),
                      "Done Today",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

// ============================================================
// MANAGE LAB TESTS
// ============================================================

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Row(
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFE6FAF8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.biotech,
          color: Color(0xFF20C6D3),
          size: 30,
        ),
      ),

      const SizedBox(width: 15),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Lab Tests",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "${tests.length} tests available",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),

     SizedBox(
  width: 95,
  height: 48,
  child: ElevatedButton(
    onPressed: _showLabTestManagement,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF20C6D3),
      foregroundColor: Colors.white,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text(
      "Manage",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
    ],
  ),
),

const SizedBox(height: 25),

_buildRescheduleRequestsSection(),

const SizedBox(height: 24),

const Text(
  "New Lab Bookings",

            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ...List.generate(
            bookings.length,

                (index) {

              final item =
              bookings[index];

              return bookingCard(
                index: index,
                item: item,
              );
            },
          ),
const SizedBox(height: 20),
        ],
      ),
    );
  }

// ============================================================
// PATIENT RESCHEDULE REQUESTS
// ============================================================

Widget _buildRescheduleRequestsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              "Reschedule Requests",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (rescheduleRequests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${rescheduleRequests.length} pending",
                style: const TextStyle(
                  color: Color(0xFFB76E00),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (rescheduleRequests.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: Color(0xFF20C6D3),
                size: 25,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "No pending patient reschedule requests.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        )
      else
        ...rescheduleRequests.map((item) {
          final orderId = item["_id"]?.toString() ?? "";
          final isProcessing =
              processingRescheduleIds.contains(orderId);
          final tests = item["tests"] is List
              ? (item["tests"] as List).map((e) => e.toString()).join(", ")
              : item["tests"]?.toString() ?? "Lab test";
          final reason =
              item["rescheduleReason"]?.toString().trim() ?? "";

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD7F3F2)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE6FAF8),
                      child: Icon(
                        Icons.person_outline,
                        color: Color(0xFF20C6D3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item["patientName"]?.toString() ?? "Patient",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFF20C6D3),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (item["patientPhone"] != null &&
                    item["patientPhone"].toString().isNotEmpty)
                  _rescheduleInfoRow(
                    Icons.phone_outlined,
                    item["patientPhone"].toString(),
                  ),
                _rescheduleInfoRow(Icons.science_outlined, tests),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current booking",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSchedule(item["scheduledAt"]),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Requested new time",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSchedule(item["requestedScheduledAt"]),
                        style: const TextStyle(
                          color: Color(0xFF078B91),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "Reason",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(reason),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Color(0xFF20C6D3),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _decidePatientReschedule(item, "Rejected"),
                          icon: const Icon(Icons.close),
                          label: const Text("Cancel Request"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _decidePatientReschedule(item, "Approved"),
                          icon: const Icon(Icons.check),
                          label: const Text("Accept New Time"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20C6D3),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
    ],
  );
}

Widget _rescheduleInfoRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF20C6D3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// COLLECTION PAGE
// ============================================================

Widget sampleCollectionPage() {
  if (collectionOrders.isEmpty) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_pin_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              "No Sample Collections",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return SafeArea(
    child: ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: collectionOrders.length,
      itemBuilder: (context, index) {
        final item = collectionOrders[index];

        final status = item["status"]
                ?.toString()
                .trim()
                .toLowerCase() ??
            "";

        final collectionMode =
            item["collectionMode"]?.toString() ??
                "Home Collection";

        final tests =
            item["tests"] is List
                ? List.from(item["tests"])
                : <dynamic>[];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==================================================
              // PATIENT HEADER
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item["patientName"]?.toString() ??
                          "Patient",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FAF8),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      item["status"]?.toString() ??
                          "Accepted",
                      style: const TextStyle(
                        color: Color(0xFF20C6D3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // PHONE
              // ==================================================

              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: Color(0xFF20C6D3),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item["patientPhone"]?.toString() ??
                        "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // COLLECTION TYPE
              // ==================================================

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      collectionMode == "Home Collection"
                          ? Icons.home_outlined
                          : Icons.science_outlined,
                      color: const Color(0xFF20C6D3),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            collectionMode,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            collectionMode ==
                                    "Home Collection"
                                ? "Sample will be collected from patient's home"
                                : "Patient will visit the laboratory",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // ADDRESS
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item["address"]?.toString() ?? "",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // TESTS
              // ==================================================

              if (tests.isNotEmpty) ...[
                const Text(
                  "Requested Tests",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tests.map<Widget>((test) {
                    return Chip(
                      avatar: const Icon(
                        Icons.science,
                        size: 16,
                        color: Color(0xFF20C6D3),
                      ),
                      label: Text(
                        test.toString(),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 15),

              // ==================================================
              // COLLECTOR INFORMATION
              // ==================================================

              if (item["collectorName"] != null &&
                  item["collectorName"]
                      .toString()
                      .trim()
                      .isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFBFA),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor:
                            Color(0xFF20C6D3),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sample Collector",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item["collectorName"]
                                      ?.toString() ??
                                  "",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item["collectorPhone"]
                                      ?.toString() ??
                                  "",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // ==================================================
              // COLLECTION ACTION
              // ==================================================

              _collectionActionButton(item),
            ],
          ),
        );
      },
    ),
  );
}


// ============================================================
// COLLECTION ACTION BUTTON
// ============================================================

Widget _collectionActionButton(
  Map<String, dynamic> item,
) {
  final status =
      item["status"]?.toString().trim().toLowerCase() ?? "";

  // ==========================================================
  // ACCEPTED → ASSIGN COLLECTOR
  // ==========================================================

  if (status == "accepted") {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          "Assign Sample Collector",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF20C6D3),
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 52),
        ),
        onPressed: () {
          _showCollectorDialog(item);
        },
      ),
    );
  }


// ==========================================================
// COLLECTOR ASSIGNED → ON THE WAY
// ==========================================================

if (status == "collector assigned") {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(
        Icons.local_shipping_outlined,
      ),
      label: const Text(
        "Collector On The Way",
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF20C6D3),
        foregroundColor: Colors.white,
        minimumSize: const Size(
          double.infinity,
          52,
        ),
      ),
      onPressed: () async {
        final orderId = item["_id"]?.toString();

        if (orderId == null || orderId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid lab order ID"),
            ),
          );
          return;
        }

        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Updating collector status..."),
              duration: Duration(seconds: 1),
            ),
          );

          final response =
              await ApiService.collectorOnTheWay(orderId);

          debugPrint("================================");
          debugPrint("COLLECTOR ON THE WAY RESPONSE");
          debugPrint("ORDER ID = $orderId");
          debugPrint("RESPONSE = $response");
          debugPrint("================================");

          if (response["success"] != true) {
            throw Exception(
              response["message"] ??
                  "Failed to update collector status",
            );
          }

          // Immediately update the clicked order
          setState(() {
            item["status"] = "On The Way";
            item["collectorStatus"] = "On The Way";
          });

          // Refresh data from backend
          await loadLabOrders();
          await loadSampleCollectors();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Collector is on the way",
              ),
            ),
          );
        } catch (e) {
          debugPrint(
            "COLLECTOR ON THE WAY UI ERROR = $e",
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed: ${e.toString()}",
              ),
            ),
          );
        }
      },
    ),
  );
}

  // ==========================================================
  // ON THE WAY → SAMPLE COLLECTED
  // ==========================================================

  if (status == "on the way") {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.verified_user_outlined,
        ),
        label: const Text(
          "Verify Patient OTP",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF20C6D3),
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 52),
        ),
        onPressed: () async {
          await _startCollectionOtpFlow(item);
        },
      ),
    );
  }

  // ==========================================================
  // SAMPLE COLLECTED → SAMPLE RECEIVED
  // ==========================================================

  if (status == "sample collected") {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.science_outlined,
        ),
        label: const Text(
          "Mark Sample Received",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF20C6D3),
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 52),
        ),
        onPressed: () async {
          try {
            await ApiService.markSampleReceived(
              item["_id"].toString(),
            );

            await loadLabOrders();

            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Sample received at laboratory",
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(e.toString()),
              ),
            );
          }
        },
      ),
    );
  }

  return const SizedBox.shrink();
}


// ============================================================
// COLLECTION OTP FLOW - LOCAL BACKEND OTP
// ============================================================
// Flow:
// On The Way -> Backend generates OTP -> OTP is shown in Render log
// -> Collector enters patient's OTP -> Backend verifies hash
// -> Sample Collected
//
// IMPORTANT:
// This flow does NOT use MSG91 or OTPWidget.
// ============================================================

Future<void> _startCollectionOtpFlow(
  Map<String, dynamic> order,
) async {
  final orderId = (order["_id"] ?? order["id"])?.toString() ?? "";

  if (orderId.isEmpty) {
    _showMessage("Order ID is missing");
    return;
  }

  debugPrint("========================================");
  debugPrint("START COLLECTION OTP FLOW");
  debugPrint("ORDER ID = $orderId");
  debugPrint("========================================");

  try {
    // ----------------------------------------------------------
    // STEP 1: Generate OTP.
    // ----------------------------------------------------------
    final generateResult =
        await ApiService.generateCollectionOtp(orderId);

    debugPrint("GENERATE OTP RESULT = $generateResult");

    final generateSuccess =
        generateResult["success"] == true;

    final generateMessage =
        generateResult["message"]?.toString() ?? "";

    // ----------------------------------------------------------
    // IMPORTANT:
    // If backend says an OTP is already active, DO NOT stop.
    // The existing OTP can still be entered and verified.
    // ----------------------------------------------------------
    final otpAlreadyActive =
        generateMessage.toLowerCase().contains("already active");

    if (!generateSuccess && !otpAlreadyActive) {
      if (!mounted) return;

      _showMessage(
        generateMessage.isNotEmpty
            ? generateMessage
            : "Failed to generate OTP",
      );
      return;
    }

    if (!mounted) return;

    debugPrint("========================================");
    debugPrint("OPENING COLLECTION OTP DIALOG");
    debugPrint("EXISTING OTP ACTIVE = $otpAlreadyActive");
    debugPrint("========================================");

    // Small delay makes the dialog opening reliable after the
    // asynchronous API request and dashboard rebuild.
    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (!mounted) return;

    // ----------------------------------------------------------
    // STEP 2: Ask collector for patient's 6-digit OTP.
    // ----------------------------------------------------------
    final otp = await _showCollectionOtpDialog(order);

    debugPrint("OTP DIALOG RESULT = $otp");

    if (otp == null || otp.trim().isEmpty) {
      debugPrint("OTP DIALOG CANCELLED");
      return;
    }

    // ----------------------------------------------------------
    // STEP 3: Verify OTP with backend.
    // ----------------------------------------------------------
    final verifyResult =
        await ApiService.verifyCollectionOtp(
      orderId: orderId,
      otp: otp.trim(),
    );

    debugPrint("VERIFY OTP RESULT = $verifyResult");

    if (!mounted) return;

    if (verifyResult["success"] == true) {
      await loadLabOrders();
      await loadSampleCollectors();

      if (!mounted) return;

      _showMessage(
        "Patient verified. Sample collected successfully.",
      );
      return;
    }

    _showMessage(
      verifyResult["message"]?.toString() ??
          "Invalid or expired OTP",
    );
  } catch (e, stackTrace) {
    debugPrint("========================================");
    debugPrint("COLLECTION OTP FLOW ERROR = $e");
    debugPrint("COLLECTION OTP STACK = $stackTrace");
    debugPrint("========================================");

    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst("Exception: ", ""),
    );
  }
}

// ============================================================
// OTP INPUT DIALOG
// ============================================================

Future<String?> _showCollectionOtpDialog(
  Map<String, dynamic> order,
) async {
  final TextEditingController otpController =
      TextEditingController();

  final FocusNode otpFocusNode = FocusNode();

  try {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF20C6D3),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Verify Patient OTP",
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ask the patient for the 6-digit OTP.",
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "OTP is valid for 10 minutes.",
                style: TextStyle(
                  color: Color(0xFF20C6D3),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: otpController,
                focusNode: otpFocusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                textAlign: TextAlign.center,

                onChanged: (value) {
                  final cleanValue =
                      value.replaceAll(RegExp(r"[^0-9]"), "");

                  if (cleanValue != value) {
                    otpController.value =
                        otpController.value.copyWith(
                      text: cleanValue,
                      selection: TextSelection.collapsed(
                        offset: cleanValue.length,
                      ),
                    );
                  }
                },

                onSubmitted: (_) {
                  final otp = otpController.text.trim();

                  if (RegExp(r"^\d{6}$").hasMatch(otp)) {
                    Navigator.of(dialogContext).pop(otp);
                  }
                },

                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),

                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  filled: true,
                  fillColor: const Color(0xFFF4F7FB),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF20C6D3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                final otp = otpController.text.trim();

                if (!RegExp(r"^\d{6}$").hasMatch(otp)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter a valid 6-digit OTP",
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(otp);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF20C6D3),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Verify OTP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result;
  } finally {
    otpController.dispose();
    otpFocusNode.dispose();
  }
}

// ============================================================
// SELECT SAMPLE COLLECTOR
// ============================================================

Future<void> _showCollectorDialog(
  Map<String, dynamic> order,
) async {
  await loadSampleCollectors();

  if (!mounted) return;

  final availableCollectors =
      sampleCollectors.where((collector) {
    final collectorStatus =
        collector["status"]?.toString() ?? "Active";

    final availability =
        collector["availability"]?.toString() ??
            "Available";

    return collectorStatus.toLowerCase() == "active" &&
        availability.toLowerCase() == "available";
  }).toList();

  if (availableCollectors.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "No sample collector is available",
        ),
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Assign Sample Collector",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Select collector for "
                "${order["patientName"] ?? "patient"}",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              ...availableCollectors.map(
                (collector) {
                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            Color(0xFFE8FAFB),
                        child: Icon(
                          Icons.person,
                          color:
                              Color(0xFF20C6D3),
                        ),
                      ),
                      title: Text(
                        collector["name"]
                                ?.toString() ??
                            "Collector",
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        collector["phone"]
                                ?.toString() ??
                            "",
                      ),
                      trailing:
                          const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () async {
                        Navigator.pop(
                          sheetContext,
                        );

                        await _assignCollector(
                          order,
                          collector,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


// ============================================================
// ASSIGN COLLECTOR
// ============================================================

Future<void> _assignCollector(
  Map<String, dynamic> order,
  Map<String, dynamic> collector,
) async {
  try {
    final collectorId =
        collector["_id"]?.toString() ?? "";

    if (collectorId.isEmpty) {
      throw Exception(
        "Collector ID is missing",
      );
    }

    await ApiService.assignSampleCollector(
      orderId: order["_id"].toString(),
      collectorId: collectorId,
      collectorName:
          collector["name"]?.toString() ?? "",
      collectorPhone:
          collector["phone"]?.toString() ?? "",
    );

    await loadLabOrders();
    await loadSampleCollectors();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${collector["name"]} assigned successfully",
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

Widget inProgressPage() {
  print("IN PROGRESS DATA = $inProgress");
print("OPENED IN PROGRESS PAGE");
print("COUNT = ${inProgress.length}");
  if (inProgress.isEmpty) {
    return const Center(
      child: Text(
        "No Orders In Progress",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


return SafeArea(
  child: ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: inProgress.length,
    itemBuilder: (context, index) {
      try {
        final item = inProgress[index];

        print("BUILDING ORDER = $item");

        return progressCard(
          index: index,
          item: item,
        );
      } catch (e) {
        print("CARD ERROR = $e");

        return Container(
          padding: const EdgeInsets.all(20),
          child: Text("Error: $e"),
        );
      }
    },
  ),
);
}

  Widget dashboardItem(
      String value,
      String label,
      ) {

    return Column(
      children: [

        Text(
          value,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          label,

          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

Future<void> _proposeNewLabSchedule(Map<String, dynamic> item) async {
  final orderId = item["_id"]?.toString() ?? "";
  if (orderId.isEmpty) {
    _showMessage("Cannot reschedule: booking ID is missing.");
    return;
  }

  final status = item["status"]?.toString().trim().toLowerCase() ?? "";
  if (! ["pending", "accepted"].contains(status)) {
    _showMessage("Only pending or accepted bookings can be rescheduled.");
    return;
  }

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final reasonController = TextEditingController();
  bool submitting = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Propose New Date & Time"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Patient: ${item["patientName"] ?? "Patient"}"),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text("Date: ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.isAfter(DateTime.now()) ? selectedDate : DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text("Time: ${selectedTime.format(context)}"),
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) setDialogState(() => selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Reason for changing schedule",
                      hintText: "e.g. Sample collector unavailable",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: submitting ? null : () async {
                  final proposedAt = DateTime(
                    selectedDate.year, selectedDate.month, selectedDate.day,
                    selectedTime.hour, selectedTime.minute,
                  );
                  if (!proposedAt.isAfter(DateTime.now())) {
                    _showMessage("Choose a date and time in the future.");
                    return;
                  }
                  setDialogState(() => submitting = true);
                  try {
                    final labId = labData?["_id"]?.toString() ?? "";
                    if (labId.isEmpty) throw Exception("Laboratory ID not found. Please log in again.");
                    await ApiService.proposeLabReschedule(
                      orderId: orderId,
                      labId: labId,
                      scheduledAt: proposedAt,
                      reason: reasonController.text.trim(),
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  } catch (e) {
                    setDialogState(() => submitting = false);
                    _showMessage(e.toString().replaceFirst("Exception: ", ""));
                  }
                },
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Send Proposal"),
              ),
            ],
          );
        },
      );
    },
  );
  reasonController.dispose();
  if (result == true) {
    await loadLabOrders();
    _showMessage("New date/time proposed. Waiting for patient response.");
  }
}

Widget bookingCard({
  required int index,
  required Map<String, dynamic> item,
}) {


    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 20,
      ),

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

             Expanded(
  child: Text(
    item["patientName"] ?? "",
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),

              Text(
                item["status"] ?? "Pending",

                style: const TextStyle(
                  color:
                  Color(0xFF20C6D3),

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,

  children: [

    Text(
      item["patientPhone"] ?? "",
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    ),

  const SizedBox(height: 15),

const Row(
  children: [
    Icon(
      Icons.science,
      color: Color(0xFF20C6D3),
      size: 18,
    ),
    SizedBox(width: 8),
    Text(
      "Requested Tests",
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),

const SizedBox(height: 8),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ...(item["tests"] ?? []).map<Widget>(
      (test) => Chip(
        backgroundColor: const Color(0xFFE6FAF8),
        avatar: const Icon(
          Icons.science,
          color: Color(0xFF20C6D3),
          size: 16,
        ),
        label: Text(test.toString()),
      ),
    ),
  ],
),

const SizedBox(height: 15),

Row(
  children: [
    const Icon(
      Icons.location_on,
      color: Colors.red,
      size: 18,
    ),
    const SizedBox(width: 6),
    Expanded(
      child: Text(
        item["address"] ?? "",
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    ),
  ],
),

    const SizedBox(height: 15),

if (item["prescriptionImage"] != null &&
    item["prescriptionImage"] != "")
  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text("Prescription"),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              item["prescriptionImage"],
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    "Unable to load image",
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
},
 

  icon: const Icon(Icons.visibility),

  label: const Text(
    "Open Prescription",
  ),
)
  ),

const SizedBox(height: 15),
  ],
),

          const SizedBox(height: 10),

         Row(
  children: [

    const Icon(
      Icons.notes,
      color: Colors.orange,
      size: 18,
    ),

    const SizedBox(width: 5),

    Expanded(
      child: Text(
        "Notes : ${item["notes"] ?? ""}",
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    ),
  ],
),

                 

          const SizedBox(height: 18),

          const SizedBox(height: 18),

          Row(
            children: [

             Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          const Color(0xFF20C6D3),
    ),

    onPressed: () async {
      try {

        debugPrint(
  "================================",
);

debugPrint(
  "ACCEPT BUTTON PRESSED",
);

debugPrint(
  "ORDER ID = ${item["_id"]}",
);

debugPrint(
  "ORDER STATUS = ${item["status"]}",
);

debugPrint(
  "ORDER PATIENT = ${item["patientName"]}",
);

debugPrint(
  "================================",
);
        await ApiService.acceptLabOrder(
          item["_id"].toString(),
        );

        await loadLabOrders();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Lab booking accepted",
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    },

    child: const Text(
      "Accept",
      style: TextStyle(
        color: Colors.white,
      ),
    ),
  ),
),

  
    
              

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _proposeNewLabSchedule(item),
                  icon: const Icon(Icons.event_repeat),
                  label: const Text("Reschedule"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF168D96),
                    side: const BorderSide(color: Color(0xFF20C6D3)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
}

Widget progressCard({
  required int index,
  required Map<String, dynamic> item,
}) {
  final status =
      item["status"]?.toString().trim().toLowerCase() ?? "";

  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ==================================================
        // PATIENT
        // ==================================================

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Expanded(
              child: Text(
                item["patientName"]?.toString() ?? "Patient",
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE6FAF8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item["status"]?.toString() ?? "",
                style: const TextStyle(
                  color: Color(0xFF20C6D3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // PHONE

        Row(
          children: [
            const Icon(
              Icons.phone,
              size: 18,
              color: Color(0xFF20C6D3),
            ),
            const SizedBox(width: 8),
            Text(
              item["patientPhone"]?.toString() ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ADDRESS

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on,
              size: 18,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item["address"]?.toString() ?? "",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // COLLECTOR

        if (item["collectorName"] != null &&
            item["collectorName"]
                .toString()
                .trim()
                .isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFBFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [

                const CircleAvatar(
                  backgroundColor:
                      Color(0xFF20C6D3),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Sample Collector",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item["collectorName"]
                                ?.toString() ??
                            "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      Text(
                        item["collectorPhone"]
                                ?.toString() ??
                            "",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 18),

        // ==================================================
        // SAMPLE RECEIVED
        // ==================================================

        if (status == "sample received")
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.science_outlined,
              ),
              label: const Text(
                "Start Testing",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF20C6D3),
                foregroundColor: Colors.white,
                minimumSize:
                    const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                try {

                  await ApiService.startLabTesting(
                    item["_id"].toString(),
                  );

                  await loadLabOrders();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Testing started",
                      ),
                    ),
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

        // ==================================================
        // IN PROGRESS
        // ==================================================

        if (status == "in progress")
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFBFA),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Row(
              children: [

                Icon(
                  Icons.hourglass_top,
                  color: Color(0xFF20C6D3),
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "Testing is currently in progress",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ==================================================
        // UPLOAD REPORT
        // ==================================================

        if (status == "in progress" ||
            status == "report ready")
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.upload_file,
              ),
              label: const Text(
                "Upload Report",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF20C6D3),
                foregroundColor: Colors.white,
                minimumSize:
                    const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {

                final result =
                    await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UploadLabReportPage(
                      order: item,
                    ),
                  ),
                );

                if (result == true) {
                  await loadLabOrders();
                }
              },
            ),
          ),
      ],
    ),
  );
}

// ================= REPORTS =================

Widget reportsPage() {
  if (reports.isEmpty) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              "No Completed Reports",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return SafeArea(
    child: ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final item = reports[index];

        final List<Map<String, dynamic>> reportFiles = [];

        // ======================================================
        // READ MULTIPLE REPORT FILES
        // ======================================================

        if (item["reports"] is List) {
          for (final report in item["reports"]) {
            if (report is Map) {
              reportFiles.add(
                Map<String, dynamic>.from(report),
              );
            }
          }
        }

        // ======================================================
        // SORT BY PAGE NUMBER
        // ======================================================

        reportFiles.sort((a, b) {
          final int pageA =
              int.tryParse(
                    a["pageNumber"]?.toString() ?? "",
                  ) ??
                  1;

          final int pageB =
              int.tryParse(
                    b["pageNumber"]?.toString() ?? "",
                  ) ??
                  1;

          return pageA.compareTo(pageB);
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==================================================
              // PATIENT
              // ==================================================

              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE6FAF8),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF20C6D3),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      item["patientName"]?.toString() ??
                          "Patient",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Completed",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // PHONE
              // ==================================================

              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 18,
                    color: Color(0xFF20C6D3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item["patientPhone"]?.toString() ??
                        "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // NUMBER OF REPORT PAGES
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9F9),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF20C6D3),
                      size: 28,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        reportFiles.length == 1
                            ? "1 Report Page"
                            : "${reportFiles.length} Report Pages",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // REPORT FILE LIST
              // ==================================================

              if (reportFiles.isNotEmpty)
                Column(
                  children:
                      List.generate(
                    reportFiles.length,
                    (reportIndex) {
                      final report =
                          reportFiles[reportIndex];

                      final String reportName =
                          report["reportName"]
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? report["reportName"].toString().trim()
                              : "Report ${reportIndex + 1}";

                      final String fileUrl =
                          report["fileUrl"]
                                  ?.toString() ??
                              "";

                      return Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding:
                            const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xffF7F9FA,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [

                            Container(
                              width: 42,
                              height: 42,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFE6FAF8,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .description,
                                color:
                                    Color(
                                  0xFF20C6D3,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [

                                  Text(
                                    reportName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              tooltip:
                                  "View",
                              icon:
                                  const Icon(
                                Icons
                                    .visibility,
                                color:
                                    Color(
                                  0xFF20C6D3,
                                ),
                              ),
                              onPressed:
                                  fileUrl
                                          .isEmpty
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      Scaffold(
                                                appBar:
                                                    AppBar(
                                                  title: Text(
                                                    report["reportName"]
                                                                ?.toString()
                                                                .trim()
                                                                .isNotEmpty ==
                                                            true
                                                        ? report["reportName"].toString().trim()
                                                        : "Report ${reportIndex + 1}",
                                                  ),
                                                ),
                                                body:
                                                    Container(
                                                  color:
                                                      Colors.black,
                                                  child:
                                                      Center(
                                                    child:
                                                        InteractiveViewer(
                                                      minScale:
                                                          0.5,
                                                      maxScale:
                                                          5,
                                                      child:
                                                          Image.network(
                                                        fileUrl,
                                                        fit:
                                                            BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return const Center(
                                                            child:
                                                                Text(
                                                              "Unable to load report",
                                                              style:
                                                                  TextStyle(
                                                                color:
                                                                    Colors.white,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Text(
                    "No report files uploaded",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // ==================================================
              // OPEN ALL REPORTS
              // ==================================================

              if (reportFiles.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.menu_book,
                    ),
                    label: Text(
                      reportFiles.length == 1
                          ? "View Report"
                          : "View All ${reportFiles.length} Pages",
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF20C6D3,
                      ),
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                        double.infinity,
                        50,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LabReportViewerPage(
                            reports:
                                reportFiles,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // ==================================================
              // PRESCRIPTION
              // ==================================================

              if (item["prescriptionImage"] !=
                      null &&
                  item["prescriptionImage"]
                      .toString()
                      .isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.image_outlined,
                    ),
                    label: const Text(
                      "Open Prescription",
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              Scaffold(
                            appBar: AppBar(
                              title:
                                  const Text(
                                "Prescription",
                              ),
                            ),
                            body: Container(
                              color:
                                  Colors.black,
                              child: Center(
                                child:
                                    InteractiveViewer(
                                  child:
                                      Image.network(
                                    item[
                                        "prescriptionImage"],
                                    fit: BoxFit
                                        .contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

 
Future<void> _logout() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Logout",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final prefs = await SharedPreferences.getInstance();

  // Clear current login/session
  await prefs.clear();

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const OnboardingScreen(),
    ),
    (route) => false,
  );
}

// ================= PROFILE =================

Widget profilePage() {
  final Map<String, dynamic> safeLabData =
      labData ?? <String, dynamic>{};

  final String name =
      safeLabData["name"]?.toString().trim().isNotEmpty == true
          ? safeLabData["name"].toString()
          : labName;

  final String phone =
      safeLabData["phone"]?.toString().trim().isNotEmpty == true
          ? safeLabData["phone"].toString()
          : labPhone;

  final String email =
      safeLabData["email"]?.toString().trim().isNotEmpty == true
          ? safeLabData["email"].toString()
          : "lab@healthhome.com";

  final String address =
      safeLabData["address"]?.toString().trim().isNotEmpty == true
          ? safeLabData["address"].toString()
          : "—";

  final String labType =
      safeLabData["labType"]?.toString().trim().isNotEmpty == true
          ? safeLabData["labType"].toString()
          : "Laboratory";

  final String experience =
      safeLabData["experience"]?.toString().trim().isNotEmpty == true
          ? safeLabData["experience"].toString()
          : "—";

  final String rating =
      safeLabData["rating"]?.toString().trim().isNotEmpty == true
          ? safeLabData["rating"].toString()
          : "—";

  return SafeArea(
    child: ListView(
      padding: const EdgeInsets.only(
        bottom: 30,
      ),
      children: [

        // =====================================================
        // PROFILE HEADER
        // =====================================================

        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            30,
            20,
            30,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF20C6D3),
                Color(0xFF0AA6B2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [

              const CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.science,
                  size: 45,
                  color: Color(0xFF20C6D3),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                labType,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // =====================================================
        // BASIC INFORMATION
        // =====================================================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Laboratory Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _profileInfoRow(
                  Icons.phone,
                  "Phone",
                  phone,
                ),

                const SizedBox(height: 16),

                _profileInfoRow(
                  Icons.email_outlined,
                  "Email",
                  email,
                ),

                const SizedBox(height: 16),

                _profileInfoRow(
                  Icons.location_on_outlined,
                  "Address",
                  address,
                ),

                const SizedBox(height: 16),

                _profileInfoRow(
                  Icons.work_outline,
                  "Experience",
                  experience,
                ),

                const SizedBox(height: 16),

                _profileInfoRow(
                  Icons.star_outline,
                  "Rating",
                  rating,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // =====================================================
        // LAB TEST SUMMARY
        // =====================================================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
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
                    color: const Color(0xFFE6FAF8),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.biotech,
                    color: Color(0xFF20C6D3),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Lab Tests",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "${tests.length} tests available",
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // =====================================================
        // SAMPLE COLLECTORS
        // =====================================================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // -------------------------------------------------
                // HEADER
                // -------------------------------------------------

                Row(
                  children: [

                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FAF8),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_outlined,
                        color: Color(0xFF20C6D3),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Sample Collectors",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "${sampleCollectors.length} collector${sampleCollectors.length == 1 ? "" : "s"} available",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: "Add Collector",
                      onPressed: () async {
                        await _showAddCollectorDialog();

                        if (!mounted) return;

                        await loadSampleCollectors();
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF20C6D3),
                        size: 30,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------
                // LOADING
                // -------------------------------------------------

                if (loadingCollectors)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF20C6D3),
                      ),
                    ),
                  )

                // -------------------------------------------------
                // NO COLLECTORS
                // -------------------------------------------------

                else if (sampleCollectors.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFA),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [

                        const Icon(
                          Icons.person_off_outlined,
                          size: 42,
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "No sample collectors added",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          "Add a collector to manage home sample collection.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: () async {
                            await _showAddCollectorDialog();

                            if (!mounted) return;

                            await loadSampleCollectors();
                          },
                          icon: const Icon(
                            Icons.person_add_alt_1,
                          ),
                          label: const Text(
                            "Add Collector",
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF20C6D3,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )

                // -------------------------------------------------
                // COLLECTOR LIST
                // -------------------------------------------------

                else
                  Column(
                    children:
                        sampleCollectors.map((collector) {

                      final String collectorName =
                          collector["name"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                              ? collector["name"]
                                  .toString()
                              : "Sample Collector";

                      final String collectorPhone =
                          collector["phone"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                              ? collector["phone"]
                                  .toString()
                              : "Phone not available";

                      final String collectorAddress =
                          collector["address"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                              ? collector["address"]
                                  .toString()
                              : "Address not available";

                      final String collectorStatus =
                          collector["status"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                              ? collector["status"]
                                  .toString()
                              : "Active";

                      final String availability =
                          collector["availability"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                              ? collector["availability"]
                                  .toString()
                              : "Available";

                      final bool isActive =
                          collectorStatus
                                  .toLowerCase() ==
                              "active";

                      final bool isAvailable =
                          availability
                                  .toLowerCase() ==
                              "available";

                      return Container(
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding:
                            const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF8FCFC,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color:
                                Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [

                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration:
                                      const BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    color: Color(
                                      0xFFE6FAF8,
                                    ),
                                  ),
                                  child:
                                      const Icon(
                                    Icons.person,
                                    color: Color(
                                      0xFF20C6D3,
                                    ),
                                    size: 27,
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        collectorName,
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Row(
                                        children: [

                                          const Icon(
                                            Icons
                                                .phone_outlined,
                                            size: 15,
                                            color:
                                                Colors
                                                    .grey,
                                          ),

                                          const SizedBox(
                                            width: 5,
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              collectorPhone,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    13,
                                                color:
                                                    Colors
                                                        .grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [

                                          const Icon(
                                            Icons
                                                .location_on_outlined,
                                            size: 15,
                                            color:
                                                Colors
                                                    .grey,
                                          ),

                                          const SizedBox(
                                            width: 5,
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              collectorAddress,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    13,
                                                color:
                                                    Colors
                                                        .grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // STATUS ROW
                            Row(
                              children: [

                                Expanded(
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isActive
                                          ? const Color(
                                              0xFFE8F8EE,
                                            )
                                          : const Color(
                                              0xFFFFEEEE,
                                            ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [

                                        Icon(
                                          isActive
                                              ? Icons
                                                  .check_circle_outline
                                              : Icons
                                                  .cancel_outlined,
                                          size: 16,
                                          color: isActive
                                              ? Colors
                                                  .green
                                              : Colors
                                                  .red,
                                        ),

                                        const SizedBox(
                                          width: 5,
                                        ),

                                        Text(
                                          isActive
                                              ? "Active"
                                              : "Inactive",
                                          style:
                                              TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color: isActive
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isAvailable
                                          ? const Color(
                                              0xFFE6F8FA,
                                            )
                                          : const Color(
                                              0xFFFFF4E5,
                                            ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        10,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [

                                        Icon(
                                          isAvailable
                                              ? Icons
                                                  .check_circle_outline
                                              : Icons
                                                  .schedule,
                                          size: 16,
                                          color: isAvailable
                                              ? const Color(
                                                  0xFF20C6D3,
                                                )
                                              : Colors
                                                  .orange,
                                        ),

                                        const SizedBox(
                                          width: 5,
                                        ),

                                        Text(
                                          isAvailable
                                              ? "Available"
                                              : "Busy",
                                          style:
                                              TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                isAvailable
                                                    ? const Color(
                                                        0xFF20C6D3,
                                                      )
                                                    : Colors
                                                        .orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 8),

                // -------------------------------------------------
                // ADD COLLECTOR BUTTON
                // -------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _showAddCollectorDialog();

                      if (!mounted) return;

                      await loadSampleCollectors();
                    },
                    icon: const Icon(
                      Icons.person_add_alt_1,
                    ),
                    label: const Text(
                      "Add Sample Collector",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF20C6D3),
                      side: const BorderSide(
                        color: Color(0xFF20C6D3),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // =====================================================
        // LOGOUT
        // =====================================================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    ),
  );
}

// =====================================================
// PROFILE INFO ROW
// =====================================================

Widget _profileInfoRow(
  IconData icon,
  String title,
  String value,
) {
  return Row(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [

      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE6FAF8),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF20C6D3),
          size: 21,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}


Future<void> _showAddCollectorDialog() async {

  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final addressController =
      TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {

      return AlertDialog(
        title: const Text(
          "Add Sample Collector",
        ),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  labelText: "Collector Name",
                  prefixIcon:
                      Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText: "Phone",
                  prefixIcon:
                      Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    addressController,
                decoration:
                    const InputDecoration(
                  labelText: "Address",
                  prefixIcon:
                      Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF20C6D3),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {

              final name =
                  nameController.text.trim();

              final phone =
                  phoneController.text.trim();

              final address =
                  addressController.text.trim();

              if (name.isEmpty ||
                  phone.isEmpty) {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Name and phone are required",
                    ),
                  ),
                );

                return;
              }

              try {

                await ApiService
                    .addSampleCollector(
                  name: name,
                  phone: phone,
                  address: address,
                  labId:
                      labData?["_id"]
                              ?.toString() ??
                          "",
                  labName:
                      labData?["name"]
                              ?.toString() ??
                          labName,
                );

                Navigator.pop(
                  dialogContext,
                );

                await loadSampleCollectors();

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Sample collector added successfully",
                    ),
                  ),
                );

              } catch (e) {

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString(),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Add Collector",
            ),
          ),
        ],
      );
    },
   );
}

// ============================================================
// LAB TEST MANAGEMENT
// ============================================================


Future<void> _showLabTestManagement() async {
  await loadLabTests();

  if (!mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) {
      return LabTestManagementSheet(
        initialTests: List<Map<String, dynamic>>.from(tests),
        labId: labData?["_id"]?.toString() ?? "",
        labName: labData?["name"]?.toString() ?? labName,
        labPhone: labData?["phone"]?.toString() ?? labPhone,
      );
    },
  );

  if (!mounted) return;

  // Refresh the dashboard after the management sheet is closed.
  await loadLabTests();
}

// ============================================================
// CLOSE LABORATORY DASHBOARD STATE
// ============================================================

}


// ============================================================
// LAB TEST MANAGEMENT SHEET
// ============================================================
//
// IMPORTANT:
// This widget intentionally does NOT open another showDialog while
// the management bottom sheet is open.
//
// The old flow was:
// BottomSheet -> StatefulBuilder -> showDialog -> StatefulBuilder
//
// The form now lives inside the same bottom-sheet route. Therefore
// Cancel only changes the sheet's local state and does not pop a
// nested dialog/overlay route. This avoids the _dependents.isEmpty
// lifecycle assertion seen on Cancel.
// ============================================================

class LabTestManagementSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialTests;
  final String labId;
  final String labName;
  final String labPhone;

  const LabTestManagementSheet({
    super.key,
    required this.initialTests,
    required this.labId,
    required this.labName,
    required this.labPhone,
  });

  @override
  State<LabTestManagementSheet> createState() =>
      _LabTestManagementSheetState();
}

class _LabTestManagementSheetState
    extends State<LabTestManagementSheet> {
  late List<Map<String, dynamic>> tests;

  bool loading = false;
  bool saving = false;
  bool showForm = false;
  bool showDeleteConfirmation = false;

  Map<String, dynamic>? editingTest;
  Map<String, dynamic>? pendingDeleteTest;

  final TextEditingController testNameController =
      TextEditingController();
  final TextEditingController categoryController =
      TextEditingController();
  final TextEditingController priceController =
      TextEditingController();
  final TextEditingController sampleTypeController =
      TextEditingController();
  final TextEditingController reportTimeController =
      TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();

  bool get isEdit => editingTest != null;

  @override
  void initState() {
    super.initState();

    tests = List<Map<String, dynamic>>.from(
      widget.initialTests,
    );

    _refreshTests();
  }

  @override
  void dispose() {
    testNameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    sampleTypeController.dispose();
    reportTimeController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  Future<void> _refreshTests() async {
    if (widget.labId.trim().isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await ApiService.getLabTestsByLab(
        widget.labId,
      );

      if (!mounted) return;

      setState(() {
        tests = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint(
        "LAB TEST MANAGEMENT LOAD ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void _clearForm() {
    testNameController.clear();
    categoryController.clear();
    priceController.clear();
    sampleTypeController.clear();
    reportTimeController.clear();
    descriptionController.clear();
  }

  void _openAddForm() {
    _clearForm();

    setState(() {
      editingTest = null;
      showForm = true;
      saving = false;
    });
  }

  void _openEditForm(
    Map<String, dynamic> test,
  ) {
    testNameController.text =
        test["testName"]?.toString() ?? "";

    categoryController.text =
        test["category"]?.toString() ?? "";

    priceController.text =
        test["price"]?.toString() ?? "";

    sampleTypeController.text =
        test["sampleType"]?.toString() ?? "";

    reportTimeController.text =
        test["reportTime"]?.toString() ?? "";

    descriptionController.text =
        test["description"]?.toString() ?? "";

    setState(() {
      editingTest = Map<String, dynamic>.from(test);
      showForm = true;
      saving = false;
    });
  }

  void _cancelForm() {
    if (saving) return;

    // No Navigator.pop() here.
    // We only switch the existing bottom-sheet content back
    // to the test list. This avoids creating/deactivating a
    // second route for the Add/Edit form.
    setState(() {
      showForm = false;
      editingTest = null;
      saving = false;
    });

    _clearForm();
  }

  Future<void> _saveTest() async {
    if (saving) return;

    final testName =
        testNameController.text.trim();

    final category =
        categoryController.text.trim();

    final price =
        double.tryParse(
      priceController.text.trim(),
    );

    final sampleType =
        sampleTypeController.text.trim();

    final reportTime =
        reportTimeController.text.trim();

    final description =
        descriptionController.text.trim();

    if (testName.isEmpty) {
      _showMessage(
        "Test name is required",
      );
      return;
    }

    if (price == null || price < 0) {
      _showMessage(
        "Enter a valid price",
      );
      return;
    }

    if (!isEdit && widget.labId.trim().isEmpty) {
      _showMessage(
        "Lab ID not found",
      );
      return;
    }

    if (isEdit) {
      final testId =
          editingTest?["_id"]?.toString().trim() ?? "";

      if (testId.isEmpty) {
        _showMessage(
          "Lab test ID is missing",
        );
        return;
      }
    }

    setState(() {
      saving = true;
    });

    try {
      final Map<String, dynamic> result;

      if (isEdit) {
        final testId =
            editingTest!["_id"].toString().trim();

        result = await ApiService.updateLabTest(
          id: testId,
          testName: testName,
          category:
              category.isEmpty ? "General" : category,
          price: price,
          sampleType:
              sampleType.isEmpty ? "Blood" : sampleType,
          reportTime:
              reportTime.isEmpty ? "24 Hours" : reportTime,
          description: description,
        );
      } else {
        result = await ApiService.addLabTest(
          labId: widget.labId,
          labName: widget.labName,
          labPhone: widget.labPhone,
          testName: testName,
          category:
              category.isEmpty ? "General" : category,
          price: price,
          sampleType:
              sampleType.isEmpty ? "Blood" : sampleType,
          reportTime:
              reportTime.isEmpty ? "24 Hours" : reportTime,
          description: description,
        );
      }

      debugPrint(
        "LAB TEST SAVE RESULT = $result",
      );

      if (!mounted) return;

      if (result["success"] == true) {
        setState(() {
          saving = false;
          showForm = false;
          editingTest = null;
        });

        _clearForm();

        await _refreshTests();

        if (!mounted) return;

        _showMessage(
          isEdit
              ? "Lab test updated successfully"
              : "Lab test added successfully",
        );

        return;
      }

      setState(() {
        saving = false;
      });

      _showMessage(
        result["message"]?.toString() ??
            "Unable to save lab test",
      );
    } catch (e) {
      debugPrint(
        "LAB TEST SAVE ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    }
  }

  void _requestDelete(
    Map<String, dynamic> test,
  ) {
    if (saving) return;

    setState(() {
      pendingDeleteTest =
          Map<String, dynamic>.from(test);
      showDeleteConfirmation = true;
    });
  }

  void _cancelDelete() {
    setState(() {
      pendingDeleteTest = null;
      showDeleteConfirmation = false;
    });
  }

  Future<void> _confirmDelete() async {
    final test = pendingDeleteTest;

    if (test == null) {
      return;
    }

    final testId =
        test["_id"]?.toString().trim() ?? "";

    if (testId.isEmpty) {
      _cancelDelete();
      _showMessage(
        "Lab test ID is missing",
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final result =
          await ApiService.deleteLabTest(testId);

      if (!mounted) return;

      if (result["success"] == true) {
        setState(() {
          saving = false;
          pendingDeleteTest = null;
          showDeleteConfirmation = false;
        });

        await _refreshTests();

        if (!mounted) return;

        _showMessage(
          "Lab test deleted successfully",
        );
      } else {
        setState(() {
          saving = false;
        });

        _showMessage(
          result["message"]?.toString() ??
              "Failed to delete test",
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget _labTestInfoChip(
    IconData icon,
    String text,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF20C6D3),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            12,
            18,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed:
                    saving ? null : _cancelForm,
                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lab Test",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Add or update test details",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              children: [
                TextField(
                  controller:
                      testNameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Test Name *",
                    prefixIcon:
                        Icon(Icons.science),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      categoryController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: "Category",
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      priceController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: "Price *",
                    prefixIcon: Icon(
                      Icons.currency_rupee,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      sampleTypeController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Sample Type",
                    prefixIcon: Icon(
                      Icons
                          .water_drop_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      reportTimeController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Report Time",
                    prefixIcon: Icon(
                      Icons.schedule,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller:
                      descriptionController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Description",
                    prefixIcon:
                        Icon(Icons.notes),
                    alignLabelWithHint:
                        true,
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : _cancelForm,
                        style:
                            OutlinedButton
                                .styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            52,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          "Cancel",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : _saveTest,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF20C6D3,
                          ),
                          foregroundColor:
                              Colors.white,
                          minimumSize:
                              const Size(
                            double.infinity,
                            52,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                isEdit
                                    ? "Update"
                                    : "Add Test",
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmation() {
    final testName =
        pendingDeleteTest?["testName"]
                ?.toString() ??
            "this test";

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            12,
            18,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed:
                    saving ? null : _cancelDelete,
                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delete Lab Test",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Confirm removal of this test",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(24),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.red.shade50,
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade700,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Delete Lab Test?",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Are you sure you want to delete "$testName"?',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : _cancelDelete,
                            style:
                                OutlinedButton
                                    .styleFrom(
                              minimumSize:
                                  const Size(
                                double.infinity,
                                50,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              "Cancel",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : _confirmDelete,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.red,
                              foregroundColor:
                                  Colors.white,
                              minimumSize:
                                  const Size(
                                double.infinity,
                                50,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Delete",
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestList() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.biotech_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              "No lab tests added",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Add your first test",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        30,
      ),
      itemCount: tests.length,
      itemBuilder:
          (context, index) {
        final test = tests[index];

        final bool isActive =
            test["isActive"] == true;

        final String testName =
            test["testName"]?.toString() ??
                "Unnamed Test";

        final String category =
            test["category"]?.toString() ??
                "General";

        final String price =
            test["price"]?.toString() ??
                "0";

        final String sampleType =
            test["sampleType"]?.toString() ??
                "Blood";

        final String reportTime =
            test["reportTime"]?.toString() ??
                "24 Hours";

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 14,
          ),
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE6FAF8,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: Color(
                        0xFF20C6D3,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          testName,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          category,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected:
                        (value) async {
                      if (value ==
                          "edit") {
                        _openEditForm(test);
                      }

                      if (value ==
                          "delete") {
                        _requestDelete(test);
                      }
                    },
                    itemBuilder:
                        (context) =>
                            const [
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color:
                                  Colors.red,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  _labTestInfoChip(
                    Icons.currency_rupee,
                    "₹$price",
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _labTestInfoChip(
                    Icons.water_drop_outlined,
                    sampleType,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  _labTestInfoChip(
                    Icons.schedule,
                    reportTime,
                  ),
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isActive
                          ? "Active — visible for booking"
                          : "Inactive — hidden from booking",
                      style: TextStyle(
                        color: isActive
                            ? Colors.green
                            : Colors.grey,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeThumbColor:
                        const Color(
                      0xFF20C6D3,
                    ),
                    onChanged:
                        (value) async {
                      final id =
                          test["_id"]
                                  ?.toString() ??
                              "";

                      if (id.isEmpty) {
                        return;
                      }

                      try {
                        final result =
                            await ApiService
                                .toggleLabTest(
                          id,
                        );

                        if (!mounted) {
                          return;
                        }

                        if (result[
                                "success"] ==
                            true) {
                          await _refreshTests();
                        } else {
                          _showMessage(
                            result[
                                    "message"]
                                ?.toString() ??
                                "Failed to update test",
                          );
                        }
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }

                        _showMessage(
                          e
                              .toString()
                              .replaceFirst(
                                "Exception: ",
                                "",
                              ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottomInset =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return AnimatedPadding(
      duration:
          const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: bottomInset,
      ),
      child: Container(
        height:
            MediaQuery.of(context)
                    .size
                    .height *
                0.88,
        decoration:
            const BoxDecoration(
          color: Color(0xFFF4F7FB),
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: showDeleteConfirmation
            ? _buildDeleteConfirmation()
            : showForm
                ? _buildForm()
                : Column(
                    children: [
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      12,
                      18,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFE6FAF8,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons.biotech,
                            color: Color(
                              0xFF20C6D3,
                            ),
                            size: 28,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                "Lab Test Management",
                                style:
                                    TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                "Manage tests offered by your laboratory",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop();
                          },
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _openAddForm,
                        icon:
                            const Icon(
                          Icons.add,
                        ),
                        label:
                            const Text(
                          "Add New Lab Test",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF20C6D3,
                          ),
                          foregroundColor:
                              Colors.white,
                          minimumSize:
                              const Size(
                            double.infinity,
                            52,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTestList(),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================
// LAB REPORT VIEWER
// ============================================================

class LabReportViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> reports;

  const LabReportViewerPage({
    super.key,
    required this.reports,
  });

  @override
  State<LabReportViewerPage> createState() =>
      _LabReportViewerPageState();
}

class _LabReportViewerPageState
    extends State<LabReportViewerPage> {

  late PageController pageController;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.reports.length == 1
              ? (widget.reports.isNotEmpty &&
                      widget.reports[currentPage]["reportName"]
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true
                  ? widget.reports[currentPage]["reportName"]
                      .toString()
                      .trim()
                  : "Lab Report")
              : "${widget.reports[currentPage]["reportName"]?.toString().trim().isNotEmpty == true ? widget.reports[currentPage]["reportName"].toString().trim() : "Report ${currentPage + 1}"} (${currentPage + 1}/${widget.reports.length})",
        ),
      ),

      body: Column(
        children: [

          // ====================================================
          // REPORT PAGES
          // ====================================================

          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: widget.reports.length,

              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },

              itemBuilder: (context, index) {

                final report =
                    widget.reports[index];

                final fileUrl =
                    report["fileUrl"]?.toString() ?? "";

                final fileType =
                    report["fileType"]?.toString().toLowerCase() ?? "";

                if (fileUrl.isEmpty) {
                  return const Center(
                    child: Text(
                      "Report file not available",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                // ==================================================
                // IMAGE REPORT
                // ==================================================

                if (fileType.startsWith("image") ||
                    fileUrl.toLowerCase().endsWith(".jpg") ||
                    fileUrl.toLowerCase().endsWith(".jpeg") ||
                    fileUrl.toLowerCase().endsWith(".png") ||
                    fileUrl.toLowerCase().endsWith(".webp")) {

                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Center(
                      child: Image.network(
                        fileUrl,
                        fit: BoxFit.contain,

                        loadingBuilder:
                            (context, child, loadingProgress) {

                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },

                        errorBuilder:
                            (context, error, stackTrace) {

                          return const Center(
                            child: Text(
                              "Unable to load report",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                // ==================================================
                // OTHER FILE TYPE
                // ==================================================

                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(30),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 80,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          report["reportName"]
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? report["reportName"].toString().trim()
                              : "Report ${widget.reports.indexOf(report) + 1}",
                          textAlign:
                              TextAlign.center,

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "This report type cannot be previewed here.",
                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ====================================================
          // PAGE INDICATOR
          // ====================================================

          if (widget.reports.length > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 12,
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: List.generate(
                  widget.reports.length,
                  (index) {

                    return Container(
                      width: 9,
                      height: 9,

                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: index == currentPage
                            ? const Color(
                                0xFF20C6D3,
                              )
                            : Colors.white38,
                      ),
                    );
                  },
                ),
              ),
            ),

          // ====================================================
          // PAGE NAME
          // ====================================================

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              18,
            ),

            child: Text(
              widget.reports[currentPage]["reportName"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? widget.reports[currentPage]["reportName"]
                      .toString()
                      .trim()
                  : "Report ${currentPage + 1}",

              textAlign: TextAlign.center,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}