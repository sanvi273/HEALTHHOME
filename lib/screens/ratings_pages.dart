import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/rating_display.dart';

String _entityLabel(String type) {
  switch (type) {
    case "doctor":
      return "Doctor";
    case "laboratory":
      return "Laboratory";
    case "pharmacy":
      return "Pharmacy";
    default:
      return "Provider";
  }
}

String _shortDate(dynamic raw) {
  if (raw == null) return "";
  final value = DateTime.tryParse(raw.toString());
  if (value == null) return "";
  return "${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}";
}

class PatientReviewsPage extends StatefulWidget {
  const PatientReviewsPage({super.key});

  @override
  State<PatientReviewsPage> createState() => _PatientReviewsPageState();
}

class _PatientReviewsPageState extends State<PatientReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final items = await ApiService.getEligibleReviews();
      if (!mounted) return;
      setState(() { reviews = items; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _writeReview(Map<String, dynamic> item) async {
    var selectedRating = 5;
    final controller = TextEditingController();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Review ${item['providerName'] ?? 'provider'}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("How was your experience?"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setSheetState(() => selectedRating = index + 1),
                  icon: Icon(
                    index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                )),
              ),
              TextField(
                controller: controller,
                maxLength: 600,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Your review (optional)",
                  hintText: "Share what went well or what could be better",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, {
                    "rating": selectedRating,
                    "review": controller.text.trim(),
                  }),
                  child: const Text("Submit review"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;

    try {
      await ApiService.submitRating(
        entityType: item["entityType"].toString(),
        targetId: item["targetId"].toString(),
        transactionId: item["transactionId"].toString(),
        rating: result["rating"] as int,
        review: result["review"]?.toString() ?? "",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanks for sharing your review.")),
      );
      await loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to submit review: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ratings & Reviews")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _MessageState(message: error!, onRetry: loadReviews)
              : reviews.isEmpty
                  ? const _MessageState(
                      message: "Completed appointments, lab tests, and delivered medicine orders will appear here.",
                    )
                  : RefreshIndicator(
                      onRefresh: loadReviews,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = reviews[index];
                          final alreadyReviewed = item["reviewed"] == true;
                          final type = item["entityType"]?.toString() ?? "";
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xffE7F7F6),
                                        child: Icon(
                                          type == "doctor"
                                              ? Icons.medical_services_outlined
                                              : type == "laboratory"
                                                  ? Icons.science_outlined
                                                  : Icons.local_pharmacy_outlined,
                                          color: const Color(0xff008F91),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item["providerName"]?.toString() ?? "Provider",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            Text("${_entityLabel(type)} • ${_shortDate(item['serviceDate'])}"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (alreadyReviewed) ...[
                                    RatingStars(rating: (item["rating"] as num?) ?? 0),
                                    if ((item["review"]?.toString() ?? "").isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(item["review"].toString()),
                                    ],
                                    const SizedBox(height: 6),
                                    const Text("Your review", style: TextStyle(color: Color(0xff008F91), fontWeight: FontWeight.w600)),
                                  ] else
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _writeReview(item),
                                        icon: const Icon(Icons.rate_review_outlined),
                                        label: const Text("Rate this service"),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class ProviderRatingsTabPage extends StatefulWidget {
  const ProviderRatingsTabPage({super.key});

  @override
  State<ProviderRatingsTabPage> createState() => _ProviderRatingsTabPageState();
}

class _ProviderRatingsTabPageState extends State<ProviderRatingsTabPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final value = await ApiService.getProviderReviews();
      if (!mounted) return;
      setState(() { data = value; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = data?["summary"] is Map
        ? Map<String, dynamic>.from(data!["summary"] as Map)
        : <String, dynamic>{};
    final reviews = data?["reviews"] is List ? data!["reviews"] as List : const [];
    final type = data?["entityType"]?.toString() ?? "provider";

    return Scaffold(
      appBar: AppBar(title: const Text("Ratings & Reviews")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _MessageState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: const Color(0xffF0FAF9),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 42, color: Colors.amber),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (summary["ratingCount"] as num? ?? 0) > 0
                                        ? ((summary["rating"] as num?) ?? 0).toStringAsFixed(1)
                                        : "New",
                                    style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                                  ),
                                  Text("${summary['ratingCount'] ?? 0} verified reviews • ${_entityLabel(type)}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: Text("Reviews from your patients will appear here.")),
                        )
                      else
                        ...reviews.whereType<Map>().map((raw) {
                          final item = Map<String, dynamic>.from(raw);
                          final comment = item["review"]?.toString() ?? "";
                          return Card(
                            child: ListTile(
                              title: Row(
                                children: [
                                  RatingStars(rating: (item["rating"] as num?) ?? 0, size: 16),
                                  const SizedBox(width: 8),
                                  Text(_shortDate(item["createdAt"])),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(comment.isEmpty ? "Star rating only" : comment),
                              ),
                              leading: const CircleAvatar(child: Icon(Icons.verified_user_outlined)),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class PublicProviderReviewsPage extends StatefulWidget {
  final String entityType;
  final String targetId;
  final String providerName;

  const PublicProviderReviewsPage({
    super.key,
    required this.entityType,
    required this.targetId,
    required this.providerName,
  });

  @override
  State<PublicProviderReviewsPage> createState() => _PublicProviderReviewsPageState();
}

class _PublicProviderReviewsPageState extends State<PublicProviderReviewsPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final value = await ApiService.getPublicReviews(
        entityType: widget.entityType,
        targetId: widget.targetId,
      );
      if (!mounted) return;
      setState(() { data = value; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = data?["summary"] is Map
        ? Map<String, dynamic>.from(data!["summary"] as Map)
        : <String, dynamic>{};
    final reviews = data?["reviews"] is List ? data!["reviews"] as List : const [];
    return Scaffold(
      appBar: AppBar(title: Text("${widget.providerName} reviews")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _MessageState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: const Color(0xffF0FAF9),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 42, color: Colors.amber),
                              const SizedBox(width: 10),
                              Text(
                                (summary["ratingCount"] as num? ?? 0) > 0
                                    ? ((summary["rating"] as num?) ?? 0).toStringAsFixed(1)
                                    : "New",
                                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text("${summary['ratingCount'] ?? 0} verified reviews"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: Text("No reviews yet.")),
                        )
                      else
                        ...reviews.whereType<Map>().map((raw) {
                          final item = Map<String, dynamic>.from(raw);
                          final comment = item["review"]?.toString() ?? "";
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.verified_user_outlined)),
                              title: Row(
                                children: [
                                  RatingStars(rating: (item["rating"] as num?) ?? 0, size: 16),
                                  const SizedBox(width: 8),
                                  Text(_shortDate(item["createdAt"])),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(comment.isEmpty ? "Star rating only" : comment),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ],
          ),
        ),
      );
}
