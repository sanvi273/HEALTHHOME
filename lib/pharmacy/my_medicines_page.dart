import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_medicine_page.dart';

class MyMedicinesPage extends StatefulWidget {
  const MyMedicinesPage({super.key});

  @override
  State<MyMedicinesPage> createState() =>
      _MyMedicinesPageState();
}

class _MyMedicinesPageState
    extends State<MyMedicinesPage> {

  List medicines = [];
  List filteredMedicines = [];

  bool loading = true;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD PHARMACY MEDICINES
  // =========================================================

  Future<void> loadMedicines() async {
    try {
      setState(() {
        loading = true;
      });

      final prefs =
          await SharedPreferences.getInstance();

      final String phone =
          prefs.getString("pharmacyPhone") ??
          prefs.getString("userPhone") ??
          "";

      if (phone.isEmpty) {
        if (!mounted) return;

        setState(() {
          medicines = [];
          filteredMedicines = [];
          loading = false;
        });

        return;
      }

      final allMedicines =
          await ApiService.getMedicines();

      final pharmacyMedicines =
          allMedicines.where((medicine) {
        return medicine["pharmacyPhone"]
                ?.toString() ==
            phone;
      }).toList();

      if (!mounted) return;

      setState(() {
        medicines = pharmacyMedicines;
        filteredMedicines =
            List.from(pharmacyMedicines);
        loading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD MEDICINES ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load medicines: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void searchMedicine(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredMedicines =
            List.from(medicines);
        return;
      }

      filteredMedicines =
          medicines.where((medicine) {
        final name =
            medicine["medicineName"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        final category =
            medicine["category"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        final manufacturer =
            medicine["manufacturer"]
                    ?.toString()
                    .toLowerCase() ??
                "";

        return name.contains(query) ||
            category.contains(query) ||
            manufacturer.contains(query);
      }).toList();
    });
  }

  // =========================================================
  // DELETE MEDICINE
  // =========================================================

  Future<void> deleteMedicine(String id) async {
    try {
      final shouldDelete =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              "Delete Medicine",
            ),
            content: const Text(
              "Are you sure you want to delete this medicine?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  "Cancel",
                ),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) {
        return;
      }

      final response =
          await ApiService.deleteMedicine(id);

      if (!mounted) return;

      if (response["success"] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Medicine Deleted Successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );

        await loadMedicines();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              response["message"]
                      ?.toString() ??
                  "Failed to delete medicine",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Delete failed: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // EDIT MEDICINE
  // =========================================================

  Future<void> editMedicine(
      Map medicine) async {

    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditMedicinePage(
          medicine: medicine,
        ),
      ),
    );

    if (result == true) {
      await loadMedicines();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF4F7FB),

      appBar: AppBar(
        backgroundColor:
            const Color(0xff14B8A6),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Medicines",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xff14B8A6),
              ),
            )
          : Column(
              children: [

                // =================================================
                // SEARCH
                // =================================================

                Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: TextField(
                    controller:
                        searchController,
                    onChanged:
                        searchMedicine,

                    decoration:
                        InputDecoration(
                      hintText:
                          "Search medicines",

                      prefixIcon:
                          const Icon(
                        Icons.search,
                        color:
                            Color(0xff14B8A6),
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

                                    searchMedicine(
                                      "",
                                    );
                                  },
                                )
                              : null,

                      filled: true,
                      fillColor:
                          Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // MEDICINES
                // =================================================

                Expanded(
                  child:
                      filteredMedicines.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .medication_outlined,
                                    size: 70,
                                    color:
                                        Colors.grey,
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    "No Medicines Found",
                                    style:
                                        TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color:
                                  const Color(
                                0xff14B8A6,
                              ),
                              onRefresh:
                                  loadMedicines,

                              child:
                                  ListView.builder(
                                padding:
                                    const EdgeInsets
                                        .fromLTRB(
                                  16,
                                  0,
                                  16,
                                  25,
                                ),

                                itemCount:
                                    filteredMedicines
                                        .length,

                                itemBuilder:
                                    (context,
                                        index) {

                                  final medicine =
                                      filteredMedicines[
                                          index];

                                  final int stock =
                                      int.tryParse(
                                            medicine[
                                                    "stock"]
                                                ?.toString() ??
                                                "0",
                                          ) ??
                                          0;

                                  final String
                                      medicineName =
                                      medicine[
                                                  "medicineName"]
                                              ?.toString() ??
                                          "Medicine";

                                  final String
                                      category =
                                      medicine[
                                                  "category"]
                                              ?.toString() ??
                                          "Tablet";

                                  final String
                                      manufacturer =
                                      medicine[
                                                  "manufacturer"]
                                              ?.toString() ??
                                          "-";

                                  final String
                                      description =
                                      medicine[
                                                  "description"]
                                              ?.toString() ??
                                          "";

                                  final String price =
                                      medicine[
                                                  "price"]
                                              ?.toString() ??
                                          "0";

                                  return Container(
                                    margin:
                                        const EdgeInsets
                                            .only(
                                      bottom: 15,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.white,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .black
                                              .withOpacity(
                                            0.05,
                                          ),
                                          blurRadius:
                                              10,
                                          offset:
                                              const Offset(
                                            0,
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),

                                    child:
                                        Padding(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        18,
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [

                                          // =================
                                          // HEADER
                                          // =================

                                          Row(
                                            children: [

                                              Container(
                                                height: 58,
                                                width: 58,
                                                decoration:
                                                    BoxDecoration(
                                                  color: const Color(
                                                          0xff14B8A6)
                                                      .withOpacity(
                                                    0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    15,
                                                  ),
                                                ),
                                                child:
                                                    const Icon(
                                                  Icons
                                                      .medication,
                                                  color:
                                                      Color(
                                                    0xff14B8A6,
                                                  ),
                                                  size:
                                                      30,
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 14,
                                              ),

                                              Expanded(
                                                child:
                                                    Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [

                                                    Text(
                                                      medicineName,
                                                      maxLines:
                                                          2,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            19,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      height:
                                                          5,
                                                    ),

                                                    Text(
                                                      category,
                                                      style:
                                                          const TextStyle(
                                                        color:
                                                            Colors.grey,
                                                        fontSize:
                                                            14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // =================
                                              // STOCK STATUS
                                              // =================

                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal:
                                                      10,
                                                  vertical:
                                                      6,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: stock <
                                                          10
                                                      ? Colors
                                                          .red
                                                      : Colors
                                                          .green,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    20,
                                                  ),
                                                ),
                                                child:
                                                    Text(
                                                  stock <
                                                          10
                                                      ? "Low"
                                                      : "In Stock",
                                                  style:
                                                      const TextStyle(
                                                    color:
                                                        Colors.white,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                    fontSize:
                                                        12,
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

                                          // =================
                                          // DETAILS
                                          // =================

                                          medicineDetail(
                                            icon:
                                                Icons.category_outlined,
                                            title:
                                                "Category",
                                            value:
                                                category,
                                          ),

                                          const SizedBox(
                                            height: 9,
                                          ),

                                          medicineDetail(
                                            icon:
                                                Icons.factory_outlined,
                                            title:
                                                "Manufacturer",
                                            value:
                                                manufacturer,
                                          ),

                                          const SizedBox(
                                            height: 9,
                                          ),

                                          medicineDetail(
                                            icon:
                                                Icons.currency_rupee,
                                            title:
                                                "Price",
                                            value:
                                                "₹$price",
                                            valueColor:
                                                const Color(
                                              0xff14B8A6,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 9,
                                          ),

                                          medicineDetail(
                                            icon:
                                                Icons.inventory_2_outlined,
                                            title:
                                                "Stock",
                                            value:
                                                "$stock",
                                          ),

                                          // IMPORTANT:
                                          // Expiry Date has been
                                          // completely removed.
                                          // No expiry field here.

                                          if (description
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(
                                              height: 14,
                                            ),

                                            Text(
                                              description,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize:
                                                    14,
                                              ),
                                            ),
                                          ],

                                          const SizedBox(
                                            height: 18,
                                          ),

                                          // =================
                                          // ACTION BUTTONS
                                          // =================

                                          Row(
                                            children: [

                                              Expanded(
                                                child:
                                                    ElevatedButton
                                                        .icon(
                                                  onPressed:
                                                      () =>
                                                          editMedicine(
                                                    medicine,
                                                  ),

                                                  style:
                                                      ElevatedButton
                                                          .styleFrom(
                                                    backgroundColor:
                                                        const Color(
                                                      0xff14B8A6,
                                                    ),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      vertical:
                                                          13,
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
                                                    Icons.edit,
                                                    size:
                                                        18,
                                                  ),

                                                  label:
                                                      const Text(
                                                    "Edit",
                                                    style:
                                                        TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 10,
                                              ),

                                              Expanded(
                                                child:
                                                    ElevatedButton
                                                        .icon(
                                                  onPressed:
                                                      () =>
                                                          deleteMedicine(
                                                    medicine[
                                                        "_id"],
                                                  ),

                                                  style:
                                                      ElevatedButton
                                                          .styleFrom(
                                                    backgroundColor:
                                                        Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      vertical:
                                                          13,
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
                                                    Icons.delete,
                                                    size:
                                                        18,
                                                  ),

                                                  label:
                                                      const Text(
                                                    "Delete",
                                                    style:
                                                        TextStyle(
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
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
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  // =========================================================
  // MEDICINE DETAIL ROW
  // =========================================================

  Widget medicineDetail({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Icon(
          icon,
          size: 20,
          color: const Color(0xff14B8A6),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 105,
          child: Text(
            "$title:",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
              color:
                  valueColor ??
                  Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}