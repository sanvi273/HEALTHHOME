class PatientReport {
  const PatientReport({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  factory PatientReport.fromJson(dynamic value) {
    if (value is String) {
      final legacyValue = value.trim();
      final legacyUrl = _validReportUrl({"fileUrl": legacyValue});
      final uri = Uri.tryParse(legacyUrl);
      final storedName = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : legacyValue;
      final fallbackName = storedName.isEmpty ? "Patient Report" : storedName;
      final legacyType =
          fallbackName.toLowerCase().endsWith(".pdf") ? "application/pdf" : "";
      return PatientReport(
        fileName: fallbackName,
        fileUrl: legacyUrl,
        fileType: legacyType,
      );
    }

    final report = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final rawName = report["fileName"]?.toString().trim() ?? "";
    final rawType = report["fileType"]?.toString().trim() ?? "";

    return PatientReport(
      fileName: rawName.isEmpty ? "Patient Report" : rawName,
      fileUrl: _validReportUrl(report),
      fileType: rawType.toLowerCase(),
    );
  }

  final String fileName;
  final String fileUrl;
  final String fileType;

  bool get isPdf {
    final path = Uri.tryParse(fileUrl)?.path.toLowerCase() ?? "";
    return fileType.contains("pdf") ||
        fileName.toLowerCase().endsWith(".pdf") ||
        path.endsWith(".pdf");
  }
}

String _validReportUrl(Map<String, dynamic> report) {
  for (final key in const [
    "fileUrl",
    "secure_url",
    "secureUrl",
    "reportUrl",
    "url",
  ]) {
    final value = report[key]?.toString().trim() ?? "";
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == "http" || uri.scheme == "https") &&
        uri.host.isNotEmpty) {
      return uri.toString();
    }
  }
  return "";
}
