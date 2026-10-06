import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController medicineController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController stockController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String selectedCategory = "Tablet";

  bool isSaving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    medicineController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE MEDICINE
  // ============================================================

  Future<void> saveMedicine() async {
    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    final medicineName = medicineController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();
    final description = descriptionController.text.trim();

    if (medicineName.isEmpty) {
      showMessage("Please enter medicine name");
      return;
    }

    if (priceText.isEmpty) {
      showMessage("Please enter price");
      return;
    }

    if (stockText.isEmpty) {
      showMessage("Please enter available stock");
      return;
    }

    final price = int.tryParse(priceText);
    final stock = int.tryParse(stockText);

    if (price == null || price < 0) {
      showMessage("Please enter a valid price");
      return;
    }

    if (stock == null || stock < 0) {
      showMessage("Please enter a valid stock quantity");
      return;
    }

    // ------------------------------------------------------------
    // START LOADING
    // ------------------------------------------------------------

    setState(() {
      isSaving = true;
    });

    try {
      // ----------------------------------------------------------
      // GET PHARMACY PHONE
      // ----------------------------------------------------------

      final prefs = await SharedPreferences.getInstance();

      final pharmacyPhone =
          prefs.getString("pharmacyPhone") ??
          prefs.getString("userPhone") ??
          "";

      if (pharmacyPhone.isEmpty) {
        if (mounted) {
          showMessage(
            "Pharmacy phone number not found. Please login again.",
          );
        }

        return;
      }

      // ----------------------------------------------------------
      // API CALL
      // ----------------------------------------------------------

      final result = await ApiService.addMedicine(
        pharmacyPhone: pharmacyPhone,

        medicineName: medicineName,

        category: selectedCategory,

        description: description,

        price: price.toString(),

        stock: stock.toString(),

        image: "",
      );

      // ----------------------------------------------------------
      // CHECK RESULT
      // ----------------------------------------------------------

      if (!mounted) return;

      if (result is Map &&
          result["success"] == true) {
        // --------------------------------------------------------
        // SUCCESS
        // --------------------------------------------------------

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Medicine Added Successfully",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // --------------------------------------------------------
        // CLEAR FIELDS
        // --------------------------------------------------------

        medicineController.clear();
        priceController.clear();
        stockController.clear();
        descriptionController.clear();

        setState(() {
          selectedCategory = "Tablet";
        });

        // --------------------------------------------------------
        // OPTIONAL: GO BACK
        // --------------------------------------------------------
        //
        // If you want to automatically return to My Medicines
        // after saving, uncomment this:
        //
        // Navigator.pop(context, true);
        //
        // Currently staying on this page allows adding another
        // medicine.
      } else {
        showMessage(
          result is Map
              ? result["message"]?.toString() ??
                  "Failed to add medicine"
              : "Failed to add medicine",
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Something went wrong: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration fieldDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: const Color(0xff14B8A6),
            ),
      border: const UnderlineInputBorder(),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xff14B8A6),
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,

        title: const Text(
          "Add Medicine",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==================================================
              // MEDICINE NAME
              // ==================================================

              sectionTitle("Medicine Name"),

              const SizedBox(height: 8),

              TextField(
                controller: medicineController,
                textInputAction: TextInputAction.next,
                decoration: fieldDecoration(
                  hint: "Enter medicine name",
                  icon: Icons.medication_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // CATEGORY
              // ==================================================

              sectionTitle("Category"),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedCategory,

                decoration: fieldDecoration(
                  hint: "Select category",
                  icon: Icons.category_outlined,
                ),

                items: const [
                  DropdownMenuItem(
                    value: "Tablet",
                    child: Text("Tablet"),
                  ),

                  DropdownMenuItem(
                    value: "Capsule",
                    child: Text("Capsule"),
                  ),

                  DropdownMenuItem(
                    value: "Syrup",
                    child: Text("Syrup"),
                  ),

                  DropdownMenuItem(
                    value: "Injection",
                    child: Text("Injection"),
                  ),

                  DropdownMenuItem(
                    value: "Cream",
                    child: Text("Cream"),
                  ),
                ],

                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedCategory = value;
                        });
                      },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // PRICE
              // ==================================================

              sectionTitle("Price Per Unit"),

              const SizedBox(height: 8),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,

                decoration: fieldDecoration(
                  hint: "Example: 80",
                  icon: Icons.currency_rupee,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // STOCK
              // ==================================================

              sectionTitle("Available Stock"),

              const SizedBox(height: 8),

              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,

                decoration: fieldDecoration(
                  hint: "Enter stock quantity",
                  icon: Icons.inventory_2_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              sectionTitle("Description"),

              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 4,

                decoration: fieldDecoration(
                  hint: "Enter medicine description",
                  icon: Icons.description_outlined,
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : saveMedicine,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff14B8A6),

                    disabledBackgroundColor:
                        Colors.grey.shade400,

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),

                  child: isSaving
                      ? const SizedBox(
                          height: 25,
                          width: 25,

                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Save Medicine",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // INFORMATION
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xffF0FDFA),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xffCCFBF1),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xff14B8A6),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Add accurate medicine details so "
                        "patients can easily identify and "
                        "order the medicine.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}