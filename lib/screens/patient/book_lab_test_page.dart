import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../payment/payment_page.dart';

class BookLabTestPage extends StatefulWidget {
  final List<String> selectedTests;

  BookLabTestPage({
    super.key,
    required this.selectedTests,
  });

  @override
  State<BookLabTestPage> createState() => _BookLabTestPageState();
}

class _BookLabTestPageState extends State<BookLabTestPage> {
  // =========================================================
  // THEME
  // =========================================================

  final Color primaryColor = Color(0xff14B8A6);

  // =========================================================
  // STATE
  // =========================================================

  bool isLoading = true;
  bool isBooking = false;
  bool isLoadingAddress = false;
  bool isLoadingTests = false;
  bool isLoadingAvailableTests = false;

  // Internal workflow inside this SAME file.
  // 0 = Test List
  // 1 = Test Details
  // 2 = Booking Options
  int workflowStep = 0;

  List<String> _selectedTests = [];
  List<dynamic> labs = [];
  List<Map<String, dynamic>> labTests = [];
  List<Map<String, dynamic>> savedAddresses = [];
  List<Map<String, dynamic>> allAvailableTests = [];

  Map<String, dynamic>? selectedTestDetails;
  String testSearchQuery = "";
  String selectedCategory = "All";

  final TextEditingController testSearchController =
      TextEditingController();

  String? selectedLabId;
  String? selectedLabName;

  String patientName = "";
  String patientPhone = "";

  String collectionMode = "homeCollection".tr();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  String? selectedAddressId;


  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> initialize() async {
    try {
      _selectedTests = List<String>.from(_selectedTests);

      final prefs = await SharedPreferences.getInstance();

      patientName =
          prefs.getString("patientName") ??
              prefs.getString("userName") ??
              "patient".tr();

      patientPhone =
          prefs.getString("patientPhone") ??
              prefs.getString("userPhone") ??
              "";

      await loadLabs();
      await loadAllAvailableTests();

      // If this page was opened with an already selected test,
      // open the booking-options step directly.
      if (_selectedTests.isNotEmpty) {
        final requestedName =
            _selectedTests.first.trim().toLowerCase();

        for (final test in allAvailableTests) {
          final name =
              test["testName"]?.toString().trim().toLowerCase() ?? "";

          if (name == requestedName) {
            selectedTestDetails = test;
            selectedLabId = test["labId"]?.toString();
            selectedLabName = test["labName"]?.toString();
            workflowStep = 2;
            break;
          }
        }
      }

      if (selectedLabId != null &&
          selectedLabId!.isNotEmpty) {
        await loadLabTests(selectedLabId!);
      }

      await loadSavedAddresses();
    } catch (e) {
      debugPrint(
        "INITIALIZE BOOK LAB ERROR = $e",
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // =========================================================
  // LOAD LABS
  // =========================================================

  Future<void> loadLabs() async {
    try {
      final data = await ApiService.getLabs();

      labs = data;

      if (labs.isNotEmpty) {
        selectedLabId =
            labs.first["_id"]?.toString();

        selectedLabName =
            labs.first["name"]?.toString();
      }
    } catch (e) {
      debugPrint(
        "LOAD LABS ERROR = $e",
      );
    }
  }

  // =========================================================
  // LOAD LAB TESTS / PRICES
  // =========================================================

  Future<void> loadLabTests(String labId) async {
    if (labId.isEmpty) return;

    if (mounted) {
      setState(() {
        isLoadingTests = true;
      });
    }

    try {
      final data =
          await ApiService.getLabTestsByLab(
        labId,
      );

      labTests = data;

      debugPrint(
        "LAB TEST PRICE DATA = $labTests",
      );
    } catch (e) {
      debugPrint(
        "LOAD LAB TESTS ERROR = $e",
      );

      labTests = [];
    }

    if (!mounted) return;

    setState(() {
      isLoadingTests = false;
    });
  }

  // =========================================================
  // LOAD ALL AVAILABLE LAB TESTS
  // =========================================================

  Future<void> loadAllAvailableTests() async {
    if (mounted) {
      setState(() {
        isLoadingAvailableTests = true;
      });
    }

    try {
      final List<Map<String, dynamic>> result = [];

      for (final lab in labs) {
        final labId = lab["_id"]?.toString() ?? "";
        final labName = lab["name"]?.toString() ?? "laboratory".tr();

        if (labId.isEmpty) continue;

        try {
          final tests = await ApiService.getLabTestsByLab(labId);

          for (final rawTest in tests) {
            final test = Map<String, dynamic>.from(rawTest);

            if (test["isActive"] == false) continue;

            test["labId"] = labId;
            test["labName"] = labName;

            result.add(test);
          }
        } catch (e) {
          debugPrint(
            "LOAD TESTS FOR LAB $labId ERROR = $e",
          );
        }
      }

      allAvailableTests = result;

      debugPrint(
        "ALL AVAILABLE LAB TESTS = ${allAvailableTests.length}",
      );
    } catch (e) {
      debugPrint(
        "LOAD ALL LAB TESTS ERROR = $e",
      );
      allAvailableTests = [];
    }

    if (!mounted) return;

    setState(() {
      isLoadingAvailableTests = false;
    });
  }

  // =========================================================
  // LOAD SAVED ADDRESSES
  // =========================================================

  Future<void> loadSavedAddresses() async {
    if (patientPhone.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        isLoadingAddress = true;
      });
    }

    try {
      /*
       Your current address API uses userId.

       HealthHome currently stores the patient phone and
       existing address flow also uses the phone as the
       patient identifier.

       Therefore patientPhone is used here.
      */

      final response =
          await ApiService.getAddresses(
        patientPhone,
      );

      debugPrint(
        "SAVED ADDRESS RESPONSE = $response",
      );

      if (response["success"] == true) {
        final data = response["addresses"];

        if (data is List) {
          savedAddresses =
              data
                  .map(
                    (item) =>
                        Map<String, dynamic>.from(
                      item,
                    ),
                  )
                  .toList();
        }
      } else {
        savedAddresses = [];
      }

      /*
       Automatically select default address.
       If no default address exists, use first address.
      */

      if (savedAddresses.isNotEmpty) {
        Map<String, dynamic>? address;

        for (final item in savedAddresses) {
          if (item["isDefault"] == true) {
            address = item;
            break;
          }
        }

        address ??= savedAddresses.first;

        _applySavedAddress(
          address,
          updateController: true,
        );
      }
    } catch (e) {
      debugPrint(
        "LOAD SAVED ADDRESS ERROR = $e",
      );
    }

    if (!mounted) return;

    setState(() {
      isLoadingAddress = false;
    });
  }

  // =========================================================
  // APPLY SAVED ADDRESS
  // =========================================================

  void _applySavedAddress(
    Map<String, dynamic> address, {
    bool updateController = true,
  }) {
    final String id =
        address["_id"]?.toString() ?? "";

    final String fullAddress =
        address["fullAddress"]?.toString() ?? "";

    final String landmark =
        address["landmark"]?.toString() ?? "";

    final String city =
        address["city"]?.toString() ?? "";

    final String state =
        address["state"]?.toString() ?? "";

    final String pincode =
        address["pincode"]?.toString() ?? "";


    String finalAddress = fullAddress;

    /*
     Add additional saved address information
     only when it is not already part of fullAddress.
    */

    final List<String> parts = [];

    if (landmark.isNotEmpty &&
        !finalAddress
            .toLowerCase()
            .contains(landmark.toLowerCase())) {
      parts.add(landmark);
    }

    if (city.isNotEmpty &&
        !finalAddress
            .toLowerCase()
            .contains(city.toLowerCase())) {
      parts.add(city);
    }

    if (state.isNotEmpty &&
        !finalAddress
            .toLowerCase()
            .contains(state.toLowerCase())) {
      parts.add(state);
    }

    if (pincode.isNotEmpty &&
        !finalAddress.contains(pincode)) {
      parts.add(pincode);
    }

    if (parts.isNotEmpty) {
      if (finalAddress.isNotEmpty) {
        finalAddress =
            "$finalAddress, ${parts.join(", ")}";
      } else {
        finalAddress = parts.join(", ");
      }
    }

    if (updateController) {
      addressController.text = finalAddress;
    }

    if (mounted) {
      setState(() {
        selectedAddressId =
            id.isEmpty ? null : id;

      });
    }
  }

  // =========================================================
  // SELECTED LAB
  // =========================================================

  Map<String, dynamic>? get selectedLab {
    if (selectedLabId == null) {
      return null;
    }

    for (final lab in labs) {
      if (lab["_id"]?.toString() ==
          selectedLabId) {
        return Map<String, dynamic>.from(
          lab,
        );
      }
    }

    return null;
  }

  // =========================================================
  // LAB ADDRESS
  // =========================================================

  String get selectedLabAddress {
    final lab = selectedLab;

    if (lab == null) {
      return "";
    }

    return lab["address"]?.toString() ??
        lab["location"]?.toString() ??
        "";
  }

  // =========================================================
  // PRICE HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }

  double _priceForTest(String testName) {
    final searchName =
        testName.trim().toLowerCase();

    for (final test in labTests) {
      final name =
          test["testName"]
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              "";

      if (name == searchName) {
        return _toDouble(test["price"]);
      }
    }

    return 0;
  }

  double get totalAmount {
    double total = 0;

    for (final test in _selectedTests) {
      total += _priceForTest(test);
    }

    return total;
  }

  bool get allPricesAvailable {
    if (_selectedTests.isEmpty) {
      return false;
    }

    for (final test in _selectedTests) {
      if (_priceForTest(test) <= 0) {
        return false;
      }
    }

    return true;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    String title = "laboratoryTests".tr();

    if (workflowStep == 1) {
      title = "testDetails".tr();
    } else if (workflowStep == 2) {
      title = "bookLabTest".tr();
    }

    return Scaffold(
      backgroundColor: Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: workflowStep == 0
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (workflowStep == 2) {
                      workflowStep = 1;
                    } else {
                      workflowStep = 0;
                    }
                  });
                },
              ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: workflowStep == 0
          ? _buildTestListPage()
          : workflowStep == 1
              ? _buildTestDetailsPage()
              : _buildBookingOptionsBody(),
    );
  }

  // =========================================================
  // TEST LIST
  // =========================================================

  Widget _buildTestListPage() {
    final query = testSearchQuery.trim().toLowerCase();

    final categories = <String>{"All"};
    for (final test in allAvailableTests) {
      final category =
          test["category"]?.toString().trim() ?? "";
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    final filteredTests = allAvailableTests.where((test) {
      final name =
          test["testName"]?.toString().toLowerCase() ?? "";
      final category =
          test["category"]?.toString().toLowerCase() ?? "";
      final labName =
          test["labName"]?.toString().toLowerCase() ?? "";

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          category.contains(query) ||
          labName.contains(query);

      final matchesCategory =
          selectedCategory == "All" ||
          category == selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "chooseALabTest".tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "selectTestToContinue".tr(),
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 18),

          TextField(
            controller: testSearchController,
            onChanged: (value) {
              setState(() {
                testSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "searchTests".tr(),
              prefixIcon: Icon(Icons.search),
              suffixIcon: testSearchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        testSearchController.clear();
                        setState(() {
                          testSearchQuery = "";
                        });
                      },
                      icon: Icon(Icons.clear),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          SizedBox(height: 16),

          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                final selected =
                    selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 20),

          if (isLoadingAvailableTests)
            Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredTests.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(children: [
                  Icon(
                    Icons.science_outlined,
                    size: 55,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "noLabTestsFound".tr(),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "tryAnotherSearch".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredTests.map(
              (test) => _testListCard(test),
            ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _testListCard(Map<String, dynamic> test) {
    final name =
        test["testName"]?.toString() ?? "labTest".tr();
    final labName =
        test["labName"]?.toString() ?? "laboratory".tr();
    final category =
        test["category"]?.toString() ?? "general".tr();
    final price =
        _toDouble(test["price"]);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final labId =
              test["labId"]?.toString() ?? "";

          setState(() {
            selectedTestDetails = test;
            selectedLabId =
                labId.isEmpty ? null : labId;
            selectedLabName =
                test["labName"]?.toString() ??
                    "laboratory".tr();
            _selectedTests = [name];
            workflowStep = 1;
          });

          if (labId.isNotEmpty) {
            await loadLabTests(labId);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xffE8F8F5),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.science,
                  color: primaryColor,
                  size: 29,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "$labName • $category",
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      "₹${price.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TEST DETAILS
  // =========================================================

  Widget _buildTestDetailsPage() {
    final test = selectedTestDetails;

    if (test == null) {
      return Center(
        child: Text("testDetailsNotAvailable".tr()),
      );
    }

    final name =
        test["testName"]?.toString() ?? "labTest".tr();
    final labName =
        test["labName"]?.toString() ?? "laboratory".tr();
    final category =
        test["category"]?.toString() ?? "general".tr();
    final sampleType =
        test["sampleType"]?.toString() ?? "blood".tr();
    final reportTime =
        test["reportTime"]?.toString() ?? "24Hours".tr();
    final description =
        test["description"]?.toString().trim() ?? "";
    final price =
        _toDouble(test["price"]);

    return SingleChildScrollView(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xffDDF8FC),
                  Color(0xffE8FAF5),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.science,
              size: 85,
              color: Color(0xff14B8A6),
            ),
          ),

          SizedBox(height: 20),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "₹${price.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Color(0xffE8F8F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Provided by $labName",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 22),

          Text(
            "testInformation".tr(),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _detailInfoCard(
                  Icons.category_outlined,
                  "category".tr(),
                  category,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _detailInfoCard(
                  Icons.water_drop_outlined,
                  "sample".tr(),
                  sampleType,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          _detailInfoCard(
            Icons.access_time,
            "reportTime".tr(),
            reportTime,
          ),

          SizedBox(height: 22),

          Text(
            "aboutThisTest".tr(),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              description.isEmpty
                  ? "This laboratory test is provided by $labName. Please follow the laboratory's instructions before sample collection."
                  : description,
              style: TextStyle(
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),

          SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTests = [name];
                  workflowStep = 2;
                });
              },
              icon: Icon(Icons.science),
              label: Text(
                "bookThisTest".tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailInfoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 23,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOOKING OPTIONS
  // =========================================================

  Widget _buildBookingOptionsBody() {
    return SingleChildScrollView(
        padding: EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =================================================
            // SELECTED TESTS
            // =================================================

            Text(
              "selectedLabTests".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,

                    children:
                        _selectedTests
                            .map(
                              (test) {
                                final price =
                                    _priceForTest(
                                  test,
                                );

                                return Chip(
                                  backgroundColor:
                                      primaryColor,

                                  avatar:
                                      Icon(
                                    Icons.science,
                                    color:
                                        Colors.white,
                                    size: 18,
                                  ),

                                  label: Text(
                                    price > 0
                                        ? "$test • ₹${price.toStringAsFixed(0)}"
                                        : test,

                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                            .toList(),
                  ),

                  SizedBox(height: 15),

                  if (isLoadingTests)
                    Row(children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "loadingTestPrices".tr(),
                        ),
                      ],
                    ),

                  if (!isLoadingTests &&
                      !allPricesAvailable)
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Color(
                          0xfffff4e5,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "selectedTestsUnavailable".tr(),
                              style: TextStyle(
                                color:
                                    Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // =================================================
            // SELECT LABORATORY
            // =================================================

            Text(
              "selectLaboratory".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: selectedLabId,

              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,

                prefixIcon: Icon(
                  Icons.local_hospital,
                  color: primaryColor,
                ),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),

                contentPadding:
                    EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),

              items:
                  labs.map<
                      DropdownMenuItem<String>>(
                (lab) {
                  final id =
                      lab["_id"]?.toString() ??
                          "";

                  final name =
                      lab["name"]?.toString() ??
                          "laboratory".tr();

                  return DropdownMenuItem<
                      String>(
                    value: id,
                    child: Text(name),
                  );
                },
              ).toList(),

              onChanged: (value) async {
                if (value == null) return;

                final selected =
                    labs.firstWhere(
                  (lab) =>
                      lab["_id"]?.toString() ==
                      value,
                );

                setState(() {
                  selectedLabId = value;
                  selectedLabName =
                      selected["name"]
                              ?.toString() ??
                          "";
                });

                await loadLabTests(value);
              },
            ),

            SizedBox(height: 30),

            // =================================================
            // COLLECTION METHOD
            // =================================================

            Text(
              "howGiveSample".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _collectionCard(
                    title: "homeCollection".tr(),
                    subtitle:
                        "sampleCollectorVisits".tr(),
                    icon:
                        Icons.home_outlined,
                    value:
                        "homeCollection".tr(),
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: _collectionCard(
                    title: "visitLaboratory".tr(),
                    subtitle:
                        "youVisitLaboratory".tr(),
                    icon:
                        Icons.local_hospital_outlined,
                    value:
                        "visitLaboratory".tr(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 25),

            // =================================================
            // HOME COLLECTION
            // =================================================

            if (collectionMode ==
                "homeCollection".tr()) ...[
              Text(
                "sampleCollectionAddress".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15),

              // SAVED ADDRESS CARD
              if (savedAddresses.isNotEmpty)
                _savedAddressSection(),

              SizedBox(height: 12),

              TextField(
                controller: addressController,
                maxLines: 3,

                decoration: InputDecoration(
                  hintText:
                      "enterCompleteHomeAddress".tr(),

                  prefixIcon:
                      Icon(
                    Icons.location_on,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),

              
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color:
                      Color(0xffE8F8F5),
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "collectorVisitHome".tr(),
                        style: TextStyle(
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // =================================================
            // VISIT LABORATORY
            // =================================================

            if (collectionMode ==
                "visitLaboratory".tr()) ...[
              Text(
                "laboratoryVisit".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
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
                        Icon(
                          Icons.local_hospital,
                          color: primaryColor,
                          size: 30,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            selectedLabName ??
                                "laboratory".tr(),
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    Divider(),

                    SizedBox(height: 12),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.location_on,
                          color:
                              Colors.redAccent,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            selectedLabAddress
                                    .isEmpty
                                ? "labAddressAvailable".tr()
                                : selectedLabAddress,

                            style:
                                TextStyle(
                              color:
                                  Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),

                    Container(
                      padding:
                          EdgeInsets.all(
                        12,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Color(
                          0xffFFF7E6,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                                Colors.orange,
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "visitLabNoCollector".tr(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 25),

            // =================================================
            // ADDITIONAL NOTES
            // =================================================

            Text(
              "additionalNotes".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: notesController,
              maxLines: 4,

              decoration: InputDecoration(
                hintText:
                    "preferredTiming".tr(),

                prefixIcon:
                    Icon(Icons.notes),

                filled: true,
                fillColor: Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // =================================================
            // BOOKING SUMMARY
            // =================================================

            _bookingSummary(),

            SizedBox(height: 30),

            // =================================================
            // PAYMENT BUTTON
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isBooking ? null : _validateAndBook,
                icon: isBooking
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.payment,
                        color: Colors.white,
                      ),
                label: Text(
                  isBooking ? "Processing..." : "continueToPayment".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            Center(
              child: Text(
                "securePaymentRazorpay".tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),

            SizedBox(height: 25),
          ],
        ),
      );
  }

  // =========================================================
  // SAVED ADDRESS SECTION
  // =========================================================

  Widget _savedAddressSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.bookmark,
                color: primaryColor,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  "savedAddresses".tr(),
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              if (isLoadingAddress)
                SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          ...savedAddresses.map(
            (address) {
              final id =
                  address["_id"]
                          ?.toString() ??
                      "";

              final label =
                  address["label"]
                          ?.toString() ??
                      "address".tr();

              final full =
                  address["fullAddress"]
                          ?.toString() ??
                      "";

              final city =
                  address["city"]
                          ?.toString() ??
                      "";

              final isSelected =
                  selectedAddressId == id;

              return Padding(
                padding:
                    EdgeInsets.only(
                  bottom: 8,
                ),

                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  onTap: () {
                    _applySavedAddress(
                      address,
                    );
                  },

                  child: Container(
                    padding:
                        EdgeInsets.all(
                      12,
                    ),

                    decoration:
                        BoxDecoration(
                      color: isSelected
                          ? Color(
                              0xffE8F8F5,
                            )
                          : Colors.grey.shade50,

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),

                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors
                                .grey
                                .shade300,
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Icon(
                          label
                                  .toLowerCase()
                                  .contains(
                                    "home",
                                  )
                              ? Icons.home
                              : Icons.location_on,
                          color:
                              isSelected
                                  ? primaryColor
                                  : Colors.grey,
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),

                                  if (address[
                                          "isDefault"] ==
                                      true)
                                    Container(
                                      padding:
                                          EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            7,
                                        vertical:
                                            3,
                                      ),

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            primaryColor,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          20,
                                        ),
                                      ),

                                      child:
                                          Text(
                                        "default".tr(),
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize:
                                              10,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              SizedBox(
                                height: 5,
                              ),

                              Text(
                                full.isEmpty
                                    ? city
                                    : full,
                                maxLines: 3,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isSelected)
                          Icon(
                            Icons
                                .check_circle,
                            color:
                                primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COLLECTION CARD
  // =========================================================

  Widget _collectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool selected =
        collectionMode == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          collectionMode = value;
        });
      },

      child: AnimatedContainer(
        duration:
            Duration(milliseconds: 200),

        padding:
            EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: selected
              ? Color(0xffE8F8F5)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,

            width:
                selected ? 2 : 1,
          ),
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
                Icon(
                  icon,
                  size: 34,
                  color: selected
                      ? primaryColor
                      : Colors.grey,
                ),

                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: primaryColor,
                  ),
              ],
            ),

            SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
                color: selected
                    ? primaryColor
                    : Colors.black87,
              ),
            ),

            SizedBox(height: 5),

            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOOKING SUMMARY
  // =========================================================

  Widget _bookingSummary() {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
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
              Icon(
                Icons.assignment,
                color: primaryColor,
              ),

              SizedBox(width: 10),

              Text(
                "bookingSummary".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          Divider(height: 25),

          _summaryRow(
            "patient".tr(),
            patientName,
          ),

          _summaryRow(
            "phone".tr(),
            patientPhone,
          ),

          _summaryRow(
            "laboratory".tr(),
            selectedLabName ?? "",
          ),

          _summaryRow(
            "tests".tr(),
            _selectedTests.join(", "),
          ),

          _summaryRow(
            "collection".tr(),
            collectionMode,
          ),

          if (collectionMode ==
              "homeCollection".tr())
            _summaryRow(
              "address".tr(),
              addressController.text
                      .trim()
                      .isEmpty
                  ? "notSelected".tr()
                  : addressController.text
                      .trim(),
            ),

          Divider(height: 25),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                "testAmount".tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(
                "₹${totalAmount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          EdgeInsets.only(
        bottom: 9,
      ),

      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),

          children: [
            TextSpan(
              text: "$title : ",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // VALIDATE
  // =========================================================

  Future<void> _validateAndBook() async {
    if (selectedLabId == null ||
        selectedLabId!.isEmpty) {
      _showMessage(
        "Please select a laboratory",
      );
      return;
    }

    if (_selectedTests.isEmpty) {
      _showMessage(
        "pleaseSelectLabTest".tr(),
      );
      return;
    }

    if (isLoadingTests) {
      _showMessage(
        "pleaseWaitPrices".tr(),
      );
      return;
    }

    if (!allPricesAvailable) {
      _showMessage(
        "testsUnavailableAtLab".tr(),
      );
      return;
    }

    if (totalAmount <= 0) {
      _showMessage(
        "unableCalculateLabAmount".tr(),
      );
      return;
    }

    if (patientPhone.isEmpty) {
      _showMessage(
        "phoneNotFoundLogin".tr(),
      );
      return;
    }

    if (collectionMode ==
            "homeCollection".tr() &&
        addressController.text
            .trim()
            .isEmpty) {
      _showMessage(
        "selectHomeAddress".tr(),
      );
      return;
    }

    await _bookLabTest();
  }

  // =========================================================
  // BOOK LAB TEST + RAZORPAY PAYMENT
  // =========================================================

  Future<void> _bookLabTest() async {
    if (isBooking) return;

    setState(() {
      isBooking = true;
    });

    String createdOrderId = "";

    try {
      // 1. Create the lab booking.
      // Payment is completed immediately after this booking is created.
      final orderResponse = await ApiService.placeLabOrder(
        patientId: patientPhone,
        patientName: patientName,
        patientPhone: patientPhone,
        labId: selectedLabId ?? "",
        labName: selectedLabName ?? "",
        address: collectionMode == "homeCollection".tr()
            ? addressController.text.trim()
            : selectedLabAddress,
        notes: notesController.text.trim(),
        prescriptionImage: "",
        tests: _selectedTests,
        collectionMode: collectionMode,
        bookingType: "test".tr(),
      );

      debugPrint("LAB ORDER RESPONSE = $orderResponse");

      final bool orderSuccess = orderResponse["success"] == true;

      if (!orderSuccess) {
        throw Exception(
          orderResponse["message"] ?? "unableCreateLabBooking".tr(),
        );
      }

      // 2. Get the exact LabOrder ID created by the backend.
      final dynamic orderData = orderResponse["order"];

      if (orderData is Map) {
        createdOrderId =
            orderData["_id"]?.toString() ??
            orderData["id"]?.toString() ??
            "";
      }

      if (createdOrderId.isEmpty) {
        createdOrderId =
            orderResponse["_id"]?.toString() ??
            orderResponse["orderId"]?.toString() ??
            "";
      }

      if (createdOrderId.isEmpty) {
        throw Exception(
          "Lab order was created but order ID was not returned by the server.",
        );
      }

      debugPrint("CREATED LAB ORDER ID = $createdOrderId");

      // 3. Verify the exact LabOrder before opening Razorpay.
      try {
        final savedOrder = await ApiService.getLabOrderById(
          createdOrderId,
        );

        debugPrint("LAB ORDER VERIFY RESPONSE = $savedOrder");

        if (savedOrder["success"] != true &&
            savedOrder["order"] == null) {
          throw Exception(
            savedOrder["message"] ??
                "labBookingCouldNotVerify".tr(),
          );
        }
      } catch (e) {
        debugPrint("LAB ORDER VERIFY ERROR = $e");
        throw Exception(
          "labBookingVerificationFailed".tr(),
        );
      }

      if (!mounted) return;

      // 4. Open the existing HealthHome Razorpay payment screen.
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            amount: totalAmount,
            userId: patientPhone,
            userName: patientName,
            userPhone: patientPhone,
            serviceType: "Lab",
            serviceId: createdOrderId,
          ),
        ),
      );

      if (!mounted) return;

      debugPrint("LAB PAYMENT RESULT = $paymentResult");

      // 5. Only show booking success after Razorpay returns success.
      if (paymentResult == true) {
        setState(() {
          isBooking = false;
        });

        _showSuccessDialog(createdOrderId);
        return;
      }

      // Payment cancelled/failed. Do not show a false success message.
      setState(() {
        isBooking = false;
      });

      _showMessage(
        "labPaymentPending".tr(),
      );
    } catch (e) {
      debugPrint("BOOK LAB + PAYMENT ERROR = $e");

      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      _showMessage(
        "Unable to continue: $e",
        isError: true,
      );
    }
  }

  // =========================================================
  // SUCCESS DIALOG
  // =========================================================

  void _showSuccessDialog(
    String orderId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        title: Row(children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                "bookingSuccessful".tr(),
              ),
            ),
          ],
        ),

        content: Text(
          collectionMode ==
                  "homeCollection".tr()
              ? "Your lab booking has been confirmed with $selectedLabName.\n\nYour payment was successful. A sample collector will be assigned by the laboratory."
              : "Your lab booking has been confirmed with $selectedLabName.\n\nYour payment was successful. Please visit the laboratory for sample collection as selected.",
        ),

        actions: [
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  primaryColor,
            ),

            onPressed: () {
              // Close the success dialog first.
              Navigator.pop(context);

              // Return TRUE to MyPrescriptionPage so it knows
              // that the selected lab tests were successfully booked.
              Navigator.pop(context, true);
            },

            child: Text(
              "OK",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            isError
                ? Colors.red
                : null,

        content: Text(
          message,
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    addressController.dispose();
    notesController.dispose();
    testSearchController.dispose();

    super.dispose();
  }
}
