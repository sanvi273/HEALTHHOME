import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/medicine_image_selection.dart';
import '../widgets/medicine_image.dart';

class EditMedicinePage extends StatefulWidget {
  final Map medicine;

  const EditMedicinePage({
    super.key,
    required this.medicine,
  });

  @override
  State<EditMedicinePage> createState() =>
      _EditMedicinePageState();
}

class _EditMedicinePageState
    extends State<EditMedicinePage> {

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController descriptionController;
  late TextEditingController manufacturerController;

  // ============================================================
  // VARIABLES
  // ============================================================

  String imageUrl = "";
  Uint8List? selectedImageBytes;
  String? selectedImageFileName;
  String selectedCategory = "Tablet";

  bool isUpdating = false;

  static const Color primaryColor = Color(0xff00C2CB);

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // MEDICINE NAME
    // ----------------------------------------------------------

    nameController = TextEditingController(
      text: widget.medicine["medicineName"]?.toString() ?? "",
    );

    // ----------------------------------------------------------
    // PRICE
    // ----------------------------------------------------------

    priceController = TextEditingController(
      text: widget.medicine["price"]?.toString() ?? "",
    );

    // ----------------------------------------------------------
    // STOCK
    // ----------------------------------------------------------

    stockController = TextEditingController(
      text: widget.medicine["stock"]?.toString() ?? "",
    );

    // ----------------------------------------------------------
    // DESCRIPTION
    // ----------------------------------------------------------

    descriptionController = TextEditingController(
      text: widget.medicine["description"]?.toString() ?? "",
    );

    // ----------------------------------------------------------
    // MANUFACTURER
    // ----------------------------------------------------------

    manufacturerController = TextEditingController(
      text: widget.medicine["manufacturer"]?.toString() ?? "",
    );

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    final category =
        widget.medicine["category"]?.toString();

    const categories = [
      "Tablet",
      "Capsule",
      "Syrup",
      "Injection",
      "Cream",
    ];

    selectedCategory =
        categories.contains(category)
            ? category!
            : "Tablet";

    // ----------------------------------------------------------
    // IMAGE
    // ----------------------------------------------------------

    imageUrl =
        widget.medicine["image"]?.toString() ?? "";
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    manufacturerController.dispose();

    super.dispose();
  }

  // ============================================================
  // UPDATE MEDICINE
  // ============================================================

  Future<void> chooseMedicineImage() async {
    if (isUpdating) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Select from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final selected = await selectMedicineImage(source);
      if (selected == null || !mounted) return;
      setState(() {
        selectedImageBytes = selected.bytes;
        selectedImageFileName = selected.fileName;
      });
    } on MedicineImageException catch (error) {
      showMessage(error.message);
    } catch (_) {
      showMessage("Could not select the medicine photo. Please try again.");
    }
  }

  Widget medicineImageSection() {
    final hasImage = selectedImageBytes != null || imageUrl.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle("Medicine Image"),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffF7FCFC),
            border: Border.all(color: const Color(0xffD8EEEE)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: selectedImageBytes != null
                    ? Image.memory(
                        selectedImageBytes!,
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.contain,
                      )
                    : hasImage
                        ? MedicineImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : Container(
                            width: double.infinity,
                            height: 150,
                            color: const Color(0xffEAF9FA),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.medication_outlined,
                              size: 54,
                              color: primaryColor,
                            ),
                          ),
              ),
              const SizedBox(height: 8),
              if (selectedImageFileName != null)
                Text(
                  selectedImageFileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                )
              else if (!hasImage)
                const Text(
                  "Add a clear photo of the medicine pack. Photo is optional.",
                  style: TextStyle(color: Colors.black54, height: 1.35),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : chooseMedicineImage,
                    icon: Icon(hasImage ? Icons.edit_outlined : Icons.add_a_photo_outlined),
                    label: Text(hasImage ? "Change Image" : "Add Medicine Photo"),
                    style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                  ),
                  if (hasImage)
                    TextButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => setState(() {
                                imageUrl = "";
                                selectedImageBytes = null;
                                selectedImageFileName = null;
                              }),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Remove Image"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
              if (isUpdating && selectedImageBytes != null) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(color: primaryColor),
                const SizedBox(height: 6),
                const Text("Uploading photo and updating medicine…"),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> updateMedicine() async {

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    final medicineName =
        nameController.text.trim();

    final priceText =
        priceController.text.trim();

    final stockText =
        stockController.text.trim();

    final manufacturer =
        manufacturerController.text.trim();

    final description =
        descriptionController.text.trim();

    if (medicineName.isEmpty) {
      showMessage(
        "Please enter medicine name",
      );
      return;
    }

    if (priceText.isEmpty) {
      showMessage(
        "Please enter price",
      );
      return;
    }

    if (stockText.isEmpty) {
      showMessage(
        "Please enter stock",
      );
      return;
    }

    final price =
        int.tryParse(priceText);

    final stock =
        int.tryParse(stockText);

    if (price == null || price < 0) {
      showMessage(
        "Please enter a valid price",
      );
      return;
    }

    if (stock == null || stock < 0) {
      showMessage(
        "Please enter a valid stock quantity",
      );
      return;
    }

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      isUpdating = true;
    });

    try {

      // --------------------------------------------------------
      // MEDICINE ID
      // --------------------------------------------------------

      final medicineId =
          widget.medicine["_id"]?.toString() ?? "";

      if (medicineId.isEmpty) {
        showMessage(
          "Medicine ID not found",
        );
        return;
      }

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response =
          await ApiService.updateMedicine(

        id: medicineId,

        medicineName:
            medicineName,

        category:
            selectedCategory,

        manufacturer:
            manufacturer,

        description:
            description,

        price:
            price.toString(),

        stock:
            stock.toString(),

        image:
            imageUrl,

        imageBytes:
            selectedImageBytes,

        imageFileName:
            selectedImageFileName,
      );

      // --------------------------------------------------------
      // CHECK RESPONSE
      // --------------------------------------------------------

      if (!mounted) return;

      if (response["success"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Medicine Updated Successfully",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ------------------------------------------------------
        // RETURN TO MY MEDICINES
        // ------------------------------------------------------

        Navigator.pop(
          context,
          true,
        );

      } else {

        showMessage(
          response["message"]?.toString() ??
              "Failed to update medicine",
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
          isUpdating = false;
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
  // FIELD DECORATION
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

      border:
          const UnderlineInputBorder(),

      focusedBorder:
          const UnderlineInputBorder(
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
          "Edit Medicine",
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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // MEDICINE NAME
              // ==================================================

              sectionTitle(
                "Medicine Name",
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    nameController,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    fieldDecoration(
                  hint:
                      "Enter medicine name",
                  icon:
                      Icons.medication_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // CATEGORY
              // ==================================================

              sectionTitle(
                "Category",
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(

                // NEW API
                initialValue:
                    selectedCategory,

                decoration:
                    fieldDecoration(
                  hint:
                      "Select category",
                  icon:
                      Icons.category_outlined,
                ),

                items: const [

                  DropdownMenuItem(
                    value: "Tablet",
                    child:
                        Text("Tablet"),
                  ),

                  DropdownMenuItem(
                    value: "Capsule",
                    child:
                        Text("Capsule"),
                  ),

                  DropdownMenuItem(
                    value: "Syrup",
                    child:
                        Text("Syrup"),
                  ),

                  DropdownMenuItem(
                    value: "Injection",
                    child:
                        Text("Injection"),
                  ),

                  DropdownMenuItem(
                    value: "Cream",
                    child:
                        Text("Cream"),
                  ),
                ],

                onChanged:
                    isUpdating
                        ? null
                        : (value) {

                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedCategory =
                                  value;
                            });
                          },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // MANUFACTURER
              // ==================================================

              sectionTitle(
                "Manufacturer",
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    manufacturerController,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    fieldDecoration(
                  hint:
                      "Enter manufacturer",
                  icon:
                      Icons.business_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // PRICE
              // ==================================================

              sectionTitle(
                "Price Per Unit",
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    priceController,

                keyboardType:
                    TextInputType.number,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    fieldDecoration(
                  hint:
                      "Example: 80",
                  icon:
                      Icons.currency_rupee,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // STOCK
              // ==================================================

              sectionTitle(
                "Available Stock",
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    stockController,

                keyboardType:
                    TextInputType.number,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    fieldDecoration(
                  hint:
                      "Enter stock quantity",
                  icon:
                      Icons.inventory_2_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              sectionTitle(
                "Description",
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    descriptionController,

                maxLines: 4,

                decoration:
                    fieldDecoration(
                  hint:
                      "Enter medicine description",
                  icon:
                      Icons.description_outlined,
                ),
              ),

              const SizedBox(height: 35),

              medicineImageSection(),

              const SizedBox(height: 35),

              // ==================================================
              // UPDATE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(

                  onPressed:
                      isUpdating
                          ? null
                          : updateMedicine,

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                      primaryColor,

                    disabledBackgroundColor:
                        Colors.grey.shade400,

                    elevation: 3,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child: isUpdating

                      ? const SizedBox(
                          height: 25,
                          width: 25,

                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth:
                                3,
                          ),
                        )

                      : Text(
                          selectedImageBytes == null
                              ? "Update Medicine"
                              : "Upload Photo & Update Medicine",

                          style: const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                18,
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

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffF0FDFA,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xffCCFBF1,
                    ),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Icon(
                      Icons.info_outline,
                      color:
                          Color(0xff14B8A6),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Update the medicine details "
                        "carefully. Changes will be "
                        "reflected in your pharmacy "
                        "inventory.",

                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black54,
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
