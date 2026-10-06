import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/api_service.dart';
import 'upload_prescription_page.dart';
import 'my_cart_page.dart';

class HealthHomePharmacyPage extends StatefulWidget {
  const HealthHomePharmacyPage({super.key});

  @override
  State<HealthHomePharmacyPage> createState() =>
      _HealthHomePharmacyPageState();
}

class _HealthHomePharmacyPageState
    extends State<HealthHomePharmacyPage> {
  List medicines = [];
  List filteredMedicines = [];

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    try {
      final data =
          await ApiService.getMedicines();

      setState(() {
        medicines = data;
        filteredMedicines = data;
      });
    } catch (e) {
      print("ERROR = $e");
    }
  }

  void searchMedicine(String value) {
    setState(() {
      filteredMedicines = medicines
          .where(
            (medicine) => medicine[
                    "medicineName"]
                .toString()
                .toLowerCase()
                .contains(
                  value.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF7F8FA),

      
     appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  centerTitle: true,
  title: Text(
    "totalMedicines".tr() + " (${filteredMedicines.length})",
    style: const TextStyle(
      color: Color(0xff0A1B5E),
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(
        Icons.shopping_cart,
        color: Colors.black,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyCartPage(),
          ),
        );
      },
    ),
  ],
),
  

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [

                TextField(
                  controller:
                      searchController,
                  onChanged:
                      searchMedicine,
                  decoration:
                      InputDecoration(
                    hintText:
                        "searchMedicines".tr(),
                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              15),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 55,
                  child:
                      ElevatedButton.icon(
                    icon: const Icon(
                      Icons.upload,
                      color:
                          Colors.white,
                    ),
                    label: Text(
                      "uploadPrescription".tr(),
                      style: TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xff00C2CB),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UploadPrescriptionPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

         Expanded(
  child: ListView.builder(
    itemCount: filteredMedicines.length,
    itemBuilder: (context, index) {
      final medicine =
          filteredMedicines[index];

      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        elevation: 2,
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor:
                Color(0xffEAFBF8),
            child: Icon(
              Icons.medication,
              color: Color(0xff00C2CB),
            ),
          ),
          title: Text(
            medicine["medicineName"]
                .toString(),
          ),
          subtitle: Text(
            "₹${medicine["price"]}",
          ),
         trailing: ElevatedButton(
  onPressed: () async {
    try {
    final response = await ApiService.addMedicineToCart(
  patientId: "7041337601",
  patientName: "patient".tr(),
  medicineId: medicine["_id"].toString(),
  medicine: medicine["medicineName"].toString(),
  dose: "",
  duration: "",
  food: "",
  instruction: "",
  quantity: 1,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(response["message"]),
  ),
);

      if (!mounted) return;

      
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  },
  child: Text("add".tr()),
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