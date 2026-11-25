import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/rating_display.dart';
import '../ratings_pages.dart';

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
                final pharmacyId = pharmacy["_id"]?.toString() ?? "";
                final rating = pharmacy["rating"] is num
                    ? pharmacy["rating"] as num
                    : num.tryParse(pharmacy["rating"]?.toString() ?? "") ?? 0;
                final ratingCount = pharmacy["ratingCount"] is num
                    ? pharmacy["ratingCount"] as num
                    : num.tryParse(pharmacy["ratingCount"]?.toString() ?? "") ?? 0;

                return Card(
                  child: ListTile(
                    leading: HealthHomeProfileAvatar(
                      imageUrl: pharmacy["profileImageUrl"]?.toString(),
                      radius: 24,
                      fallbackIcon: Icons.local_pharmacy,
                    ),
                    title: Text(
                      pharmacy["name"],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacy["address"] ?? ""),
                        const SizedBox(height: 4),
                        RatingSummaryLink(
                          rating: rating,
                          count: ratingCount,
                          onTap: pharmacyId.isEmpty
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicProviderReviewsPage(
                                        entityType: "pharmacy",
                                        targetId: pharmacyId,
                                        providerName: pharmacy["name"]?.toString() ?? "Pharmacy",
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
