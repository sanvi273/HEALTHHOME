import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../payment/payment_page.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  // ============================================================
  // THEME
  // ============================================================

  final Color primaryColor = const Color(0xff14B8A6);

  // ============================================================
  // DATA
  // ============================================================

  bool isLoading = true;
  bool isPlacingOrder = false;

  String patientId = "";
  String patientName = "";
  String patientPhone = "";

  List<dynamic> cartItems = [];
  List<dynamic> pharmacies = [];

  String? selectedPharmacy;

  String selectedPaymentMethod = "online".tr();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalAmount {
    double total = 0;

    for (final item in cartItems) {
      final storedSubtotal =
          double.tryParse(
                item["subtotal"]?.toString() ?? "",
              ) ??
              0;

      final price =
          double.tryParse(
                item["price"]?.toString() ?? "0",
              ) ??
              0;

      final quantity =
          int.tryParse(
                item["quantity"]?.toString() ?? "1",
              ) ??
              1;

      // Prefer a valid stored subtotal, otherwise
      // always calculate price × quantity.
      final subtotal =
          storedSubtotal > 0
              ? storedSubtotal
              : price * quantity;

      total += subtotal;
    }

    return total;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> loadCart() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      patientPhone =
          prefs.getString("patientPhone") ??
              prefs.getString("phone") ??
              "";

      patientId =
          prefs.getString("patientId") ??
              patientPhone;

      patientName =
          prefs.getString("patientName") ??
              prefs.getString("name") ??
              "patient".tr();

      debugPrint(
        "================================",
      );

      debugPrint("loadingCart".tr());

      debugPrint(
        "PATIENT ID = $patientId",
      );

      debugPrint(
        "PATIENT PHONE = $patientPhone",
      );

      debugPrint(
        "================================",
      );

      final results = await Future.wait([
        ApiService.getCartItems(patientPhone),
        ApiService.getPharmacies(),
      ]);

      cartItems = results[0];
      pharmacies = results[1];

      debugPrint(
        "CART ITEMS = $cartItems",
      );

      debugPrint(
        "PHARMACIES = $pharmacies",
      );
    } catch (e) {
      debugPrint(
        "❌ LOAD CART ERROR = $e",
      );

      if (mounted) {
        showMessage(
          e.toString(),
          Colors.red,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

        title: Text(
          "myCart".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : cartItems.isEmpty
              ? emptyWidget()
              : RefreshIndicator(
                  onRefresh: loadCart,

                  child: ListView(
                    padding:
                        const EdgeInsets.all(16),

                    children: [
                      // ==================================================
                      // CART ITEMS
                      // ==================================================

                      ...cartItems.map(
                        (item) {
                          return buildCartItem(
                            item,
                          );
                        },
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==================================================
                      // ORDER SUMMARY
                      // ==================================================

                      buildOrderSummary(),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // PHARMACY
                      // ==================================================

                      buildPharmacyDropdown(),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // ADDRESS
                      // ==================================================

                      TextField(
                        controller:
                            addressController,

                        maxLines: 3,

                        decoration:
                            InputDecoration(
                          labelText:
                              "deliveryAddress".tr(),

                          hintText:
                              "enterCompleteDeliveryAddress".tr(),

                          prefixIcon:
                              const Padding(
                            padding:
                                EdgeInsets.only(
                              bottom: 45,
                            ),

                            child: Icon(
                              Icons.location_on,
                            ),
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // NOTES
                      // ==================================================

                      TextField(
                        controller:
                            notesController,

                        maxLines: 3,

                        decoration:
                            InputDecoration(
                          labelText:
                              "notes".tr(),

                          hintText:
                              "anyDeliveryInstructions".tr(),

                          prefixIcon:
                              const Padding(
                            padding:
                                EdgeInsets.only(
                              bottom: 45,
                            ),

                            child: Icon(
                              Icons
                                  .note_alt_outlined,
                            ),
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // PAYMENT METHOD
                      // ==================================================

                      buildPaymentMethod(),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // PLACE ORDER
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,

                        height: 56,

                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryColor,

                            foregroundColor:
                                Colors.white,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                          ),

                          onPressed:
                              isPlacingOrder
                                  ? null
                                  : placeMedicineOrder,

                          icon:
                              isPlacingOrder
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,

                                        color:
                                            Colors
                                                .white,
                                      ),
                                    )
                                  : Icon(
                                      selectedPaymentMethod ==
                                              "online".tr()
                                          ? Icons
                                              .payment
                                          : Icons
                                              .payments,
                                    ),

                          label: Text(
                            isPlacingOrder
                                ? "processing".tr()
                                : selectedPaymentMethod ==
                                        "online".tr()
                                    ? "proceedToPayment".tr()
                                    : "placeCodOrder".tr(),

                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget buildCartItem(
    dynamic item,
  ) {
    final medicineName =
        item["medicine"]?.toString() ??
            item["medicineName"]?.toString() ??
            "medicine".tr();

    final dose =
        item["dose"]?.toString() ?? "";

    final duration =
        item["duration"]?.toString() ?? "";

    final instruction =
        item["instruction"]?.toString() ??
            "";

    final quantity =
        int.tryParse(
              item["quantity"]?.toString() ??
                  "1",
            ) ??
            1;

    final price =
        double.tryParse(
              item["price"]?.toString() ??
                  "0",
            ) ??
            0;

    final storedSubtotal =
        double.tryParse(
              item["subtotal"]?.toString() ?? "",
            ) ??
            0;

    final subtotal =
        storedSubtotal > 0
            ? storedSubtotal
            : price * quantity;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                CircleAvatar(
                  radius: 28,

                  backgroundColor:
                      primaryColor
                          .withOpacity(.12),

                  child: Icon(
                    Icons.medication,

                    color:
                        primaryColor,

                    size: 30,
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        medicineName,

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (dose.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),

                          child: Text(
                            "${"doseLabel".tr()}: $dose",
                          ),
                        ),

                      if (duration.isNotEmpty)
                        Text(
                          "${"durationLabel".tr()}: $duration",
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        "${"priceLabel".tr()}: ₹${price.toStringAsFixed(2)}",

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        "${"subtotal".tr()}: ₹${subtotal.toStringAsFixed(2)}",

                        style:
                            const TextStyle(
                          color:
                              Colors.green,

                          fontWeight:
                              FontWeight.bold,
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
                        Colors.green.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Text(
                    "${"quantityShort".tr()} $quantity",

                    style:
                        const TextStyle(
                      color:
                          Colors.green,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // INSTRUCTION
            // ==================================================

            if (instruction.isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Text(
                  instruction,
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // QUANTITY
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        isPlacingOrder
                            ? null
                            : () async {
                                try {
                                  await ApiService
                                      .decreaseCartQuantity(
                                    item["_id"],
                                  );

                                  await loadCart();
                                } catch (e) {
                                  showMessage(
                                    e.toString(),
                                    Colors.red,
                                  );
                                }
                              },

                    icon:
                        const Icon(
                      Icons.remove,
                    ),

                    label:
                        Text(
                      "decrease".tr(),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryColor,

                      foregroundColor:
                          Colors.white,
                    ),

                    onPressed:
                        isPlacingOrder
                            ? null
                            : () async {
                                try {
                                  await ApiService
                                      .increaseCartQuantity(
                                    item["_id"],
                                  );

                                  await loadCart();
                                } catch (e) {
                                  showMessage(
                                    e.toString(),
                                    Colors.red,
                                  );
                                }
                              },

                    icon:
                        const Icon(
                      Icons.add,
                    ),

                    label:
                        Text(
                      "increase".tr(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // DELETE
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              child:
                  TextButton.icon(
                onPressed:
                    isPlacingOrder
                        ? null
                        : () async {
                            try {
                              await ApiService
                                  .deleteCartItem(
                                item["_id"],
                              );

                              await loadCart();
                            } catch (e) {
                              showMessage(
                                e.toString(),
                                Colors.red,
                              );
                            }
                          },

                icon:
                    const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),

                label:
                    Text(
                  "removeMedicine".tr(),

                  style:
                      TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget buildOrderSummary() {
    return Card(
      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              "orderSummary".tr(),

              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            summaryRow(
              "totalMedicines".tr(),
              "${cartItems.fold<int>(0, (sum, item) {
                final quantity =
                    int.tryParse(
                          item["quantity"]?.toString() ?? "1",
                        ) ??
                        1;
                return sum + quantity;
              })}",
            ),

            const Divider(),

            summaryRow(
              "subtotal".tr(),
              "₹${totalAmount.toStringAsFixed(2)}",
            ),

            const Divider(),

            summaryRow(
              "deliveryCharges".tr(),
              "free".tr(),
            ),

            const Divider(),

            summaryRow(
              "grandTotal".tr(),
              "₹${totalAmount.toStringAsFixed(2)}",
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHARMACY DROPDOWN
  // ============================================================

  Widget buildPharmacyDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          selectedPharmacy,

      isExpanded: true,

      decoration:
          InputDecoration(
        labelText:
            "choosePharmacy".tr(),

        prefixIcon:
            const Icon(
          Icons.local_pharmacy,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
        ),
      ),

      items: pharmacies.map(
        (pharmacy) {
          final name =
              pharmacy["name"]
                      ?.toString() ??
                  "pharmacy".tr();

          return DropdownMenuItem<String>(
            value: name,

            child: Text(
              name,

              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),

      onChanged:
          isPlacingOrder
              ? null
              : (value) {
                  setState(() {
                    selectedPharmacy =
                        value;
                  });
                },
    );
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  Widget buildPaymentMethod() {
    return Card(
      elevation: 1,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
             Padding(
              padding:
                  EdgeInsets.all(8),

              child: Text(
                "paymentMethod".tr(),

                style:
                    TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            RadioListTile<String>(
              value: "online".tr(),

              groupValue:
                  selectedPaymentMethod,

              title:
                  Text(
                "onlinePayment".tr(),
              ),

              subtitle:
                  Text(
                "upiCardNetBanking".tr(),
              ),

              secondary:
                  const Icon(
                Icons.payment,
              ),

              onChanged:
                  isPlacingOrder
                      ? null
                      : (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            selectedPaymentMethod =
                                value;
                          });
                        },
            ),

            RadioListTile<String>(
              value: "cod".tr(),

              groupValue:
                  selectedPaymentMethod,

              title:
                  Text(
                "cashOnDelivery".tr(),
              ),

              subtitle:
                  Text(
                "payWhenDelivered".tr(),
              ),

              secondary:
                  const Icon(
                Icons
                    .local_atm,
              ),

              onChanged:
                  isPlacingOrder
                      ? null
                      : (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            selectedPaymentMethod =
                                value;
                          });
                        },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLACE MEDICINE ORDER
  // ============================================================

  Future<void>
      placeMedicineOrder() async {
    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (cartItems.isEmpty) {
      showMessage(
        "yourCartIsEmpty".tr(),
        Colors.red,
      );

      return;
    }

    if (selectedPharmacy ==
            null ||
        selectedPharmacy!
            .trim()
            .isEmpty) {
      showMessage(
        "pleaseSelectPharmacy".tr(),
        Colors.orange,
      );

      return;
    }

    if (addressController.text
        .trim()
        .isEmpty) {
      showMessage(
        "pleaseEnterDeliveryAddress".tr(),
        Colors.orange,
      );

      return;
    }

    if (patientPhone
        .trim()
        .isEmpty) {
      showMessage(
        "patientPhoneNotFound".tr(),
        Colors.red,
      );

      return;
    }

    if (isPlacingOrder) {
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // ========================================================
      // FIND PHARMACY
      // ========================================================

      dynamic pharmacy;

      for (final p in pharmacies) {
        if (p["name"]?.toString() ==
            selectedPharmacy) {
          pharmacy = p;
          break;
        }
      }

      if (pharmacy == null) {
        throw Exception(
          "pharmacyInformationNotFound".tr(),
        );
      }

      final pharmacyId =
          pharmacy["_id"]?.toString() ??
              "";

      final pharmacyName =
          pharmacy["name"]?.toString() ??
              "";

      if (pharmacyId.isEmpty) {
        throw Exception(
          "pharmacyIdNotFound".tr(),
        );
      }

      // ========================================================
      // PREPARE MEDICINES
      // ========================================================

      final medicines =
          cartItems.map<
              Map<String, dynamic>>(
        (item) {
          final medicineId =
              item["medicineId"]
                      ?.toString() ??
                  "";

          if (medicineId.isEmpty) {
            throw Exception(
              "Medicine ID is missing for ${item["medicine"] ?? "medicine"}.",
            );
          }

          final quantity =
              int.tryParse(
                    item["quantity"]
                            ?.toString() ??
                        "1",
                  ) ??
                  1;

          final price =
              double.tryParse(
                    item["price"]?.toString() ?? "0",
                  ) ??
                  0;

          if (price <= 0) {
            throw Exception(
              "Invalid price for ${item["medicine"] ?? item["medicineName"] ?? "medicine"}.",
            );
          }

          final itemSubtotal = price * quantity;

          if (itemSubtotal <= 0) {
            throw Exception(
              "Unable to calculate subtotal for ${item["medicine"] ?? item["medicineName"] ?? "medicine"}.",
            );
          }

          return {
            "medicineId": medicineId,

            "medicineName":
                item["medicine"]?.toString() ??
                item["medicineName"]?.toString() ??
                "medicine".tr(),

            "quantity": quantity,

            // This is the current cart price.
            // Backend will still verify the real price
            // from MongoDB before saving the order.
            "price": price,

            // IMPORTANT:
            // Never send a hardcoded zero subtotal.
            "subtotal": itemSubtotal,
          };
        },
      ).toList();

      // ========================================================
      // CREATE HEALTHHOME ORDER FIRST
      //
      // IMPORTANT:
      // Backend calculates the actual amount.
      // Flutter does NOT send a trusted total.
      // ========================================================

      debugPrint(
        "================================",
      );

      debugPrint(
        "creatingHealthHomeMedicineOrder".tr(),
      );

      debugPrint(
        "PHARMACY ID = $pharmacyId",
      );

      debugPrint(
        "PAYMENT METHOD = $selectedPaymentMethod",
      );

      debugPrint(
        "================================",
      );

      final orderResponse =
          await ApiService
              .placeMedicineOrder(
        patientId:
            patientId,

        patientName:
            patientName,

        patientPhone:
            patientPhone,

        pharmacyId:
            pharmacyId,

        pharmacyName:
            pharmacyName,

        address:
            addressController.text
                .trim(),

        notes:
            notesController.text
                .trim(),

        prescriptionImage:
            "",

        medicines:
            medicines,

        // Send the calculated cart total.
        // Backend remains authoritative and recalculates
        // the final total from MongoDB medicine prices.
        totalAmount:
            medicines.fold<double>(
          0,
          (sum, medicine) =>
              sum +
              ((medicine["subtotal"] as num?)?.toDouble() ?? 0),
        ),

        paymentMethod:
            selectedPaymentMethod,

        // Backend determines the real payment state.
        paymentStatus:
            "Pending",
      );

      debugPrint(
        "ORDER RESPONSE = $orderResponse",
      );

      if (orderResponse["success"] !=
          true) {
        throw Exception(
          orderResponse["message"] ??
              "medicineOrderCouldNotBeCreated".tr(),
        );
      }

      final createdOrder =
          orderResponse["order"];

      if (createdOrder == null) {
        throw Exception(
          "orderCreatedNoInformation".tr(),
        );
      }

      final orderId =
          createdOrder["id"]?.toString() ??
              createdOrder["_id"]?.toString() ??
              "";

      if (orderId.isEmpty) {
        throw Exception(
          "healthHomeOrderIdMissing".tr(),
        );
      }

      final backendTotal =
          double.tryParse(
                createdOrder[
                        "totalAmount"]
                    ?.toString() ??
                    "0",
              ) ??
              0;

      debugPrint(
        "HEALTHHOME ORDER ID = $orderId",
      );

      debugPrint(
        "BACKEND TOTAL = $backendTotal",
      );

      // ========================================================
      // IMPORTANT: THE CART IS NOW CONVERTED INTO A HEALTHHOME
      // ORDER. REMOVE THE ACTIVE CART ITEMS IMMEDIATELY.
      //
      // This prevents old medicines from appearing again when
      // the patient reopens My Cart or starts another order.
      // The HealthHome Order remains saved in MongoDB even if
      // online payment is cancelled/failed.
      // ========================================================

      await clearCart();

      debugPrint(
        "cartClearedAfterOrder".tr(),
      );

      // ========================================================
      // COD
      // ========================================================

      if (selectedPaymentMethod ==
          "cod".tr()) {

        if (!mounted) {
          return;
        }

        setState(() {
          isPlacingOrder = false;
        });

        await showOrderSuccessDialog(
          title:
              "codOrderPlaced".tr(),

          message:
              "medicineOrderPlacedSuccess".tr() + "\n\n"
              "paymentCollectedOnDelivery".tr(),
        );

        if (!mounted) return;

        Navigator.of(
          context,
        ).pop(true);

        return;
      }

      // ========================================================
      // ONLINE PAYMENT
      //
      // serviceId MUST be HealthHome Order ID
      // ========================================================

      debugPrint(
        "================================",
      );

      debugPrint(
        "openingOnlinePayment".tr(),
      );

      debugPrint(
        "HEALTHHOME ORDER ID = $orderId",
      );

      debugPrint(
        "AMOUNT = $backendTotal",
      );

      debugPrint(
        "================================",
      );

      if (backendTotal <= 0) {
        throw Exception(
          "invalidOrderAmount".tr(),
        );
      }

      final paymentSuccess =
          await Navigator.of(context)
              .push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              PaymentPage(
            amount:
                backendTotal,

            userId:
                patientId,

            userName:
                patientName,

            userPhone:
                patientPhone,

            serviceType:
                "medicine".tr(),

            // IMPORTANT:
            // This is the HealthHome
            // Order ID, NOT pharmacyId.
            serviceId:
                orderId,
          ),
        ),
      );

      debugPrint(
        "PAYMENT RESULT = $paymentSuccess",
      );

      // ========================================================
      // PAYMENT CANCELLED / FAILED
      // ========================================================

      if (paymentSuccess !=
          true) {
        if (!mounted) {
          return;
        }

        setState(() {
          isPlacingOrder = false;
        });

        showMessage(
          "paymentNotCompletedPending".tr(),
          Colors.orange,
        );

        return;
      }

      // ========================================================
      // ONLINE PAYMENT SUCCESS
      // ========================================================

      // Cart was already cleared immediately after the
      // HealthHome order was created. Do not clear it again.

      if (!mounted) {
        return;
      }

      setState(() {
        isPlacingOrder = false;
      });

      await showOrderSuccessDialog(
        title:
            "paymentSuccessful".tr(),

        message:
            "medicineOrderPaymentVerified".tr() + "\n\n"
            "pharmacyWillProcess".tr(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(true);
    } catch (e) {
      debugPrint(
        "================================",
      );

      debugPrint(
        "medicineOrderError".tr(),
      );

      debugPrint(
        "$e",
      );

      debugPrint(
        "================================",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isPlacingOrder = false;
      });

      showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  Future<void> clearCart() async {
    final items =
        List<dynamic>.from(
      cartItems,
    );

    for (final item in items) {
      try {
        await ApiService
            .deleteCartItem(
          item["_id"],
        );
      } catch (e) {
        debugPrint(
          "${"unableToRemoveItem".tr()}: $e",
        );
      }
    }

    cartItems = [];
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void>
      showOrderSuccessDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,

      barrierDismissible:
          false,

      builder:
          (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color:
                    Colors.green,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  title,
                ),
              ),
            ],
          ),

          content: Text(
            message,
          ),

          actions: [
            ElevatedButton(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    primaryColor,

                foregroundColor:
                    Colors.white,
              ),

              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },

              child:
                  Text(
                "done".tr(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY CART
  // ============================================================

  Widget emptyWidget() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .shopping_cart_outlined,

              size: 100,

              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              "yourCartIsEmpty".tr(),

              style:
                  TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              "medicinesAddedFromPrescription".tr() + "\n"
              "willAppearHere".tr(),

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,

                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget summaryRow(
    String title,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          Text(
            title,

            style:
                TextStyle(
              fontSize: 16,

              fontWeight:
                  highlight
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),

          Text(
            value,

            style:
                TextStyle(
              fontSize:
                  highlight ? 18 : 16,

              fontWeight:
                  FontWeight.bold,

              color: highlight
                  ? primaryColor
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        backgroundColor:
            color,

        content:
            Text(message),
      ),
    );
  }
}