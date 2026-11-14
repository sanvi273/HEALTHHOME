import 'dart:typed_data';

class PatientReportUpload {
  PatientReportUpload({
    required this.fileName,
    required List<int> bytes,
  }) : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final Uint8List bytes;
}
