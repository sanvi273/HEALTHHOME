import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthhome/screens/onboarding_screen.dart';
import '../services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../pharmacy/add_medicine_page.dart';
import '../pharmacy/my_medicines_page.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  int currentIndex = 0;

  Map<String, dynamic>? pharmacyData;

  bool isLoading = true;

  String pharmacyName = "";
  String pharmacyPhone = "";

List<dynamic> orders = [];
List<dynamic> acceptedOrders = [];
List<dynamic> medicines = [];

List<Map<String, dynamic>> deliveryPartners = [];

bool isRemovingPartner = false;

// Total pharmacy revenue
int totalRevenue = 0;

String _mongoIdFrom(dynamic value) {
  if (value == null) {
    return "";
  }

  if (value is String) {
    return value.trim();
  }

  if (value is Map) {
    final nested =
        value["_id"] ?? value[r"$oid"] ?? value["oid"] ?? value["id"];

    if (nested != null && !identical(nested, value)) {
      return _mongoIdFrom(nested);
    }
  }

  return value.toString().trim();
}

  // ============================================================
  // LOAD PHARMACY
  // ============================================================

  Future<void> loadPharmacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final phone = prefs.getString("pharmacyPhone") ??
          prefs.getString("userPhone") ??
          "";

      final savedName =
          prefs.getString("pharmacyName") ?? prefs.getString("userName") ?? "";

      if (phone.isEmpty) {
        debugPrint("❌ Pharmacy phone not found");

        if (!mounted) return;

        setState(() {
          pharmacyName = savedName;
          pharmacyPhone = "";
          isLoading = false;
        });

        return;
      }

      debugPrint("================================");
      debugPrint("LOADING PHARMACY PROFILE");
      debugPrint("PHARMACY PHONE = $phone");
      debugPrint("================================");

      final response = await ApiService.getPharmacyProfile(phone);

      debugPrint(
        "PHARMACY PROFILE RESPONSE = $response",
      );

      if (response["success"] == true && response["pharmacy"] != null) {
        final pharmacy = Map<String, dynamic>.from(
          response["pharmacy"],
        );

        pharmacyData = pharmacy;

        pharmacyName = pharmacy["name"]?.toString() ?? savedName;

        pharmacyPhone = pharmacy["phone"]?.toString() ?? phone;

        await prefs.setString(
          "pharmacyName",
          pharmacyName,
        );

        await prefs.setString(
          "pharmacyPhone",
          pharmacyPhone,
        );

        debugPrint(
          "✅ Pharmacy profile loaded from MongoDB",
        );
      } else {
        debugPrint(
          "❌ Pharmacy profile not found",
        );

        pharmacyData = {};

        pharmacyName = savedName;
        pharmacyPhone = phone;
      }
    } catch (e) {
      debugPrint(
        "❌ LOAD PHARMACY ERROR = $e",
      );

      try {
        final prefs = await SharedPreferences.getInstance();

        pharmacyName = prefs.getString("pharmacyName") ??
            prefs.getString("userName") ??
            "";

        pharmacyPhone = prefs.getString("pharmacyPhone") ??
            prefs.getString("userPhone") ??
            "";
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // LOAD PHARMACY INFO
  // ============================================================

  Future<void> loadPharmacyInfo() async {
    final prefs = await SharedPreferences.getInstance();

    pharmacyName =
        prefs.getString("pharmacyName") ?? prefs.getString("userName") ?? "";

    pharmacyPhone =
        prefs.getString("pharmacyPhone") ?? prefs.getString("userPhone") ?? "";
  }

  // ============================================================
  // LOAD DELIVERY PARTNERS FROM MONGODB
  // ============================================================

Future<void> loadDeliveryPartners() async {
  try {
    final phone = pharmacyPhone.trim().isNotEmpty
        ? pharmacyPhone.trim()
        : (pharmacyData?["phone"]?.toString() ?? "").trim();

    if (phone.isEmpty) {
      if (mounted) {
        setState(() {
          deliveryPartners = [];
        });
      } else {
        deliveryPartners = [];
      }

      return;
    }

    final response = await ApiService.getDeliveryPartners(phone);

    debugPrint(
      "DELIVERY PARTNERS RESPONSE = $response",
    );

    if (response["success"] != true) {
      debugPrint(
        "❌ GET DELIVERY PARTNERS FAILED: "
        "${response["message"]}",
      );
      return;
    }

    final rawPartners = response["deliveryPartners"];

    final newPartners = <Map<String, dynamic>>[];

    if (rawPartners is List) {
      for (final item in rawPartners) {
        if (item is Map) {
          final id = _mongoIdFrom(item["_id"]).isNotEmpty
              ? _mongoIdFrom(item["_id"])
              : _mongoIdFrom(item["id"]);
          final name = item["name"]?.toString().trim() ?? "";
          final partnerPhone =
              item["phone"]?.toString().trim() ?? "";

          if (name.isNotEmpty && partnerPhone.isNotEmpty) {
            newPartners.add({
              "_id": id,
              "name": name,
              "phone": partnerPhone,
            });
          }
        }
      }
    }

    if (!mounted) {
      deliveryPartners = newPartners;
      return;
    }

    setState(() {
      deliveryPartners = newPartners;
    });

    debugPrint(
      "✅ DELIVERY PARTNERS UPDATED = $deliveryPartners",
    );
  } catch (e) {
    debugPrint(
      "❌ LOAD DELIVERY PARTNERS ERROR = $e",
    );
  }
}

  // ============================================================
  // ADD DELIVERY PARTNER
  // PERSISTENT STORAGE = MONGODB
  // ============================================================

  Future<void> addDeliveryPartnerDialog() async {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isAdding = false;

  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Add Delivery Partner",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      enabled: !isAdding,
                      decoration: InputDecoration(
                        labelText: "Partner Name",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      enabled: !isAdding,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(Icons.phone),
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter partner name.",
                                ),
                              ),
                            );
                            return;
                          }

                          if (name.length < 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter a valid partner name.",
                                ),
                              ),
                            );
                            return;
                          }

                          if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Enter a valid 10-digit phone number.",
                                ),
                              ),
                            );
                            return;
                          }

                          final currentPharmacyPhone =
    pharmacyPhone.trim().isNotEmpty
        ? pharmacyPhone.trim()
        : (pharmacyData?["phone"]?.toString() ?? "").trim();
                          
                          

                          if (currentPharmacyPhone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pharmacy phone number not found.",
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isAdding = true;
                          });

                          try {
                            final response =
                                await ApiService.addDeliveryPartner(
                              pharmacyPhone: currentPharmacyPhone,
                              name: name,
                              phone: phone,
                            );

                            if (!mounted) return;

                            if (response["success"] == true) {
                              Navigator.of(dialogContext).pop(true);
                            } else {
                              setDialogState(() {
                                isAdding = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response["message"]?.toString() ??
                                        "Failed to add delivery partner.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isAdding = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error: $e",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00C2CB),
                    foregroundColor: Colors.white,
                  ),
                  child: isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    // Dialog has completely closed before we update the main page.
    if (!mounted) return;

   if (result == true) {
  // Load latest partners from MongoDB
  await loadDeliveryPartners();

  if (!mounted) return;

  // IMPORTANT:
  // Rebuild the Profile UI immediately
  setState(() {});

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Delivery partner added successfully.",
      ),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}
  } finally {
    nameController.dispose();
    phoneController.dispose();
  }
}
  // ============================================================
  // REMOVE DELIVERY PARTNER FROM MONGODB
  // ============================================================

Future<void> removeDeliveryPartner(int index) async {
  if (isRemovingPartner) {
    return;
  }

  if (index < 0 || index >= deliveryPartners.length) {
    return;
  }

  final partner = Map<String, dynamic>.from(
    deliveryPartners[index],
  );

  final partnerId = _mongoIdFrom(partner["_id"]).isNotEmpty
      ? _mongoIdFrom(partner["_id"])
      : _mongoIdFrom(partner["id"]);

  final currentPharmacyPhone =
      pharmacyPhone.trim().isNotEmpty
          ? pharmacyPhone.trim()
          : (pharmacyData?["phone"]?.toString() ?? "").trim();

  debugPrint("================================");
  debugPrint("DELETE DELIVERY PARTNER");
  debugPrint("DELETE PARTNER RAW = $partner");
  debugPrint("DELETE PARTNER ID = $partnerId");
  debugPrint("DELETE PHARMACY PHONE = $currentPharmacyPhone");
  debugPrint("================================");

  if (partnerId.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Delivery partner ID is missing. Cannot delete from MongoDB.",
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (currentPharmacyPhone.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Pharmacy phone number is missing. Cannot delete from MongoDB.",
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          "Remove Delivery Partner?",
        ),
        content: Text(
          "Remove ${partner["name"] ?? "this partner"} "
          "from the pharmacy list?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Remove"),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  if (!mounted) return;

  setState(() {
    isRemovingPartner = true;
  });

  try {
    final response =
        await ApiService.deleteDeliveryPartner(
      pharmacyPhone: currentPharmacyPhone,
      partnerId: partnerId,
    );

    debugPrint(
      "DELETE DELIVERY PARTNER RESPONSE = $response",
    );

    if (!mounted) return;

    if (response["success"] == true) {
      // Reload from MongoDB
      await loadDeliveryPartners();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Delivery partner removed successfully.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"]?.toString() ??
                "Failed to remove delivery partner.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    debugPrint(
      "❌ DELETE DELIVERY PARTNER ERROR = $e",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Error removing delivery partner: $e",
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isRemovingPartner = false;
      });
    } else {
      isRemovingPartner = false;
    }
  }
}

  // ============================================================
  // SELECT DELIVERY PARTNER
  // ============================================================

  Future<void> showDeliveryPartnerSheet(
    Map<String, dynamic> order,
  ) async {
    await loadDeliveryPartners();

    if (!mounted) return;

    if (deliveryPartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No delivery partner is available. Add a partner from Profile first.",
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final selectedPartner = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(
                    sheetContext,
                  ).size.height *
                  0.72,
            ),
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xffF4F8F8),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Assign Delivery Partner",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Select partner for ${order["patientName"]?.toString() ?? "patient"}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ...deliveryPartners.map(
                    (partner) {
                      final name = partner["name"] ?? "Delivery Partner";

                      final phone = partner["phone"] ?? "";

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: const CircleAvatar(
                            radius: 27,
                            backgroundColor: Color(
                              0xFFE8FAFB,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Color(
                                0xFF20C6D3,
                              ),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: 3,
                            ),
                            child: Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),

                          // IMPORTANT:
                          // Return partner first.
                          // API call happens AFTER
                          // bottom sheet is completely
                          // closed.
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                              partner,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (selectedPartner == null) {
      return;
    }

    await assignDeliveryPartnerToOrder(
      order,
      selectedPartner,
    );
  }

  // ============================================================
  // ASSIGN DELIVERY PARTNER
  // ============================================================

  Future<void> assignDeliveryPartnerToOrder(
    Map<String, dynamic> order,
    Map<String, String> partner,
  ) async {
    final orderId = order["_id"]?.toString() ?? "";

    final name = partner["name"]?.trim() ?? "";

    final phone = partner["phone"]?.trim() ?? "";

    if (orderId.isEmpty || name.isEmpty || phone.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Delivery partner information is incomplete.",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    debugPrint(
      "====================================",
    );
    debugPrint(
      "ASSIGNING DELIVERY PARTNER",
    );
    debugPrint(
      "ORDER ID = $orderId",
    );
    debugPrint(
      "PARTNER NAME = $name",
    );
    debugPrint(
      "PARTNER PHONE = $phone",
    );
    debugPrint(
      "====================================",
    );

    final result = await ApiService.assignDeliveryAgent(
      orderId: orderId,
      deliveryAgentName: name,
      deliveryAgentPhone: phone,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      debugPrint(
        "✅ DELIVERY PARTNER ASSIGNED",
      );

      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$name assigned successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint(
        "❌ ASSIGN FAILED = ${result["message"]}",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"]?.toString() ??
                "Unable to assign delivery partner.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOAD MEDICINES
  // ============================================================

  Future<void> loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final phone = prefs.getString("pharmacyPhone") ??
          prefs.getString("userPhone") ??
          "";

      final allMedicines = await ApiService.getMedicines();

      debugPrint(
        "ALL MEDICINES = $allMedicines",
      );

      final filteredMedicines = allMedicines.where((medicine) {
        return medicine["pharmacyPhone"]?.toString() == phone;
      }).toList();

      if (!mounted) return;

      setState(() {
        medicines = filteredMedicines;
      });
    } catch (e) {
      debugPrint(
        "❌ LOAD MEDICINES ERROR = $e",
      );
    }
  }

Future<void> loadOrders() async {
  try {
    if (pharmacyData == null ||
        pharmacyData!["_id"] == null) {
      debugPrint("❌ Pharmacy ID not found");
      return;
    }

    final response = await ApiService.getPharmacyOrders(
      pharmacyData!["_id"].toString(),
    );

    if (response["success"] != true) {
      debugPrint("❌ Failed to load pharmacy orders");
      return;
    }

    final List<dynamic> allOrders =
        List<dynamic>.from(response["orders"] ?? []);

    // ==========================================================
    // PENDING ORDERS
    // ==========================================================

    final List<dynamic> pendingOrders = allOrders
        .where(
          (order) =>
              order["status"]?.toString() == "Pending",
        )
        .toList();

    // ==========================================================
    // ACTIVE DELIVERY ORDERS
    //
    // Delivered orders are intentionally NOT included.
    // They disappear automatically from the Delivery page.
    // ==========================================================

    final List<dynamic> activeOrders = allOrders
        .where((order) {
          final status =
              order["status"]?.toString() ?? "";

          return status == "Accepted" ||
              status == "Packed" ||
              status == "Out for Delivery";
        })
        .toList();

    // ==========================================================
    // NEWEST PENDING ORDER FIRST
    // ==========================================================

    pendingOrders.sort((a, b) {
      final aDate =
          DateTime.tryParse(
                a["createdAt"]?.toString() ?? "",
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      final bDate =
          DateTime.tryParse(
                b["createdAt"]?.toString() ?? "",
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    // ==========================================================
    // NEWEST ACCEPTED ORDER FIRST
    //
    // acceptedAt is preferred.
    // updatedAt is fallback for old orders.
    // ==========================================================

    activeOrders.sort((a, b) {
      final aDate =
          DateTime.tryParse(
                a["acceptedAt"]?.toString() ??
                    a["updatedAt"]?.toString() ??
                    a["createdAt"]?.toString() ??
                    "",
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      final bDate =
          DateTime.tryParse(
                b["acceptedAt"]?.toString() ??
                    b["updatedAt"]?.toString() ??
                    b["createdAt"]?.toString() ??
                    "",
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    // ==========================================================
    // REVENUE
    //
    // IMPORTANT:
    // Include Delivered orders in revenue calculation.
    // Otherwise removing Delivered orders from the screen
    // would incorrectly reduce the revenue.
    // ==========================================================

    int calculatedRevenue = 0;

    for (final order in allOrders) {
      final status =
          order["status"]?.toString() ?? "";

      if (status == "Accepted" ||
          status == "Packed" ||
          status == "Out for Delivery" ||
          status == "Delivered") {
        final amount =
            num.tryParse(
                  order["totalAmount"]?.toString() ?? "",
                ) ??
                0;

        calculatedRevenue += amount.toInt();
      }
    }

    if (!mounted) return;

    setState(() {
      orders = pendingOrders;
      acceptedOrders = activeOrders;
      totalRevenue = calculatedRevenue;
    });

    debugPrint(
      "========== PHARMACY ORDERS ==========",
    );
    debugPrint(
      "Pending = ${orders.length}",
    );
    debugPrint(
      "Active Delivery = ${acceptedOrders.length}",
    );
    debugPrint(
      "Revenue = ₹$totalRevenue",
    );
  } catch (e) {
    debugPrint(
      "❌ LOAD PHARMACY ORDERS ERROR = $e",
    );
  }
}

// ============================================================
// REVENUE
// ============================================================

int calculateRevenue() {
  return totalRevenue;
}

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    initializeDashboard();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initializeDashboard() async {
    await loadPharmacy();

    if (!mounted) return;

    await loadPharmacyInfo();

    if (!mounted) return;

    await loadDeliveryPartners();

    if (!mounted) return;

    await loadOrders();

    if (!mounted) return;

    await loadMedicines();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      body: IndexedStack(
        index: currentIndex,
        children: [
          OrdersPage(
            context: context,
            pharmacyData: pharmacyData,
            pharmacyName: pharmacyName,
            orders: orders,
            delivered: acceptedOrders,
            revenue: calculateRevenue(),
            onAccept: (index) async {
              if (index < 0 || index >= orders.length) return;

              final orderId = orders[index]["_id"]?.toString() ?? "";
              if (orderId.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Order ID not found."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await ApiService.updateOrderStatus(
                orderId: orderId,
                status: "Accepted",
              );

              if (!mounted) return;

              if (result["success"] != true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result["message"]?.toString() ??
                          "Unable to accept order.",
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await loadOrders();
              if (!mounted) return;

              Map<String, dynamic>? acceptedOrder;
              for (final item in acceptedOrders) {
                if (item["_id"]?.toString() == orderId) {
                  acceptedOrder = Map<String, dynamic>.from(item);
                  break;
                }
              }

              if (acceptedOrder == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Order accepted, but order details could not be loaded.",
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await showDeliveryPartnerSheet(acceptedOrder);
            },
            onReject: (index) async {
              if (index < 0 || index >= orders.length) return;

              final orderId = orders[index]["_id"]?.toString() ?? "";
              if (orderId.isEmpty) return;

              final result = await ApiService.updateOrderStatus(
                orderId: orderId,
                status: "Rejected",
              );

              if (!mounted) return;
              if (result["success"] == true) {
                await loadOrders();
              }
            },
          ),

          DeliveryPage(
            delivered: List<dynamic>.from(acceptedOrders),
            refreshOrders: loadOrders,
            updateStatus: (orderId, status) async {
              await ApiService.updateOrderStatus(
                orderId: orderId,
                status: status,
              );
              if (!mounted) return;
              await loadOrders();
            },
           partners: deliveryPartners.map((partner) {
  return {
    "name": partner["name"]?.toString() ?? "",
    "phone": partner["phone"]?.toString() ?? "",
  };
}).toList(),
            onPartnersChanged: (updatedPartners) async {
              if (!mounted) return;

              setState(() {
                deliveryPartners = updatedPartners
                    .map(
                      (partner) => {
                        "_id": partner["_id"]?.toString() ?? "",
                        "name": partner["name"]?.toString() ?? "",
                        "phone": partner["phone"]?.toString() ?? "",
                      },
                    )
                    .toList();
              });

              // Delivery partners are stored in MongoDB.
              // Do not save them to SharedPreferences here.
              await loadDeliveryPartners();
            },
            assignPartner: (order) async {
              await showDeliveryPartnerSheet(order);
            },
          ),

          InventoryPage(
            inventory: medicines,
          ),

          profilePage(),
        ],
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(
          0xff00C2CB,
        ),
        unselectedItemColor: Colors.grey,
        onTap: (value) {
  if (!mounted) return;

  if (currentIndex == value) {
    return;
  }

  setState(() {
    currentIndex = value;
  });

},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_bag,
            ),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.delivery_dining,
            ),
            label: "Delivery",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.inventory_2,
            ),
            label: "Inventory",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// ================= ORDERS PAGE =================

class OrdersPage extends StatelessWidget {
  final BuildContext context;
  final Map<String, dynamic>? pharmacyData;

  final List orders;
  final String pharmacyName;
  final List delivered;
  final int revenue;

  final Future<void> Function(int) onAccept;
  final Function(int) onReject;

  const OrdersPage({
    super.key,
    required this.context,
    required this.pharmacyData,
    required this.pharmacyName,
    required this.orders,
    required this.delivered,
    required this.revenue,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ================= HEADER =================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff14B8A6),
                  Color(0xff2DD4BF),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  pharmacyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pharmacyData?["address"] ?? "",
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    dashboardItem(
                      orders.length.toString(),
                      "Pending",
                    ),
                    dashboardItem(
                      delivered.length.toString(),
                      "Delivery",
                    ),
                    dashboardItem(
                      "₹$revenue",
                      "Revenue",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14B8A6),
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Add Medicine",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddMedicinePage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14B8A6),
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.medication,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "My Medicines",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyMedicinesPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      "No Pending Orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      final totalAmount = num.tryParse(
                            order["totalAmount"]?.toString() ?? "",
                          ) ??
                          0;

                      final orderType =
                          order["orderType"]?.toString().toUpperCase() ?? "";

                      final isPendingPrescription =
                          orderType == "PRESCRIPTION" && totalAmount <= 0;

                      return orderCard(
                        index: index,
                        name: order["patientName"]?.toString() ?? "Patient",
                        patientPhone: order["patientPhone"]?.toString() ??
                            order["patientId"]?.toString() ??
                            "",
                        medicine: order["medicines"] != null
                            ? (order["medicines"] as List)
                                .map(
                                  (e) => e["medicineName"],
                                )
                                .join(", ")
                            : "Prescription Order",
                        address: order["address"]?.toString() ?? "No Address",
                        notes: order["notes"]?.toString() ?? "",
                        imageUrl: order["prescriptionImage"]?.toString() ?? "",
                        price: isPendingPrescription
                            ? "Amount pending pharmacy confirmation"
                            : "₹${totalAmount.toStringAsFixed(0)}",
                      );
                    },
                  ),
          ),
        ],
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

Widget orderCard({
  required int index,
  required String name,
  required String patientPhone,
  required String medicine,
  required String address,
  required String notes,
  required String imageUrl,
  required String price,
}) {
  final bool amountPending =
      price == "Amount pending pharmacy confirmation";

  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // =====================================================
        // PATIENT
        // =====================================================

        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xff14B8A6),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    patientPhone,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // =====================================================
        // MEDICINE NAME
        // =====================================================

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.medication,
              color: Color(0xff14B8A6),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                medicine,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // =====================================================
        // ADDRESS
        // =====================================================

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),

        // =====================================================
        // TOTAL AMOUNT
        // =====================================================

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: amountPending
                ? const Color(0xfffff7ed)
                : const Color(0xffecfdf5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: amountPending
                  ? const Color(0xffffd7aa)
                  : const Color(0xffa7f3d0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.currency_rupee,
                color: amountPending
                    ? Colors.orange
                    : const Color(0xff14B8A6),
                size: 26,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  amountPending
                      ? "Amount Pending"
                      : "Total Amount",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Flexible(
                child: Text(
                  price,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: amountPending
                        ? Colors.orange
                        : const Color(0xff14B8A6),
                    fontSize: amountPending ? 14 : 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // =====================================================
        // NOTES
        // =====================================================

        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),

          Text(
            "Notes : $notes",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // =====================================================
        // PRESCRIPTION IMAGE
        // =====================================================

        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 15),

          GestureDetector(
            onTap: () => showFullScreenImage(
              context,
              imageUrl,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    loadingBuilder:
                        (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return Container(
                        height: 180,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child:
                            const CircularProgressIndicator(
                          color: Color(0xff14B8A6),
                        ),
                      );
                    },

                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 42,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Unable to load prescription",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 18,
                        ),

                        SizedBox(width: 6),

                        Text(
                          "Tap to view",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // =====================================================
        // ACCEPT / REJECT BUTTONS
        // =====================================================

        const SizedBox(height: 18),

        Row(
          children: [

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff14B8A6),
                  minimumSize:
                      const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                onPressed: () async {
                  await onAccept(index);
                },

                child: const Text(
                  "Accept",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize:
                      const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {
                  onReject(index);
                },

                child: const Text(
                  "Reject",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

}

// ================= PRESCRIPTION IMAGE VIEWER =================

void showFullScreenImage(
  BuildContext context,
  String imageUrl,
) {
  if (imageUrl.trim().isEmpty) return;

  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 60,
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Unable to load prescription image",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 15,
              child: SafeArea(
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Pinch to zoom • Drag to move",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ================= DELIVERY PARTNER SELECTION PAGE =================

class DeliveryAgentPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final List<Map<String, String>> partners;
  final Future<void> Function(List<Map<String, String>>) onPartnersChanged;

  const DeliveryAgentPage({
    super.key,
    required this.order,
    required this.partners,
    required this.onPartnersChanged,
  });

  @override
  State<DeliveryAgentPage> createState() => _DeliveryAgentPageState();
}

class _DeliveryAgentPageState extends State<DeliveryAgentPage> {
  late List<Map<String, String>> partners;
  bool isAssigning = false;
  bool isLoadingPartners = true;

  @override
  void initState() {
    super.initState();

    partners = widget.partners
        .map(
          (partner) => {
            "_id": partner["_id"]?.toString() ?? "",
            "name": partner["name"]?.toString() ?? "",
            "phone": partner["phone"]?.toString() ?? "",
          },
        )
        .toList();

    isLoadingPartners = false;
  }

  Future<void> addPartner() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Delivery Partner"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Partner Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter partner name";
                    }

                    if (value.trim().length < 2) {
                      return "Enter a valid name";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone),
                    counterText: "",
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? "";


                    if (!RegExp(r"^[0-9]{10}$").hasMatch(phone)) {
                      return "Enter a valid 10 digit number";
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff14B8A6),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (added != true) {
      nameController.dispose();
      phoneController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    final exists = partners.any(
      (partner) =>
          partner["phone"] == phone ||
          partner["name"]?.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This delivery partner already exists."),
            backgroundColor: Colors.orange,
          ),
        );
      }

      nameController.dispose();
      phoneController.dispose();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final pharmacyPhone = (prefs.getString("pharmacyPhone") ??
            prefs.getString("userPhone") ??
            "")
        .trim();

    if (pharmacyPhone.isEmpty) {
      nameController.dispose();
      phoneController.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pharmacy phone number not found."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await ApiService.addDeliveryPartner(
      pharmacyPhone: pharmacyPhone,
      name: name,
      phone: phone,
    );

    if (result["success"] != true) {
      nameController.dispose();
      phoneController.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["message"]?.toString() ??
                  "Unable to add delivery partner.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final newPartner = result["deliveryPartner"];

    setState(() {
      if (newPartner is Map) {
        partners.add({
          "_id": newPartner["_id"]?.toString() ?? "",
          "name": newPartner["name"]?.toString() ?? name,
          "phone": newPartner["phone"]?.toString() ?? phone,
        });
      } else {
        partners.add({
          "_id": "",
          "name": name,
          "phone": phone,
        });
      }
    });

    await widget.onPartnersChanged(partners);

    nameController.dispose();
    phoneController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery partner added."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> assignPartner(Map<String, String> partner) async {
    if (isAssigning) return;

    final orderId = widget.order["_id"]?.toString() ?? "";

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order ID not found."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isAssigning = true;
    });

    final result = await ApiService.assignDeliveryAgent(
      orderId: orderId,
      deliveryAgentName: partner["name"] ?? "",
      deliveryAgentPhone: partner["phone"] ?? "",
    );

    if (!mounted) return;

    setState(() {
      isAssigning = false;
    });

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${partner["name"] ?? "Delivery partner"} assigned successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"]?.toString() ??
                "Unable to assign delivery partner.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget partnerCard(
    Map<String, String> partner,
    int index,
  ) {
    final name = partner["name"] ?? "";
    final phone = partner["phone"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF5F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xffE6FFFB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xff14B8A6),
              size: 30,
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Available",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          isAssigning
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xff14B8A6),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff14B8A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => assignPartner(partner),
                  child: const Text(
                    "Assign",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.order["patientName"]?.toString() ?? "Patient";

    final address = widget.order["address"]?.toString() ?? "No Address";

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text("Select Delivery Partner"),
        backgroundColor: const Color(0xff14B8A6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Add Partner",
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: isAssigning ? null : addPartner,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Information",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xff14B8A6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(address),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        color: Color(0xff14B8A6),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${widget.order["totalAmount"] ?? 0}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Delivery Partners",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isAssigning ? null : addPartner,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xff14B8A6),
                    size: 32,
                  ),
                ),
              ],
            ),
            const Text(
              "Select a delivery partner for this order.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 15),
            if (isLoadingPartners)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Color(0xff14B8A6),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Loading Delivery Partners...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (partners.isEmpty)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      size: 55,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No Delivery Partners Added",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Add a delivery partner first.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff14B8A6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isAssigning ? null : addPartner,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Delivery Partner"),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                partners.length,
                (index) => partnerCard(
                  partners[index],
                  index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// DELIVERY OTP DIALOG
// ============================================================

class _DeliveryOtpDialog extends StatefulWidget {
  final String orderId;

  const _DeliveryOtpDialog({
    required this.orderId,
  });

  @override
  State<_DeliveryOtpDialog> createState() => _DeliveryOtpDialogState();
}

class _DeliveryOtpDialogState extends State<_DeliveryOtpDialog> {
  late final TextEditingController _otpController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 6-digit OTP."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.verifyDeliveryOtp(
        orderId: widget.orderId,
        otp: otp,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        // Return from the dialog first. The controller will be disposed
        // safely by this dialog's State.dispose() after the route is removed.
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"]?.toString() ?? "Invalid OTP.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP verification failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Color(0xff14B8A6),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Verify Delivery OTP",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Ask the patient for the 6-digit delivery OTP.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            textAlign: TextAlign.center,
            enabled: !_isLoading,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "000000",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                letterSpacing: 8,
              ),
              prefixIcon: const Icon(
                Icons.password,
                color: Color(0xff14B8A6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xff14B8A6),
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) {
              if (!_isLoading) {
                _verify();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff14B8A6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : _verify,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

// ================= DELIVERY PAGE =================

class DeliveryPage extends StatelessWidget {
  final List delivered;

  final Future<void> Function() refreshOrders;

  final Future<void> Function(
    String orderId,
    String status,
  ) updateStatus;

  final List<Map<String, String>> partners;

  final Future<void> Function(
    List<Map<String, String>>,
  ) onPartnersChanged;

  final Future<void> Function(
    Map<String, dynamic> order,
  ) assignPartner;

  const DeliveryPage({
    super.key,
    required this.delivered,
    required this.refreshOrders,
    required this.updateStatus,
    required this.partners,
    required this.onPartnersChanged,
    required this.assignPartner,
  });

  // ============================================================
  // SAFE STRING
  // ============================================================

  String stringValue(dynamic value) {
    if (value == null) {
      return "";
    }

    return value.toString().trim();
  }

  // ============================================================
  // CHECK DELIVERY PARTNER
  // ============================================================

  bool isPartnerAssigned(
    Map<String, dynamic> order,
  ) {
    return order["deliveryAgentAssigned"] == true ||
        order["deliveryAgentAssigned"]?.toString() == "true";
  }

  // ============================================================
  // DELIVERY OTP VERIFICATION
  // ============================================================

  Future<void> verifyDeliveryOtp(
    BuildContext pageContext,
    Map<String, dynamic> order,
  ) async {
    final orderId = stringValue(order["_id"]);

    if (orderId.isEmpty) {
      if (!pageContext.mounted) return;

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text("Order ID is missing."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // IMPORTANT:
    // The OTP TextEditingController is owned by the dialog widget itself.
    // Do NOT create/dispose it inside this async method.
    // This prevents Flutter from rebuilding TextField after its controller
    // has already been disposed.
    final verified = await showDialog<bool>(
      context: pageContext,
      barrierDismissible: false,
      builder: (_) => _DeliveryOtpDialog(
        orderId: orderId,
      ),
    );

    if (!pageContext.mounted) return;

    if (verified == true) {
      await refreshOrders();

      if (!pageContext.mounted) return;

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          content: Text(
            "Delivery OTP verified. Order marked as Delivered.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // GET MEDICINES
  // ============================================================

  List<Map<String, dynamic>> getMedicineItems(
    Map<String, dynamic> order,
  ) {
    final raw = order["medicines"];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .where(
          (item) =>
              stringValue(
                item["medicineName"],
              ).isNotEmpty &&
              stringValue(
                    item["medicineName"],
                  ) !=
                  "Prescription Order",
        )
        .toList();
  }

  // ============================================================
  // PRESCRIPTION URL
  // ============================================================

  String getPrescriptionUrl(
    Map<String, dynamic> order,
  ) {
    return stringValue(
      order["prescriptionImage"],
    );
  }

  // ============================================================
  // MEDICINE LIST
  // ============================================================

  Widget medicineList(
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xffF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffCCFBF1),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.medication_outlined,
                color: Color(0xff14B8A6),
              ),
              SizedBox(width: 8),
              Text(
                "Selected Medicines",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...List.generate(
            items.length,
            (index) {
              final medicine =
                  items[index];

              final name = stringValue(
                medicine["medicineName"],
              );

              final quantity =
                  medicine["quantity"] ?? 1;

              final price =
                  medicine["price"];

              return Container(
                margin: EdgeInsets.only(
                  bottom:
                      index == items.length - 1
                          ? 0
                          : 8,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,

                      alignment:
                          Alignment.center,

                      decoration: BoxDecoration(
                        color:
                            const Color(
                          0xff14B8A6,
                        ).withOpacity(0.12),

                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),

                      child: const Icon(
                        Icons.medication,
                        size: 19,
                        color:
                            Color(0xff14B8A6),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    Text(
                      "× $quantity",
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    if (price != null) ...[
                      const SizedBox(
                        width: 12,
                      ),

                      Text(
                        "₹$price",
                        style:
                            const TextStyle(
                          color:
                              Color(0xff14B8A6),
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRESCRIPTION CARD
  // ============================================================

  Widget prescriptionCard(
    BuildContext context,
    String imageUrl,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffFED7AA),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Prescription Order",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              showFullScreenImage(
                context,
                imageUrl,
              );
            },

            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),

              child: Stack(
                children: [
                  Image.network(
                    imageUrl,

                    height: 190,
                    width: double.infinity,

                    fit: BoxFit.cover,

                    loadingBuilder: (
                      context,
                      child,
                      loadingProgress,
                    ) {
                      if (loadingProgress ==
                          null) {
                        return child;
                      }

                      return Container(
                        height: 190,
                        width: double.infinity,

                        alignment:
                            Alignment.center,

                        color:
                            Colors.grey.shade100,

                        child:
                            const CircularProgressIndicator(
                          color:
                              Color(0xff14B8A6),
                        ),
                      );
                    },

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        height: 190,
                        width: double.infinity,

                        alignment:
                            Alignment.center,

                        color:
                            Colors.grey.shade100,

                        child: const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [
                            Icon(
                              Icons
                                  .broken_image_outlined,
                              size: 42,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Unable to load prescription",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  Positioned(
                    right: 10,
                    bottom: 10,

                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 18,
                          ),

                          SizedBox(width: 6),

                          Text(
                            "View Prescription",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w600,
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
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS DIALOG
  // ============================================================

  Future<void> showOrderDetails(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final items =
        getMedicineItems(order);

    final prescriptionUrl =
        getPrescriptionUrl(order);

    final hasPrescription =
        prescriptionUrl.isNotEmpty;

    final totalAmount =
        num.tryParse(
              order["totalAmount"]
                      ?.toString() ??
                  "",
            ) ??
            0;

    final status =
        stringValue(
          order["status"],
        );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delivery Details",
          ),

          content:
              SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  "Patient : ${stringValue(order["patientName"])}",
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Phone : ${stringValue(order["patientPhone"]).isNotEmpty ? stringValue(order["patientPhone"]) : stringValue(order["patientId"])}",
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Address : ${stringValue(order["address"])}",
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Payment : ${stringValue(order["paymentMethod"]).isNotEmpty ? stringValue(order["paymentMethod"]) : "Cash"}",
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Total : ₹${totalAmount.toStringAsFixed(0)}",
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  "Status : $status",
                ),

                if (items.isNotEmpty) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  medicineList(items),
                ],

                if (hasPrescription) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  SizedBox(
                    width: double.infinity,

                    child:
                        ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xff14B8A6,
                        ),
                      ),

                      icon: const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                      ),

                      label: const Text(
                        "View Prescription",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),

                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                        );

                        showFullScreenImage(
                          context,
                          prescriptionUrl,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STATUS ACTION
  // ============================================================

  Future<void> handleStatusAction(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final orderId =
        stringValue(order["_id"]);

    final status =
        stringValue(order["status"]);

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Order ID not found.",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // ==========================================================
    // ACCEPTED → PACKED
    // ==========================================================

    if (status == "Accepted") {
      await updateStatus(
        orderId,
        "Packed",
      );

      await refreshOrders();

      return;
    }

    // ==========================================================
    // PACKED → ASSIGN PARTNER
    // ==========================================================

    if (status == "Packed" &&
        !isPartnerAssigned(order)) {
      await assignPartner(order);

      await refreshOrders();

      return;
    }

    // ==========================================================
    // PACKED → OUT FOR DELIVERY
    // ==========================================================

    if (status == "Packed" &&
        isPartnerAssigned(order)) {
      await updateStatus(
        orderId,
        "Out for Delivery",
      );

      await refreshOrders();

      return;
    }

    // ==========================================================
    // OUT FOR DELIVERY → OTP
    // ==========================================================

    if (status == "Out for Delivery") {
      await verifyDeliveryOtp(
        context,
        order,
      );

      return;
    }

    // ==========================================================
    // DELIVERED
    // ==========================================================

    if (status == "Delivered") {
      return;
    }
  }

  // ============================================================
  // BUTTON LABEL
  // ============================================================

  String getActionLabel(
    Map<String, dynamic> order,
  ) {
    final status =
        stringValue(order["status"]);

    if (status == "Accepted") {
      return "Pack";
    }

    if (status == "Packed") {
      if (isPartnerAssigned(order)) {
        return "Dispatch";
      }

      return "Assign Partner";
    }

    if (status == "Out for Delivery") {
      return "Deliver";
    }

    if (status == "Delivered") {
      return "Completed";
    }

    return "Update";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (delivered.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: Colors.grey,
              ),

              SizedBox(
                height: 20,
              ),

              Text(
                "No Delivery Orders",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding:
            const EdgeInsets.all(16),

        itemCount:
            delivered.length,

        itemBuilder:
            (context, index) {
          final order =
              Map<String, dynamic>.from(
            delivered[index],
          );

          final items =
              getMedicineItems(order);

          final prescriptionUrl =
              getPrescriptionUrl(order);

          final hasPrescription =
              prescriptionUrl.isNotEmpty;

          final isMedicineOrder =
              items.isNotEmpty;

          final totalAmount =
              num.tryParse(
                    order["totalAmount"]
                            ?.toString() ??
                        "",
                  ) ??
                  0;

          final status =
              stringValue(
                order["status"],
              ).isEmpty
                  ? "Accepted"
                  : stringValue(
                      order["status"],
                    );

          final assigned =
              isPartnerAssigned(order);

          return Card(
            elevation: 4,

            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: Padding(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // PATIENT HEADER
                  // ==================================================

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,

                        backgroundColor:
                            const Color(
                          0xff14B8A6,
                        ).withOpacity(0.15),

                        child:
                            const Icon(
                          Icons.person,
                          color:
                              Color(0xff14B8A6),
                          size: 30,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              stringValue(
                                order[
                                    "patientName"],
                              ),

                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              stringValue(
                                order[
                                    "patientPhone"],
                              ).isNotEmpty
                                  ? stringValue(
                                      order[
                                          "patientPhone"],
                                    )
                                  : stringValue(
                                      order[
                                          "patientId"],
                                    ),

                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              status ==
                                      "Delivered"
                                  ? Colors.green
                                  : const Color(
                                      0xff14B8A6,
                                    ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                        ),

                        child: Text(
                          status,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Divider(),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // PRESCRIPTION
                  // ==================================================

                  if (hasPrescription)
                    prescriptionCard(
                      context,
                      prescriptionUrl,
                    ),

                  // ==================================================
                  // MEDICINES
                  // ==================================================

                  if (isMedicineOrder) ...[
                    if (hasPrescription)
                      const SizedBox(
                        height: 12,
                      ),

                    medicineList(
                      items,
                    ),
                  ],

                  // ==================================================
                  // EMPTY DETAILS
                  // ==================================================

                  if (!hasPrescription &&
                      !isMedicineOrder)
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade100,

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child:
                          const Text(
                        "Order details are not available.",
                        style:
                            TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // ADDRESS
                  // ==================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          stringValue(
                            order["address"],
                          ).isNotEmpty
                              ? stringValue(
                                  order[
                                      "address"],
                                )
                              : "No Address",
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // NOTES
                  // ==================================================

                  if (stringValue(
                    order["notes"],
                  ).isNotEmpty) ...[
                    const SizedBox(
                      height: 14,
                    ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Icon(
                          Icons.notes,
                          color:
                              Colors.orange,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            stringValue(
                              order["notes"],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ==================================================
                  // TOTAL
                  // ==================================================

                  Container(
                    width:
                        double.infinity,

                    margin:
                        const EdgeInsets.only(
                      top: 16,
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xffECFDF5,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      border: Border.all(
                        color:
                            const Color(
                          0xffA7F3D0,
                        ),
                      ),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .currency_rupee,
                          color:
                              Color(0xff14B8A6),
                          size: 28,
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        const Expanded(
                          child: Text(
                            "Total Amount",
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          "₹${totalAmount.toStringAsFixed(0)}",

                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(
                              0xff14B8A6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // DELIVERY PARTNER
                  // ==================================================

                  if (assigned &&
                      status !=
                          "Delivered") ...[
                    const SizedBox(
                      height: 16,
                    ),

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffECFDF5,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xffA7F3D0,
                          ),
                        ),
                      ),

                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor:
                                Color(
                              0xff14B8A6,
                            ),

                            child:
                                Icon(
                              Icons
                                  .local_shipping,
                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  "Delivery Partner",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize:
                                        13,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  stringValue(
                                    order[
                                        "deliveryAgentName"],
                                  ),

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  stringValue(
                                    order[
                                        "deliveryAgentPhone"],
                                  ),

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip:
                                "Edit Partner",

                            icon:
                                const Icon(
                              Icons.edit,
                              color:
                                  Color(
                                0xff14B8A6,
                              ),
                            ),

                            onPressed:
                                () async {
                              await assignPartner(
                                order,
                              );

                              await refreshOrders();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!assigned &&
                      status !=
                          "Delivered") ...[
                    const SizedBox(
                      height: 16,
                    ),

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffFFF7ED,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xffFED7AA,
                          ),
                        ),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .warning_amber_rounded,
                            color:
                                Colors.orange,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          const Expanded(
                            child:
                                Text(
                              "Delivery partner is not assigned.",
                              style:
                                  TextStyle(
                                color:
                                    Colors.orange,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed:
                                () async {
                              await assignPartner(
                                order,
                              );

                              await refreshOrders();
                            },

                            child:
                                const Text(
                              "Assign",
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xff14B8A6,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // BUTTONS
                  // ==================================================

                  Row(
                    children: [
                      // ==============================================
                      // DETAILS BUTTON
                      // ==============================================

                      Expanded(
                        child:
                            OutlinedButton.icon(
                          style:
                              OutlinedButton.styleFrom(
                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xff14B8A6,
                              ),
                            ),

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),

                          icon:
                              const Icon(
                            Icons.visibility,
                            color:
                                Color(
                              0xff14B8A6,
                            ),
                          ),

                          label:
                              const Text(
                            "Details",
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xff14B8A6,
                              ),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          onPressed: () {
                            showOrderDetails(
                              context,
                              order,
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      // ==============================================
                      // STATUS / OTP BUTTON
                      // ==============================================

                      Expanded(
                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                status ==
                                        "Delivered"
                                    ? Colors
                                        .green
                                    : const Color(
                                        0xff14B8A6,
                                      ),

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),

                          icon: Icon(
                            status ==
                                    "Delivered"
                                ? Icons
                                    .check_circle
                                : status ==
                                        "Out for Delivery"
                                    ? Icons
                                        .lock_outline
                                    : Icons
                                        .local_shipping,

                            color:
                                Colors.white,
                          ),

                          label: Text(
                            getActionLabel(
                              order,
                            ),

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          // IMPORTANT:
                          // No direct Delivered status call.
                          onPressed:
                              status ==
                                      "Delivered"
                                  ? null
                                  : () async {
                                      await handleStatusAction(
                                        context,
                                        order,
                                      );
                                    },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= INVENTORY PAGE =================

// ================= INVENTORY PAGE =================

// ================= INVENTORY PAGE =================

class InventoryPage extends StatefulWidget {
  final List inventory;

  const InventoryPage({
    super.key,
    required this.inventory,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    print("INVENTORY RECEIVED:");
    print(widget.inventory);

    if (widget.inventory.isEmpty) {
      return const Center(
        child: Text(
          "No Medicines Found",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.inventory.length,
        itemBuilder: (context, index) {
          final item = widget.inventory[index];

          int stock = int.tryParse(item["stock"].toString()) ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xff14B8A6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: Color(0xff14B8A6),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["medicineName"] ?? "",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item["category"] ?? "Tablet",
                          ),
                          Text(
                            "₹${item["price"]}",
                            style: const TextStyle(
                              color: Color(0xff14B8A6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stock > 20 ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stock > 20 ? "In Stock" : "Low",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Stock: ${item["stock"]}",
                ),
                const SizedBox(height: 6),
                Text(
                  item["description"] ?? "",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================= PROFILE PAGE =================

extension PharmacyProfileExtension on _PharmacyDashboardState {
  Widget profilePage() {
    final pharmacy = pharmacyData ?? {};

    final String name = pharmacy["name"]?.toString().trim().isNotEmpty == true
        ? pharmacy["name"].toString().trim()
        : pharmacyName;

    final String phone = pharmacy["phone"]?.toString() ?? pharmacyPhone;

    final String address = pharmacy["address"]?.toString() ?? "";

    final String shopType = pharmacy["shopType"]?.toString() ?? "";

    final String experience = pharmacy["experience"]?.toString() ?? "";

    final String rating = pharmacy["rating"]?.toString() ?? "4.5";

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(
          bottom: 30,
        ),
        children: [
          // =================================================
          // PROFILE HEADER
          // =================================================

          Column(
            children: [
              const SizedBox(height: 25),
              CircleAvatar(
                radius: 62,
                backgroundColor: const Color(0xff14B8A6),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "P",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name.isEmpty ? "Pharmacy" : name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),

          // =================================================
          // PHONE
          // =================================================

          profileInfoCard(
            icon: Icons.phone,
            title: "Phone",
            value: phone.isEmpty ? "-" : phone,
          ),

          // =================================================
          // ADDRESS
          // =================================================

          profileInfoCard(
            icon: Icons.local_hospital,
            title: "Address",
            value: address.isEmpty ? "-" : address,
          ),

          // =================================================
          // SHOP TYPE
          // =================================================

          profileInfoCard(
            icon: Icons.local_pharmacy,
            title: "Shop Type",
            value: shopType.isEmpty ? "-" : shopType,
          ),

          // =================================================
          // EXPERIENCE
          // =================================================

          profileInfoCard(
            icon: Icons.work,
            title: "Experience",
            value: experience.isEmpty ? "-" : "$experience Years",
          ),

          // =================================================
          // RATING
          // =================================================

          profileInfoCard(
            icon: Icons.star,
            title: "Rating",
            value: rating,
          ),

          const SizedBox(height: 25),

          // =================================================
          // DELIVERY PARTNERS
          // =================================================

          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 34,
              vertical: 8,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Delivery Partners",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Add Delivery Partner",
                      onPressed: addDeliveryPartnerDialog,
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xff14B8A6),
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Select a partner when assigning an order.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                if (deliveryPartners.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F8FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No Delivery Partners",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Tap + to add a delivery partner.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(
                    deliveryPartners.length,
                    (index) {
                      final partner = deliveryPartners[index];

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index == deliveryPartners.length - 1 ? 0 : 10,
                        ),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xffF5F8FC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xffE6FFFB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xff14B8A6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partner["name"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    partner["phone"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    "Available",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: "Remove",
                              onPressed: isRemovingPartner
                                  ? null
                                  : () => removeDeliveryPartner(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =================================================
          // AVAILABLE FOR ORDERS
          // =================================================

          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 34,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Available for Orders",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Online",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: pharmacy["available"] ?? true,
                  activeThumbColor: const Color(0xff14B8A6),
                  onChanged: (value) {
                    // Availability update
                    // can be connected later.
                    setState(() {
                      pharmacyData?["available"] = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // =================================================
          // LOGOUT
          // =================================================

          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 34,
            ),
            height: 58,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();

                // ==========================================
                // CLEAR LOGIN SESSION ONLY
                // ==========================================

                await prefs.remove("isLoggedIn");
                await prefs.remove("userRole");
                await prefs.remove("userPhone");
                await prefs.remove("userName");
                await prefs.remove("token");

                debugPrint("================================");
                debugPrint("PHARMACY LOGOUT");
                debugPrint("LOGIN SESSION CLEARED");
                debugPrint("================================");

                if (!context.mounted) {
                  return;
                }

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================
  // PROFILE INFORMATION CARD
  // =========================================================

  Widget profileInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 34,
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ICON

          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xff14B8A6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 25),

          // TEXT

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
