import 'package:flutter/material.dart';

import 'profile_image.dart';

/// A resilient provider selector that avoids dropdown value assertions when
/// provider data is still loading or has duplicate display names.
class ProviderPicker extends StatelessWidget {
  final List<dynamic> providers;
  final String? selectedId;
  final String title;
  final String emptyMessage;
  final String? errorMessage;
  final IconData fallbackIcon;
  final bool isLoading;
  final VoidCallback? onRetry;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const ProviderPicker({
    super.key,
    required this.providers,
    required this.selectedId,
    required this.title,
    required this.emptyMessage,
    required this.fallbackIcon,
    required this.onSelected,
    this.errorMessage,
    this.isLoading = false,
    this.onRetry,
  });

  List<Map<String, dynamic>> get _options {
    final unique = <String, Map<String, dynamic>>{};
    for (final raw in providers) {
      if (raw is! Map) continue;
      final provider = Map<String, dynamic>.from(raw);
      final id = provider["_id"]?.toString().trim() ?? "";
      if (id.isEmpty) continue;
      unique.putIfAbsent(id, () => provider);
    }
    return unique.values.toList();
  }

  Map<String, dynamic>? _selected(List<Map<String, dynamic>> options) {
    for (final option in options) {
      if (option["_id"]?.toString() == selectedId) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final selected = _selected(options);
    final imageUrl = (selected?["profileImageUrl"] ?? selected?["image"] ?? "")
        .toString();
    final name = selected?["name"]?.toString().trim() ?? "";
    final address = selected?["address"]?.toString().trim() ?? "";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isLoading || options.isEmpty
            ? null
            : () => _openPicker(context, options),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                HealthHomeProfileAvatar(
                  imageUrl: imageUrl,
                  radius: 22,
                  fallbackIcon: fallbackIcon,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? "Loading $title..."
                          : name.isNotEmpty
                              ? name
                              : errorMessage ??
                                  (options.isEmpty
                                      ? emptyMessage
                                      : "Tap to select $title"),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: name.isNotEmpty ? Colors.black87 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isLoading && name.isNotEmpty && address.isNotEmpty)
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
              if (!isLoading && options.isNotEmpty)
                const Icon(Icons.keyboard_arrow_down_rounded),
              if (!isLoading && options.isEmpty && onRetry != null)
                IconButton(
                  tooltip: "Retry",
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    List<Map<String, dynamic>> options,
  ) async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Select $title",
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final id = option["_id"]?.toString() ?? "";
                    final providerName =
                        option["name"]?.toString().trim().isNotEmpty == true
                            ? option["name"].toString().trim()
                            : title;
                    final providerAddress =
                        option["address"]?.toString().trim() ?? "";
                    return ListTile(
                      leading: HealthHomeProfileAvatar(
                        imageUrl: (option["profileImageUrl"] ??
                                option["image"] ??
                                "")
                            .toString(),
                        radius: 24,
                        fallbackIcon: fallbackIcon,
                      ),
                      title: Text(providerName),
                      subtitle: providerAddress.isEmpty
                          ? null
                          : Text(
                              providerAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: id == selectedId
                          ? const Icon(Icons.check_circle, color: Color(0xff14B8A6))
                          : null,
                      onTap: () => Navigator.pop(sheetContext, option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) onSelected(selected);
  }
}
