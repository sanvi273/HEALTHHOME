import 'package:flutter/material.dart';

class MedicineImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const MedicineImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  Widget _fallback() => Image.asset(
        'assets/images/medicine.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          color: const Color(0xffE8FAFB),
          child: const Icon(
            Icons.medication_outlined,
            color: Color(0xff00C2CB),
            size: 40,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    final validHttpsUrl =
        uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

    final image = !validHttpsUrl
        ? _fallback()
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                color: const Color(0xffF1FBFB),
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff00C2CB),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _fallback(),
          );

    return ClipRRect(
      borderRadius: borderRadius,
      child: image,
    );
  }
}
