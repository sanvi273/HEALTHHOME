import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../payment/payment_page.dart';

class OrderMedicinesPage extends StatefulWidget {
  const OrderMedicinesPage({super.key});

  @override
  State<OrderMedicinesPage> createState() =>
      _OrderMedicinesPageState();
}

class _OrderMedicinesPageState
    extends State<OrderMedicinesPage> {
  static const Color primaryColor =
      Color(0xff00C2CB);

  List<dynamic> allMedicines = [];
  List<dynamic> filteredMedicines = [];
  List<dynamic> pharmacies = [];

  bool isLoading = true;

  String selectedCategory = "All";

  final TextEditingController searchController =
      TextEditingController();

  String patientName = "";
  String patientPhone = "";

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      patientName =
          prefs.getString("patientName") ??
              prefs.getString("userName") ??
              "patient".tr();

      patientPhone =
          prefs.getString("patientPhone") ??
              prefs.getString("userPhone") ??
              "";

      await Future.wait([
        loadMedicines(),
        loadPharmacies(),
      ]);
    } catch (e) {
      debugPrint(
        "INITIALIZE MEDICINE PAGE ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD MEDICINES
  // ============================================================

  Future<void> loadMedicines() async {
    try {
      final medicines =
          await ApiService.getMedicines();

      if (!mounted) return;

      setState(() {
        allMedicines = medicines;
        filteredMedicines = medicines;
      });
    } catch (e) {
      debugPrint(
        "LOAD MEDICINES ERROR = $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("${"unableToLoadMedicines".tr()}: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD PHARMACIES
  // ============================================================

  Future<void> loadPharmacies() async {
    try {
      final data =
          await ApiService.getPharmacies();

      if (!mounted) return;

      setState(() {
        pharmacies = data;
      });
    } catch (e) {
      debugPrint(
        "LOAD PHARMACIES ERROR = $e",
      );
    }
  }

  // ============================================================
  // FIND PHARMACY
  // ============================================================

  Map<String, dynamic>? findPharmacy(
    String phone,
  ) {
    final normalizedPhone =
        phone.trim();

    for (final pharmacy in pharmacies) {
      final pharmacyPhone =
          pharmacy["phone"]
                  ?.toString()
                  .trim() ??
              "";

      if (pharmacyPhone ==
          normalizedPhone) {
        return Map<String, dynamic>.from(
          pharmacy,
        );
      }
    }

    return null;
  }

  String getPharmacyName(
    Map<String, dynamic> medicine,
  ) {
    final phone =
        medicine["pharmacyPhone"]
                ?.toString() ??
            "";

    final pharmacy =
        findPharmacy(phone);

    return pharmacy?["name"]
            ?.toString() ??
        "pharmacy".tr();
  }

  String getPharmacyId(
    Map<String, dynamic> medicine,
  ) {
    final phone =
        medicine["pharmacyPhone"]
                ?.toString() ??
            "";

    final pharmacy =
        findPharmacy(phone);

    return pharmacy?["_id"]
            ?.toString() ??
        "";
  }

  // ============================================================
  // SEARCH / FILTER
  // ============================================================

  void filterMedicines() {
    final search =
        searchController.text
            .trim()
            .toLowerCase();

    setState(() {
      filteredMedicines =
          allMedicines.where((medicine) {
        final name =
            (medicine["medicineName"] ??
                    "")
                .toString()
                .toLowerCase();

        final category =
            (medicine["category"] ??
                    "")
                .toString()
                .toLowerCase();

        final manufacturer =
            (medicine["manufacturer"] ??
                    "")
                .toString()
                .toLowerCase();

        final status =
            (medicine["status"] ??
                    "available".tr())
                .toString()
                .toLowerCase();

        final stock =
            int.tryParse(
                  medicine["stock"]
                          ?.toString() ??
                      "0",
                ) ??
                0;

        final matchesSearch =
            search.isEmpty ||
                name.contains(search) ||
                category.contains(search) ||
                manufacturer.contains(search);

        final matchesCategory =
            selectedCategory == "All" ||
                category ==
                    selectedCategory
                        .toLowerCase();

        final available =
            status == "available" &&
                stock > 0;

        return matchesSearch &&
            matchesCategory &&
            available;
      }).toList();
    });
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> getCategories() {
    final categories =
        <String>{"All"};

    for (final medicine
        in allMedicines) {
      final category =
          medicine["category"]
                  ?.toString()
                  .trim() ??
              "";

      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    return categories.toList();
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  Future<void> openCart() async {
    if (patientPhone.trim().isEmpty) {
      _showMessage(
        "patientInformationNotFound".tr(),
        error: true,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineCartPage(
          patientName: patientName,
          patientPhone: patientPhone,
          medicines: allMedicines,
          pharmacies: pharmacies,
        ),
      ),
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> addToCart(
    Map<String, dynamic> medicine,
  ) async {
    if (patientPhone.trim().isEmpty) {
      _showMessage(
        "patientInformationNotFound".tr(),
        error: true,
      );
      return;
    }

    final medicineId =
        medicine["_id"]?.toString() ?? "";

    if (medicineId.isEmpty) {
      _showMessage(
        "medicineIdMissing".tr(),
        error: true,
      );
      return;
    }

    try {
      final result =
          await ApiService.addMedicineToCart(
        patientId: patientPhone,
        patientName: patientName,
        medicineId: medicineId,
        medicine:
            medicine["medicineName"]
                    ?.toString() ??
                "",
        dose:
            medicine["category"]
                    ?.toString() ??
                "",
        duration: "",
        food: "",
        instruction: "",
        quantity: 1,
      );

      if (!mounted) return;

      final success =
          result["success"] == true ||
              result["item"] != null ||
              result["cart"] != null;

      if (!success) {
        _showMessage(
          result["message"] ??
              "unableToAddMedicineToCart".tr(),
          error: true,
        );
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "${medicine["medicineName"]} ${"addedToCart".tr()}",
          ),
          backgroundColor:
              Colors.green,
          action: SnackBarAction(
            label: "viewCart".tr(),
            textColor: Colors.white,
            onPressed: openCart,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Unable to add to cart: $e",
        error: true,
      );
    }
  }

  // ============================================================
  // MEDICINE DETAILS
  // ============================================================

  void openMedicineDetails(
    Map<String, dynamic> medicine,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicineDetailPage(
          medicine: medicine,
          pharmacyName:
              getPharmacyName(
            medicine,
          ),
          pharmacyId:
              getPharmacyId(
            medicine,
          ),
          patientName:
              patientName,
          patientPhone:
              patientPhone,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(0xff0F172A),

        title: Text(
          "orderMedicines".tr(),
          style: TextStyle(
            color:
                Color(0xff0F172A),
            fontSize: 23,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
            onPressed: openCart,
          ),
        ],
      ),

      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await Future.wait([
            loadMedicines(),
            loadPharmacies(),
          ]);
        },

        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                children: [
                  _buildHeader(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildSearch(),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    "categories".tr(),
                    style:
                        TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xff0F172A,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildCategories(),

                  const SizedBox(
                    height: 24,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        "availableMedicines".tr(),
                        style:
                            TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${filteredMedicines.length} ${"items".tr()}",
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  if (filteredMedicines
                      .isEmpty)
                    _emptyState()
                  else
                    ...filteredMedicines
                        .map(
                      (
                        medicine,
                      ) {
                        return _medicineCard(
                          Map<String, dynamic>.from(
                            medicine,
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xffE8FAFB),
            Colors.white,
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child: Row(
        children: [
           Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  "findYourMedicines".tr(),
                  style:
                      TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                Text(
                  "orderMedicinesFromPharmacy".tr(),
                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 60,
            height: 60,
            decoration:
                BoxDecoration(
              color: primaryColor
                  .withOpacity(
                0.12,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.medication,
              color:
                  primaryColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          searchController,

      onChanged: (_) {
        filterMedicines();
      },

      decoration:
          InputDecoration(
        hintText:
            "searchMedicines".tr(),

        prefixIcon:
            const Icon(
          Icons.search,
          color:
              primaryColor,
        ),

        suffixIcon:
            searchController
                    .text
                    .isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(
                      Icons.clear,
                    ),
                    onPressed: () {
                      searchController
                          .clear();
                      filterMedicines();
                    },
                  )
                : null,

        filled: true,
        fillColor:
            Colors.white,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color:
                primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 42,

      child: ListView(
        scrollDirection:
            Axis.horizontal,

        children:
            getCategories()
                .map(
          (category) {
            final selected =
                selectedCategory ==
                    category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory =
                      category;
                });

                filterMedicines();
              },

              child:
                  Container(
                margin:
                    const EdgeInsets.only(
                  right: 10,
                ),

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? primaryColor
                          : Colors.white,

                  borderRadius:
                      BorderRadius
                          .circular(
                    22,
                  ),

                  border:
                      Border.all(
                    color:
                        selected
                            ? primaryColor
                            : Colors.grey
                                .shade300,
                  ),
                ),

                child: Center(
                  child:
                      Text(
                    category,
                    style:
                        TextStyle(
                      color:
                          selected
                              ? Colors.white
                              : Colors.black87,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // MEDICINE CARD
  // ============================================================

  Widget _medicineCard(
    Map<String, dynamic> medicine,
  ) {
    final name =
        medicine["medicineName"]
                ?.toString() ??
            "medicine".tr();

    final category =
        medicine["category"]
                ?.toString() ??
            "medicine".tr();

    final manufacturer =
        medicine["manufacturer"]
                ?.toString() ??
            "";

    final image =
        medicine["image"]
                ?.toString() ??
            "";

    final price =
        double.tryParse(
              medicine["price"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    final stock =
        int.tryParse(
              medicine["stock"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    final pharmacyName =
        getPharmacyName(
      medicine,
    );

    return GestureDetector(
      onTap: () {
        openMedicineDetails(
          medicine,
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(
                0.04,
              ),
              blurRadius: 10,
              offset:
                  const Offset(
                0,
                4,
              ),
            ),
          ],
        ),

        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xffE8FAFB,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: image.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                          child:
                              Image.network(
                            image,
                            fit: BoxFit
                                .cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.medication,
                                color:
                                    primaryColor,
                                size:
                                    40,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.medication,
                          color:
                              primaryColor,
                          size: 40,
                        ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        category,
                        style:
                            const TextStyle(
                          color:
                              primaryColor,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      if (manufacturer
                          .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          child: Text(
                            manufacturer,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // PHARMACY
            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 9,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xffF2F8F9,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.local_pharmacy,
                    color:
                        primaryColor,
                    size: 18,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      pharmacyName,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  Text(
                    "$stock ${"available".tr()}",
                    style:
                        const TextStyle(
                      color:
                          Colors.green,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed: () {
                      openMedicineDetails(
                        medicine,
                      );
                    },
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          primaryColor,
                      side:
                          const BorderSide(
                        color:
                            primaryColor,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child:
                        Text(
                      "viewDetails".tr(),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      addToCart(
                        medicine,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .shopping_cart_outlined,
                      size: 18,
                    ),
                    label:
                        Text(
                      "add".tr(),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyState() {
    return Container(
      padding:
          const EdgeInsets.all(
        40,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(children: [
          Icon(
            Icons.search_off,
            size: 55,
            color:
                Colors.grey,
          ),
          SizedBox(
            height: 14,
          ),
          Text(
            "noMedicinesFound".tr(),
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            "tryAnotherMedicineOrCategory".tr(),
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// MEDICINE DETAIL PAGE
// =================================================================

class MedicineDetailPage
    extends StatelessWidget {
  final Map<String, dynamic> medicine;

  final String pharmacyName;
  final String pharmacyId;

  final String patientName;
  final String patientPhone;

  const MedicineDetailPage({
    super.key,
    required this.medicine,
    required this.pharmacyName,
    required this.pharmacyId,
    required this.patientName,
    required this.patientPhone,
  });

  static const Color primaryColor =
      Color(0xff00C2CB);

  Future<void> addToCart(
    BuildContext context,
  ) async {
    try {
      final result =
          await ApiService.addMedicineToCart(
        patientId: patientPhone,
        patientName: patientName,
        medicineId:
            medicine["_id"]
                    ?.toString() ??
                "",
        medicine:
            medicine["medicineName"]
                    ?.toString() ??
                "",
        dose:
            medicine["category"]
                    ?.toString() ??
                "",
        duration: "",
        food: "",
        instruction: "",
        quantity: 1,
      );

      if (!context.mounted) return;

      final success =
          result["success"] == true ||
              result["item"] != null ||
              result["cart"] != null;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              "${medicine["medicineName"]} ${"addedToCart".tr()}",
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              result["message"] ??
                  "unableToAddToCart".tr(),
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text("Error: $e"),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final name =
        medicine["medicineName"]
                ?.toString() ??
            "medicine".tr();

    final category =
        medicine["category"]
                ?.toString() ??
            "medicine".tr();

    final manufacturer =
        medicine["manufacturer"]
                ?.toString() ??
            "";

    final description =
        medicine["description"]
                ?.toString() ??
            "";

    final image =
        medicine["image"]
                ?.toString() ??
            "";

    final price =
        double.tryParse(
              medicine["price"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    final stock =
        int.tryParse(
              medicine["stock"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(
          0xff0F172A,
        ),
        title:
            Text(
          "medicineDetails".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Container(
              width:
                  double.infinity,
              height: 280,

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),

              child:
                  image.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          child:
                              Image.network(
                            image,
                            fit: BoxFit
                                .contain,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.medication,
                                size:
                                    100,
                                color:
                                    primaryColor,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.medication,
                          size:
                              100,
                          color:
                              primaryColor,
                        ),
            ),

            const SizedBox(
              height: 22,
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration:
                  BoxDecoration(
                color:
                    primaryColor
                        .withOpacity(
                  0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child:
                  Text(
                category,
                style:
                    const TextStyle(
                  color:
                      primaryColor,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              name,
              style:
                  const TextStyle(
                fontSize: 27,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Icon(
                  Icons.local_pharmacy,
                  size: 18,
                  color:
                      primaryColor,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  pharmacyName,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Colors.black87,
                  ),
                ),
              ],
            ),

            if (manufacturer
                .isNotEmpty) ...[
              const SizedBox(
                height: 7,
              ),
              Text(
                "${"manufacturer".tr()}: $manufacturer",
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
                Text(
                  "₹${price.toStringAsFixed(0)}",
                  style:
                      const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        primaryColor,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green
                            .withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                      Text(
                    "$stock ${"available".tr()}",
                    style:
                        const TextStyle(
                      color:
                          Colors.green,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 25,
            ),

            Text(
              "description".tr(),
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  Text(
                description.isNotEmpty
                    ? description
                    : "noDescriptionAvailable".tr(),
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 55,

              child:
                  ElevatedButton.icon(
                onPressed:
                    stock > 0
                        ? () {
                            addToCart(
                              context,
                            );
                          }
                        : null,

                icon:
                    const Icon(
                  Icons
                      .shopping_cart,
                ),

                label:
                    Text(
                  "addToCart".tr(),
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

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
                      16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// CART PAGE
// =================================================================

class MedicineCartPage
    extends StatefulWidget {
  final String patientName;
  final String patientPhone;

  final List<dynamic> medicines;
  final List<dynamic> pharmacies;

  const MedicineCartPage({
    super.key,
    required this.patientName,
    required this.patientPhone,
    required this.medicines,
    required this.pharmacies,
  });

  @override
  State<MedicineCartPage> createState() =>
      _MedicineCartPageState();
}

class _MedicineCartPageState
    extends State<MedicineCartPage> {
  static const Color primaryColor =
      Color(0xff00C2CB);

  List<dynamic> cartItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  // ============================================================
  // LOAD CART
  // ============================================================

  Future<void> loadCart() async {
    try {
      final items =
          await ApiService.getCartItems(
        widget.patientPhone,
      );

      if (!mounted) return;

      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD CART ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        "Unable to load cart: $e",
        error: true,
      );
    }
  }

  // ============================================================
  // FIND MEDICINE
  // ============================================================

  Map<String, dynamic>? findMedicine(
    String medicineId,
  ) {
    for (final medicine
        in widget.medicines) {
      if (medicine["_id"]
              ?.toString() ==
          medicineId) {
        return Map<String, dynamic>.from(
          medicine,
        );
      }
    }

    return null;
  }

  // ============================================================
  // PHARMACY
  // ============================================================

  Map<String, dynamic>? findPharmacyByPhone(
    String phone,
  ) {
    for (final pharmacy
        in widget.pharmacies) {
      if (pharmacy["phone"]
              ?.toString()
              .trim() ==
          phone.trim()) {
        return Map<String, dynamic>.from(
          pharmacy,
        );
      }
    }

    return null;
  }

  // ============================================================
  // CART PRICE
  // ============================================================

  double getItemPrice(
    Map<String, dynamic> item,
  ) {
    final medicineId =
        item["medicineId"]
                ?.toString() ??
            "";

    final medicine =
        findMedicine(
      medicineId,
    );

    return double.tryParse(
          medicine?["price"]
                  ?.toString() ??
              "0",
        ) ??
        0;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get subtotal {
    double total = 0;

    for (final rawItem
        in cartItems) {
      final item =
          Map<String, dynamic>.from(
        rawItem,
      );

      final quantity =
          int.tryParse(
                item["quantity"]
                        ?.toString() ??
                    "1",
              ) ??
              1;

      total +=
          getItemPrice(item) *
              quantity;
    }

    return total;
  }

  double get deliveryFee => 0;

  double get total =>
      subtotal + deliveryFee;

  // ============================================================
  // INCREASE
  // ============================================================

  Future<void> increase(
    String id,
  ) async {
    try {
      await ApiService
          .increaseCartQuantity(
        id,
      );

      await loadCart();
    } catch (e) {
      _showMessage(
        "unableToIncreaseQuantity".tr(),
        error: true,
      );
    }
  }

  // ============================================================
  // DECREASE
  // ============================================================

  Future<void> decrease(
    String id,
  ) async {
    try {
      await ApiService
          .decreaseCartQuantity(
        id,
      );

      await loadCart();
    } catch (e) {
      _showMessage(
        "unableToDecreaseQuantity".tr(),
        error: true,
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> remove(
    String id,
  ) async {
    try {
      await ApiService
          .deleteCartItem(
        id,
      );

      await loadCart();
    } catch (e) {
      _showMessage(
        "unableToRemoveItem".tr(),
        error: true,
      );
    }
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  void checkout() {
    if (cartItems.isEmpty) {
      _showMessage(
        "yourCartIsEmpty".tr(),
        error: true,
      );
      return;
    }

    final pharmacyKeys =
        <String>{};

    for (final rawItem
        in cartItems) {
      final item =
          Map<String, dynamic>.from(
        rawItem,
      );

      final medicine =
          findMedicine(
        item["medicineId"]
                ?.toString() ??
            "",
      );

      if (medicine != null) {
        pharmacyKeys.add(
          medicine["pharmacyPhone"]
                  ?.toString() ??
              "",
        );
      }
    }

    if (pharmacyKeys.length >
        1) {
      _showMessage(
        "cartDifferentPharmacies".tr(),
        error: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicineCheckoutPage(
          patientName:
              widget.patientName,
          patientPhone:
              widget.patientPhone,
          cartItems:
              cartItems,
          medicines:
              widget.medicines,
          pharmacies:
              widget.pharmacies,
          subtotal:
              subtotal,
          deliveryFee:
              deliveryFee,
          total:
              total,
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(
          0xff0F172A,
        ),
        title:
            Text(
          "myCart".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    primaryColor,
              ),
            )
          : cartItems.isEmpty
              ? _emptyCart()
              : Column(
                  children: [
                    Expanded(
                      child:
                          RefreshIndicator(
                        onRefresh:
                            loadCart,
                        child:
                            ListView(
                          padding:
                              const EdgeInsets
                                  .all(
                            16,
                          ),
                          children:
                              cartItems
                                  .map(
                            (
                              rawItem,
                            ) {
                              return _cartItemCard(
                                Map<String, dynamic>.from(
                                  rawItem,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),

                    _bottomSummary(),
                  ],
                ),
    );
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget _cartItemCard(
    Map<String, dynamic> item,
  ) {
    final medicine =
        findMedicine(
      item["medicineId"]
              ?.toString() ??
          "",
    );

    final name =
        medicine?["medicineName"]
                ?.toString() ??
            item["medicine"]
                ?.toString() ??
            "medicine".tr();

    final image =
        medicine?["image"]
                ?.toString() ??
            "";

    final quantity =
        int.tryParse(
              item["quantity"]
                      ?.toString() ??
                  "1",
            ) ??
            1;

    final price =
        getItemPrice(item);

        String pharmacyName = "pharmacy".tr();

    if (medicine != null) {
      final pharmacy = findPharmacyByPhone(
        medicine["pharmacyPhone"]?.toString() ?? "",
      );

      pharmacyName =
          pharmacy?["name"]?.toString() ?? "pharmacy".tr();
    }

    final itemId =
        item["_id"]?.toString() ??
            "";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffE8FAFB,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    image.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            child:
                                Image.network(
                              image,
                              fit: BoxFit
                                  .cover,
                            ),
                          )
                        : const Icon(
                            Icons.medication,
                            color:
                                primaryColor,
                            size:
                                35,
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
                    Text(
                      name,
                      maxLines:
                          2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize:
                            16,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .local_pharmacy,
                          size:
                              14,
                          color:
                              primaryColor,
                        ),
                        const SizedBox(
                          width:
                              4,
                        ),
                        Expanded(
                          child:
                              Text(
                            pharmacyName,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize:
                                  12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      "₹${price.toStringAsFixed(0)}",
                      style:
                          const TextStyle(
                        color:
                            primaryColor,
                        fontWeight:
                            FontWeight.bold,
                        fontSize:
                            17,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed:
                    itemId.isEmpty
                        ? null
                        : () {
                            remove(
                              itemId,
                            );
                          },
                icon:
                    const Icon(
                  Icons.delete_outline,
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                "quantity".tr(),
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              Container(
                decoration:
                    BoxDecoration(
                  border:
                      Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          quantity > 1 &&
                                  itemId.isNotEmpty
                              ? () {
                                  decrease(
                                    itemId,
                                  );
                                }
                              : null,
                      icon:
                          const Icon(
                        Icons.remove,
                        size: 18,
                      ),
                    ),

                    Text(
                      "$quantity",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed:
                          itemId.isNotEmpty
                              ? () {
                                  increase(
                                    itemId,
                                  );
                                }
                              : null,
                      icon:
                          const Icon(
                        Icons.add,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Align(
            alignment:
                Alignment.centerRight,
            child: Text(
              "${"itemTotal".tr()}: ₹${(price * quantity).toStringAsFixed(0)}",
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _bottomSummary() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        18,
      ),

      decoration:
          const BoxDecoration(
        color:
            Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color:
                Color(0x12000000),
          ),
        ],
      ),

      child: Column(
        children: [
          _summaryRow(
            "subtotal".tr(),
            subtotal,
          ),

          _summaryRow(
            "delivery".tr(),
            deliveryFee,
          ),

          const Divider(),

          _summaryRow(
            "total".tr(),
            total,
            bold: true,
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width:
                double.infinity,
            height: 52,
            child:
                ElevatedButton(
              onPressed:
                  checkout,
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
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              child:
                  Text(
                "${"proceedToCheckout".tr()} • ₹${total.toStringAsFixed(0)}",
                style:
                    const TextStyle(
                  fontSize:
                      16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            title,
            style:
                TextStyle(
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
              fontSize:
                  bold
                      ? 17
                      : 14,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style:
                TextStyle(
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
              fontSize:
                  bold
                      ? 18
                      : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Icon(
              Icons
                  .shopping_cart_outlined,
              size:
                  80,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              "yourCartIsEmpty".tr(),
              style:
                  TextStyle(
                fontSize:
                    21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              "addMedicinesContinueCheckout".tr(),
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// CHECKOUT PAGE
// =================================================================

class MedicineCheckoutPage
    extends StatefulWidget {
  final String patientName;
  final String patientPhone;

  final List<dynamic> cartItems;
  final List<dynamic> medicines;
  final List<dynamic> pharmacies;

  final double subtotal;
  final double deliveryFee;
  final double total;

  const MedicineCheckoutPage({
    super.key,
    required this.patientName,
    required this.patientPhone,
    required this.cartItems,
    required this.medicines,
    required this.pharmacies,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  State<MedicineCheckoutPage>
      createState() =>
          _MedicineCheckoutPageState();
}

class _MedicineCheckoutPageState
    extends State<MedicineCheckoutPage> {
  static const Color primaryColor =
      Color(0xff00C2CB);

  final TextEditingController
      addressController =
      TextEditingController();

  final TextEditingController
      notesController =
      TextEditingController();

  String paymentMethod = "COD";

  bool isSubmitting = false;

  // ============================================================
  // FIND MEDICINE
  // ============================================================

  Map<String, dynamic>? findMedicine(
    String id,
  ) {
    for (final medicine
        in widget.medicines) {
      if (medicine["_id"]
              ?.toString() ==
          id) {
        return Map<String, dynamic>.from(
          medicine,
        );
      }
    }

    return null;
  }

  // ============================================================
  // PHARMACY
  // ============================================================

  Map<String, dynamic>? findPharmacy(
    String phone,
  ) {
    for (final pharmacy
        in widget.pharmacies) {
      if (pharmacy["phone"]
              ?.toString()
              .trim() ==
          phone.trim()) {
        return Map<String, dynamic>.from(
          pharmacy,
        );
      }
    }

    return null;
  }

  Map<String, dynamic>?
      get selectedPharmacy {
    if (widget.cartItems.isEmpty) {
      return null;
    }

    final first =
        Map<String, dynamic>.from(
      widget.cartItems.first,
    );

    final medicine =
        findMedicine(
      first["medicineId"]
              ?.toString() ??
          "",
    );

    if (medicine == null) {
      return null;
    }

    return findPharmacy(
      medicine["pharmacyPhone"]
              ?.toString() ??
          "",
    );
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> placeOrder() async {
    if (isSubmitting) return;

    final address =
        addressController.text.trim();

    if (address.isEmpty) {
      _showMessage(
        "pleaseEnterDeliveryAddress".tr(),
        error: true,
      );
      return;
    }

    final pharmacy =
        selectedPharmacy;

    if (pharmacy == null) {
      _showMessage(
        "pharmacyInformationNotFound".tr(),
        error: true,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final orderMedicines =
          <Map<String, dynamic>>[];

      for (final rawItem
          in widget.cartItems) {
        final item =
            Map<String, dynamic>.from(
          rawItem,
        );

        final medicine =
            findMedicine(
          item["medicineId"]
                  ?.toString() ??
              "",
        );

        if (medicine == null) {
          throw Exception(
            "medicineInformationNotFound".tr(),
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
                  medicine["price"]
                          ?.toString() ??
                      "0",
                ) ??
                0;

        orderMedicines.add({
          "medicineId":
              medicine["_id"]
                  ?.toString() ??
                  "",
          "medicineName":
              medicine["medicineName"]
                      ?.toString() ??
                  "",
          "quantity":
              quantity,
          "price":
              price,
          "subtotal":
              price * quantity,
        });
      }

      // ========================================================
      // CREATE ORDER
      // ========================================================

      final result =
          await ApiService
              .placeMedicineOrder(
        patientId:
            widget.patientPhone,

        patientName:
            widget.patientName,

        patientPhone:
            widget.patientPhone,

        pharmacyId:
            pharmacy["_id"]
                    ?.toString() ??
                "",

        pharmacyName:
            pharmacy["name"]
                    ?.toString() ??
                "pharmacy".tr(),

        address:
            address,

        notes:
            notesController.text
                .trim(),

        prescriptionImage:
            "",

        medicines:
            orderMedicines,

        totalAmount:
            widget.total,

        paymentMethod:
            paymentMethod,

        paymentStatus: "Pending",
      );

      final success =
          result["success"] == true ||
              result["order"] != null;

      if (!success) {
        throw Exception(
          result["message"] ??
              "unableToCreateMedicineOrder".tr(),
        );
      }

      final order =
          Map<String, dynamic>.from(
        result["order"] ?? {},
      );

      final orderId =
          order["id"]?.toString() ??
              order["_id"]
                  ?.toString() ??
              "";

      // ========================================================
      // COD
      // ========================================================

      if (paymentMethod == "COD") {
        await ApiService.clearCart(
          widget.patientPhone,
        );

        if (!mounted) return;

        setState(() {
          isSubmitting = false;
        });

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicineOrderSuccessPage(
              orderId:
                  orderId,
              total:
                  widget.total,
              paymentMethod:
                  "COD",
              pharmacyName:
                  pharmacy["name"]
                          ?.toString() ??
                      "pharmacy".tr(),
            ),
          ),
        );

        return;
      }

      // ========================================================
      // ONLINE PAYMENT
      // ========================================================

      if (orderId.isEmpty) {
        throw Exception(
          "orderIdNotReturned".tr(),
        );
      }

      final paymentSuccess =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PaymentPage(
            amount: widget.total,
            userId: widget.patientPhone,
            userName: widget.patientName,
            userPhone: widget.patientPhone,
            serviceType: "Medicine",
            serviceId: orderId,
          ),
        ),
      );

      if (paymentSuccess !=
          true) {
        if (!mounted) return;

        setState(() {
          isSubmitting = false;
        });

        _showMessage(
          "paymentCancelledPending".tr(),
          error: true,
        );

        return;
      }

      // ========================================================
      // PAYMENT SUCCESS
      // ========================================================

      await ApiService.clearCart(
        widget.patientPhone,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MedicineOrderSuccessPage(
            orderId:
                orderId,
            total:
                widget.total,
            paymentMethod:
                "ONLINE",
            pharmacyName:
                pharmacy["name"]
                        ?.toString() ??
                    "pharmacy".tr(),
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "MEDICINE CHECKOUT ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showMessage(
        "Order failed: $e",
        error: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final pharmacy =
        selectedPharmacy;

    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(
          0xff0F172A,
        ),
        title:
            Text(
          "checkout".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            // ==================================================
            // PHARMACY
            // ==================================================

            _sectionTitle(
              "pharmacy".tr(),
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color:
                          primaryColor
                              .withOpacity(
                        0.10,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons
                          .local_pharmacy,
                      color:
                          primaryColor,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        Text(
                      pharmacy?["name"]
                              ?.toString() ??
                          "pharmacy".tr(),
                      style:
                          const TextStyle(
                        fontSize:
                            17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // ADDRESS
            // ==================================================

            _sectionTitle(
              "deliveryAddress".tr(),
            ),

            TextField(
              controller:
                  addressController,
              maxLines: 3,
              decoration:
                  InputDecoration(
                hintText:
                    "enterCompleteDeliveryAddress".tr(),

                prefixIcon:
                    const Icon(
                  Icons.location_on_outlined,
                  color:
                      primaryColor,
                ),

                filled:
                    true,
                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      BorderSide.none,
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  notesController,
              maxLines: 2,
              decoration:
                  InputDecoration(
                hintText:
                    "deliveryInstructionsOptional".tr(),

                filled:
                    true,
                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // ORDER ITEMS
            // ==================================================

            _sectionTitle(
              "orderItems".tr(),
            ),

            ...widget.cartItems
                .map(
              (
                rawItem,
              ) {
                return _checkoutItem(
                  Map<String, dynamic>.from(
                    rawItem,
                  ),
                );
              },
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // PAYMENT
            // ==================================================

            _sectionTitle(
              "paymentMethod".tr(),
            ),

            _paymentOption(
  value: "COD",
              title:
                  "cashOnDelivery".tr(),
              subtitle:
                  "payWhenDelivered".tr(),
              icon:
                  Icons
                      .payments_outlined,
            ),

            const SizedBox(
              height: 10,
            ),

            _paymentOption(
  value: "ONLINE",
              title:
                  "onlinePayment".tr(),
              subtitle:
                  "paySecurelyRazorpay".tr(),
              icon:
                  Icons
                      .account_balance_wallet_outlined,
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // PRICE SUMMARY
            // ==================================================

            _sectionTitle(
              "priceDetails".tr(),
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child:
                  Column(
                children: [
                  _priceRow(
                    "subtotal".tr(),
                    widget
                        .subtotal,
                  ),
                  _priceRow(
                    "delivery".tr(),
                    widget
                        .deliveryFee,
                  ),
                  const Divider(),
                  _priceRow(
                    "total".tr(),
                    widget.total,
                    bold:
                        true,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 55,

              child:
                  ElevatedButton(
                onPressed:
                    isSubmitting
                        ? null
                        : placeOrder,

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
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                child:
                    isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : Text(
                            paymentMethod ==
                                    "COD"
                                ? "${"placeOrder".tr()} • ₹${widget.total.toStringAsFixed(0)}"
                                : "${"payAndPlaceOrder".tr()} ₹${widget.total.toStringAsFixed(0)}",
                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              19,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _checkoutItem(
    Map<String, dynamic> item,
  ) {
    final medicine =
        findMedicine(
      item["medicineId"]
              ?.toString() ??
          "",
    );

    final name =
        medicine?["medicineName"]
                ?.toString() ??
            "medicine".tr();

    final quantity =
        int.tryParse(
              item["quantity"]
                      ?.toString() ??
                  "1",
            ) ??
            1;

    final price =
        double.tryParse(
              medicine?["price"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              "$name × $quantity",
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Text(
            "₹${(price * quantity).toStringAsFixed(0)}",
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected =
        paymentMethod ==
            value;

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod =
              value;
        });
      },

      child:
          Container(
        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                selected
                    ? primaryColor
                    : Colors.grey
                        .shade300,
            width:
                selected
                    ? 1.5
                    : 1,
          ),
        ),

        child:
            Row(
          children: [
            Icon(
              icon,
              color:
                  primaryColor,
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
                  Text(
                    title,
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
                    subtitle,
                    style:
                        const TextStyle(
                      color:
                          Colors.grey,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ),

            Radio<String>(
              value:
                  value,
              groupValue:
                  paymentMethod,
              activeColor:
                  primaryColor,
              onChanged:
                  (value) {
                if (value ==
                    null) {
                  return;
                }

                setState(() {
                  paymentMethod =
                      value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            title,
            style:
                TextStyle(
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style:
                TextStyle(
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
              fontSize:
                  bold
                      ? 18
                      : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineOrderSuccessPage
    extends StatelessWidget {
  final String orderId;
  final double total;
  final String paymentMethod;
  final String pharmacyName;

  const MedicineOrderSuccessPage({
    super.key,
    required this.orderId,
    required this.total,
    required this.paymentMethod,
    required this.pharmacyName,
  });

  static const Color primaryColor =
      Color(0xff00C2CB);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false,
      ),

      body:
          Center(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              Container(
                width:
                    90,
                height:
                    90,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green
                          .withOpacity(
                    0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.check_circle,
                  color:
                      Colors.green,
                  size:
                      70,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Text(
                "orderPlacedSuccessfully".tr(),
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize:
                      25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                "${"orderFromPharmacyPlaced".tr(namedArgs: {"pharmacy": pharmacyName})}",
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                    Column(
                  children: [
                    _infoRow(
                      "orderId".tr(),
                      orderId,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _infoRow(
                      "amount".tr(),
                      "₹${total.toStringAsFixed(0)}",
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _infoRow(
                      "payment".tr(),
                      paymentMethod ==
                              "cod".tr()
                          ? "cashOnDelivery".tr()
                          : "onlinePaid".tr(),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                width:
                    double.infinity,
                height:
                    52,
                child:
                    ElevatedButton(
                  onPressed:
                      () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MedicineOrderTrackingPage(
                          orderId:
                              orderId,
                          pharmacyName:
                              pharmacyName,
                        ),
                      ),
                    );
                  },
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
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                  child:
                      Text(
                    "trackOrder".tr(),
                    style:
                        TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextButton(
                onPressed:
                    () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.isFirst,
                  );
                },
                child:
                    Text(
                  "continueShopping".tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            color:
                Colors.grey,
          ),
        ),
        Flexible(
          child:
              Text(
            value,
            textAlign:
                TextAlign.end,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================
// ORDER TRACKING
// =================================================================

class MedicineOrderTrackingPage
    extends StatefulWidget {
  final String orderId;
  final String pharmacyName;

  const MedicineOrderTrackingPage({
    super.key,
    required this.orderId,
    required this.pharmacyName,
  });

  @override
  State<MedicineOrderTrackingPage>
      createState() =>
          _MedicineOrderTrackingPageState();
}

class _MedicineOrderTrackingPageState
    extends State<MedicineOrderTrackingPage> {
  static const Color primaryColor =
      Color(0xff00C2CB);

  List<dynamic> orders = [];

  bool isLoading = true;

  Map<String, dynamic>?
      currentOrder;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final phone =
          prefs.getString(
                "patientPhone",
              ) ??
              prefs.getString(
                "userPhone",
              ) ??
              "";

      if (phone.isEmpty) {
        throw Exception(
          "patientPhoneNotFound".tr(),
        );
      }

      final data =
          await ApiService
              .getPatientMedicineOrders(
        phone,
      );

      if (!mounted) return;

      orders = data;

      for (final rawOrder
          in data) {
        final order =
            Map<String, dynamic>.from(
          rawOrder,
        );

        final id =
            order["_id"]
                    ?.toString() ??
                order["id"]
                    ?.toString() ??
                "";

        if (id ==
            widget.orderId) {
          currentOrder =
              order;
          break;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD ORDER TRACKING ERROR = $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text("${"unableToLoadOrder".tr()}: $e"),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final status =
        currentOrder?["status"]
                ?.toString() ??
            "Pending";

    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        foregroundColor:
            const Color(
          0xff0F172A,
        ),
        title:
            Text(
          "trackOrder".tr(),
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
                loadOrders,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        primaryColor,
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadOrders,

                  child:
                      ListView(
                    padding:
                        const EdgeInsets
                            .all(
                      16,
                    ),

                    children: [
                      _orderHeader(
                        status,
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      _trackingTimeline(
                        status,
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      if (currentOrder !=
                          null)
                        _orderDetails(),
                    ],
                  ),
                ),
    );
  }

  Widget _orderHeader(
    String status,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            "orderStatus".tr(),
            style:
                TextStyle(
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            status,
            style:
                const TextStyle(
              fontSize:
                  25,
              fontWeight:
                  FontWeight.bold,
              color:
                  primaryColor,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            widget.pharmacyName,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            "${"orderId".tr()}: ${widget.orderId}",
            style:
                const TextStyle(
              color:
                  Colors.grey,
              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingTimeline(
    String status,
  ) {
    final steps = [
      "Pending",
      "accepted".tr(),
      "packed".tr(),
      "outForDelivery".tr(),
      "delivered".tr(),
    ];

    final currentIndex =
        steps.indexOf(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Column(
        children:
            List.generate(
          steps.length,
          (index) {
            final completed =
                currentIndex >=
                    index;

            final active =
                currentIndex ==
                    index;

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Column(
                  children: [
                    Container(
                      width:
                          28,
                      height:
                          28,

                      decoration:
                          BoxDecoration(
                        color:
                            completed
                                ? primaryColor
                                : Colors
                                    .grey
                                    .shade300,
                        shape:
                            BoxShape
                                .circle,
                      ),

                      child:
                          Icon(
                        completed
                            ? Icons
                                .check
                            : Icons
                                .circle,
                        size:
                            17,
                        color:
                            Colors.white,
                      ),
                    ),

                    if (index !=
                        steps.length -
                            1)
                      Container(
                        width:
                            2,
                        height:
                            45,
                        color:
                            completed
                                ? primaryColor
                                : Colors
                                    .grey
                                    .shade300,
                      ),
                  ],
                ),

                const SizedBox(
                  width:
                      14,
                ),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    top:
                        3,
                  ),

                  child:
                      Text(
                    steps[index],
                    style:
                        TextStyle(
                      fontWeight:
                          active
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          completed
                              ? Colors
                                  .black87
                              : Colors
                                  .grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _orderDetails() {
    final order =
        currentOrder!;

    final amount =
        double.tryParse(
              order["totalAmount"]
                      ?.toString() ??
                  "0",
            ) ??
            0;

    final payment =
        order["paymentMethod"]
                ?.toString() ??
            "cod".tr();

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            "orderDetails".tr(),
            style:
                TextStyle(
              fontSize:
                  19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          _detailRow(
            "amount".tr(),
            "₹${amount.toStringAsFixed(0)}",
          ),

          _detailRow(
            "payment".tr(),
            payment ==
                    "cod".tr()
                ? "cashOnDelivery".tr()
                : "online".tr(),
          ),

          _detailRow(
            "address".tr(),
            order["address"]
                    ?.toString() ??
                "",
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          SizedBox(
            width:
                90,
            child:
                Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}