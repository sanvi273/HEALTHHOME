import 'package:flutter_test/flutter_test.dart';
import 'package:healthhome/models/patient_report.dart';

void main() {
  group('PatientReport', () {
    test('reads the stored filename and secure fileUrl', () {
      final report = PatientReport.fromJson({
        '_id': '507f1f77bcf86cd799439044',
        'canView': true,
        'fileName': 'blood-test.jpg',
        'fileType': 'image/jpeg',
        'fileUrl': 'https://res.cloudinary.com/healthhome/report.jpg',
      });

      expect(report.fileName, 'blood-test.jpg');
      expect(report.reportId, '507f1f77bcf86cd799439044');
      expect(report.canView, isTrue);
      expect(
          report.fileUrl, 'https://res.cloudinary.com/healthhome/report.jpg');
      expect(report.isPdf, isFalse);
    });

    test('supports older URL key aliases and PDF metadata', () {
      final report = PatientReport.fromJson({
        '_id': '507f1f77bcf86cd799439044',
        'canView': true,
        'fileName': 'scan.pdf',
        'secure_url': 'https://res.cloudinary.com/healthhome/scan',
      });

      expect(report.fileUrl, 'https://res.cloudinary.com/healthhome/scan');
      expect(report.canView, isTrue);
      expect(report.isPdf, isTrue);
    });

    test('requires an authorized report ID before it can be viewed', () {
      final report = PatientReport.fromJson({
        'fileName': 'old-report.jpg',
        'fileUrl': 'https://res.cloudinary.com/healthhome/report.jpg',
      });

      expect(report.fileUrl, isNotEmpty);
      expect(report.reportId, isEmpty);
      expect(report.canView, isFalse);
    });

    test('supports legacy string URLs and keeps legacy filenames unavailable',
        () {
      final storedUrl = PatientReport.fromJson(
        'https://res.cloudinary.com/healthhome/legacy-scan.png',
      );
      final oldFilename = PatientReport.fromJson('legacy-scan.png');

      expect(storedUrl.fileUrl,
          'https://res.cloudinary.com/healthhome/legacy-scan.png');
      expect(storedUrl.fileName, 'legacy-scan.png');
      expect(oldFilename.fileName, 'legacy-scan.png');
      expect(oldFilename.fileUrl, isEmpty);
    });

    test('marks missing or non-web paths unavailable without inventing a URL',
        () {
      final missing = PatientReport.fromJson({'fileName': 'old-report.jpg'});
      final localPath = PatientReport.fromJson({
        'fileName': 'old-report.jpg',
        'fileUrl': 'C:\\uploads\\old-report.jpg',
      });

      expect(missing.fileUrl, isEmpty);
      expect(localPath.fileUrl, isEmpty);
      expect(missing.fileName, 'old-report.jpg');
    });

    test('uses a readable fallback filename for malformed report entries', () {
      final report = PatientReport.fromJson(null);

      expect(report.fileName, 'Patient Report');
      expect(report.fileUrl, isEmpty);
    });
  });
}
