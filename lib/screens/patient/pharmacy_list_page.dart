import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PharmacyListPage extends StatefulWidget {
  const PharmacyListPage({super.key});

  @override
  State<PharmacyListPage> createState() =>
      _PharmacyListPageState();
}

class _PharmacyListPageState
    extends State<PharmacyListPage> {

  List pharmacies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPharmacies();
  }

  Future<void> loadPharmacies() async {

    pharmacies =
        await ApiService.getPharmacies();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pharmacies",
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount:
                  pharmacies.length,
              itemBuilder:
                  (context, index) {

                final pharmacy =
                    pharmacies[index];

                return Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.local_pharmacy,
                    ),
                    title: Text(
                      pharmacy["name"],
                    ),
                    subtitle: Text(
                      pharmacy["address"] ??
                          "",
                    ),
                  ),
                );
              },
            ),
    );
  }
}