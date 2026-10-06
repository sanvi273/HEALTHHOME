import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'pharmacy_dashboard.dart';

class PharmacyProfileSetup extends StatefulWidget {
  const PharmacyProfileSetup({super.key});

  @override
  State<PharmacyProfileSetup> createState() =>
      _PharmacyProfileSetupState();
}

class _PharmacyProfileSetupState
    extends State<PharmacyProfileSetup> {

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController shopTypeController =
      TextEditingController();

  final TextEditingController experienceController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPharmacyName();
  }

  // =====================================================
  // LOAD PHARMACY NAME
  // =====================================================

  Future<void> loadPharmacyName() async {

    final prefs =
        await SharedPreferences.getInstance();

    nameController.text =
        prefs.getString("pharmacyName") ??
        prefs.getString("userName") ??
        "";
  }

  // =====================================================
  // SAVE PHARMACY PROFILE
  // =====================================================

  Future<void> savePharmacyProfile() async {

    if (isLoading) return;

    final shopType =
        shopTypeController.text.trim();

    final experience =
        experienceController.text.trim();

    final address =
        addressController.text.trim();

    // ---------------------------------------------------
    // VALIDATION
    // ---------------------------------------------------

    if (shopType.isEmpty ||
        experience.isEmpty ||
        address.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all pharmacy details",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final prefs =
          await SharedPreferences.getInstance();

      // -------------------------------------------------
      // GET PHONE
      // -------------------------------------------------

      final phone =
          prefs.getString("pharmacyPhone") ??
          prefs.getString("userPhone") ??
          "";

      // -------------------------------------------------
      // GET NAME
      // -------------------------------------------------

      final name =
          nameController.text.trim().isNotEmpty
              ? nameController.text.trim()
              : prefs.getString("pharmacyName") ??
                  prefs.getString("userName") ??
                  "";

      // -------------------------------------------------
      // CHECK PHONE
      // -------------------------------------------------

      if (phone.isEmpty) {

        throw Exception(
          "Pharmacy phone number is missing. Please login again.",
        );
      }

      // -------------------------------------------------
      // DEBUG
      // -------------------------------------------------

      debugPrint("================================");
      debugPrint("SAVING PHARMACY PROFILE");
      debugPrint("NAME       = $name");
      debugPrint("PHONE      = $phone");
      debugPrint("SHOP TYPE  = $shopType");
      debugPrint("EXPERIENCE = $experience");
      debugPrint("ADDRESS    = $address");
      debugPrint("================================");

      // -------------------------------------------------
      // SEND TO BACKEND
      // -------------------------------------------------

      final result =
          await ApiService.addPharmacy(
        name: name,
        shopType: shopType,
        experience: experience,
        address: address,
        phone: phone,
      );

      // -------------------------------------------------
      // API RESPONSE
      // -------------------------------------------------

      debugPrint("================================");
      debugPrint("PHARMACY API RESPONSE");
      debugPrint("$result");
      debugPrint(
        "SUCCESS = ${result["success"]}",
      );
      debugPrint(
        "PHARMACY = ${result["pharmacy"]}",
      );
      debugPrint("================================");

      // -------------------------------------------------
      // CHECK SUCCESS
      // -------------------------------------------------

      if (result["success"] != true) {

        throw Exception(
          result["message"]?.toString() ??
              "Failed to save pharmacy profile",
        );
      }

      // -------------------------------------------------
      // SAVE LOCAL DATA
      // -------------------------------------------------

      await prefs.setString(
        "pharmacyName",
        name,
      );

      await prefs.setString(
        "pharmacyPhone",
        phone,
      );

      await prefs.setString(
        "pharmacyShopType",
        shopType,
      );

      await prefs.setString(
        "pharmacyExperience",
        experience,
      );

      await prefs.setString(
        "pharmacyAddress",
        address,
      );

      await prefs.setBool(
        "pharmacyProfileCompleted_$phone",
        true,
      );

      debugPrint(
        "✅ PHARMACY PROFILE SAVED SUCCESSFULLY",
      );

      // -------------------------------------------------
      // GO TO DASHBOARD
      // -------------------------------------------------

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const PharmacyDashboard(),
        ),
      );

    } catch (e) {

      debugPrint(
        "❌ SAVE PHARMACY PROFILE ERROR = $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          duration:
              const Duration(seconds: 4),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration inputDecoration(
    String hint,
  ) {

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),

        borderSide:
            BorderSide.none,
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }

  // =====================================================
  // BUILD UI
  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF4F7FB),

      appBar: AppBar(

        backgroundColor:
            const Color(0xff14B8A6),

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Pharmacy Profile Setup",

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height: 20),

            // ------------------------------------------------
            // ICON
            // ------------------------------------------------

            const CircleAvatar(

              radius: 55,

              backgroundColor:
                  Color(0xffD1FAF5),

              child: Icon(
                Icons.medical_services,
                size: 60,
                color: Color(0xff14B8A6),
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------
            // NAME
            // ------------------------------------------------

            TextField(

              controller:
                  nameController,

              readOnly: true,

              decoration:
                  inputDecoration(
                "Pharmacy Name",
              ),
            ),

            const SizedBox(height: 15),

            // ------------------------------------------------
            // SHOP TYPE
            // ------------------------------------------------

            TextField(

              controller:
                  shopTypeController,

              decoration:
                  inputDecoration(
                "Shop Type",
              ),
            ),

            const SizedBox(height: 15),

            // ------------------------------------------------
            // EXPERIENCE
            // ------------------------------------------------

            TextField(

              controller:
                  experienceController,

              keyboardType:
                  TextInputType.number,

              decoration:
                  inputDecoration(
                "Experience",
              ),
            ),

            const SizedBox(height: 15),

            // ------------------------------------------------
            // ADDRESS
            // ------------------------------------------------

            TextField(

              controller:
                  addressController,

              maxLines: 2,

              decoration:
                  inputDecoration(
                "Address",
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------------------
            // SAVE BUTTON
            // ------------------------------------------------

            SizedBox(

              width:
                  double.infinity,

              height: 55,

              child:
                  ElevatedButton(

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      const Color(
                    0xff14B8A6,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                onPressed:
                    isLoading
                        ? null
                        : savePharmacyProfile,

                child:

                    isLoading

                        ? const SizedBox(
                            height: 25,
                            width: 25,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 3,
                            ),
                          )

                        : const Text(
                            "Save Profile",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {

    nameController.dispose();
    shopTypeController.dispose();
    experienceController.dispose();
    addressController.dispose();

    super.dispose();
  }
}