import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../services/api_service.dart';
import 'doctor_profile_page.dart';

class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({super.key});

  @override
  State<DoctorsListPage> createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  List doctors = [];
  bool loading = true;

  String searchText = "";
  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "General Physician",
    "Cardiology",
    "Dermatology",
    "Orthopedics",
    "Pediatrics",
    "Gynecology",
    "ENT",
    "Ophthalmology",
    "Dentistry",
    "Neurology",
    "Gastroenterology",
    "Urology",
    "Psychiatry",
    "Pulmonology",
  ];

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      doctors = await ApiService.getDoctors();
    } catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // Translation key for doctor category
  String _categoryKey(String category) {
    switch (category) {
      case "All":
        return "all";
      case "General Physician":
        return "generalPhysician";
      case "Cardiology":
        return "cardiology";
      case "Dermatology":
        return "dermatology";
      case "Orthopedics":
        return "orthopedics";
      case "Pediatrics":
        return "pediatrics";
      case "Gynecology":
        return "gynecology";
      case "ENT":
        return "ent";
      case "Ophthalmology":
        return "ophthalmology";
      case "Dentistry":
        return "dentistry";
      case "Neurology":
        return "neurology";
      case "Gastroenterology":
        return "gastroenterology";
      case "Urology":
        return "urology";
      case "Psychiatry":
        return "psychiatry";
      case "Pulmonology":
        return "pulmonology";
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = doctors.where((doctor) {
      final matchesSearch = (doctor["name"] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchText);

      final matchesCategory = selectedCategory == "All"
          ? true
          : (doctor["specialization"] ?? "")
              .toString()
              .toLowerCase()
              .contains(selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "doctors".tr(),
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "searchDoctor".tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value.toLowerCase();
                      });
                    },
                  ),
                ),

                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        child: ChoiceChip(
                          label: Text(
                            _categoryKey(category).tr(),
                          ),
                          selected: selectedCategory == category,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: filteredDoctors.isEmpty
                      ? Center(
                          child: Text(
                            "noDoctorsFound".tr(),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DoctorProfilePage(
                                        doctor: doctor,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor:
                                            Colors.blue.shade100,
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                        ),
                                      ),

                                      const SizedBox(width: 15),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor["name"] ?? "",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            Text(
                                              doctor["specialization"] ?? "",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            Text(
                                              "${doctor["experience"] ?? "0"} ${"yearsExperience".tr()}",
                                            ),

                                            Text(
                                              doctor["hospital"] ?? "",
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),

                                                const Text("4.8"),

                                                const Spacer(),

                                                Text(
                                                  "₹${doctor["fees"]}",
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
  }
}