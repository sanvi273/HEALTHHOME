import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhome/login_screen.dart';
import 'package:healthhome/role_selection_screen.dart';
import 'package:healthhome/services/api_service.dart';
import 'package:healthhome/terms_acceptance_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _roleDocuments = <({String role, String label, String documentType})>[
  (role: 'patient', label: 'Patient', documentType: 'patient_individual'),
  (role: 'doctor', label: 'Doctor', documentType: 'doctor_partner'),
  (
    role: 'laboratory',
    label: 'Laboratory',
    documentType: 'laboratory_partner',
  ),
  (role: 'pharmacy', label: 'Pharmacy', documentType: 'pharmacy_partner'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late http.Client originalTermsClient;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    originalTermsClient = ApiService.termsClient;
  });

  tearDown(() {
    ApiService.termsClient.close();
    ApiService.termsClient = originalTermsClient;
  });

  testWidgets('all role cards show their terms and continue to matching login',
      (tester) async {
    for (final item in _roleDocuments) {
      SharedPreferences.setMockInitialValues({});
      final acceptedBodies = <Map<String, dynamic>>[];
      final document = _documentFor(item.role, item.documentType);
      ApiService.termsClient = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/terms/${item.role}/current');
          return http.Response(jsonEncode(document), 200);
        }
        expect(request.url.path, '/api/terms/accept');
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        acceptedBodies.add(body);
        return http.Response(
          jsonEncode({
            'success': true,
            'acceptanceToken': body['onboardingSessionToken'],
            'role': item.role,
            'termsVersion': document['version'],
            'acceptedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          }),
          201,
        );
      });

      await tester.pumpWidget(
        _localizedApp(
          const RoleSelectionScreen(),
          key: ValueKey('terms-flow-${item.role}'),
        ),
      );
      await tester.pumpAndSettle();
      final roleCard = find.byKey(ValueKey('role-selection-${item.role}'));
      await tester.ensureVisible(roleCard);
      await tester.tap(roleCard);
      await tester.pumpAndSettle();

      expect(find.text(document['title']! as String), findsOneWidget);
      expect(find.text('For ${item.label} · Version 1.0.0'), findsOneWidget);

      final checkboxFinder = find.byType(CheckboxListTile);
      final checkbox = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(checkbox.value, isFalse);
      expect(checkbox.onChanged, isNull);
      expect(_continueButton(tester).onPressed, isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -12000),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(checkboxFinder).onChanged,
        isNotNull,
      );
      expect(_continueButton(tester).onPressed, isNull);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isTrue);
      expect(_continueButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('I Agree & Continue'));
      await tester.pumpAndSettle();

      expect(acceptedBodies, hasLength(1));
      expect(acceptedBodies.single['selectedRole'], item.role);
      expect(acceptedBodies.single['termsDocumentType'], item.documentType);
      expect(acceptedBodies.single['termsVersion'], '1.0.0');
      expect(acceptedBodies.single['accepted'], isTrue);
      expect(
        acceptedBodies.single['onboardingSessionToken'],
        matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      );
      expect(find.byType(TermsAcceptanceScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).role,
          item.label);
    }
  });

  testWidgets('backend failure keeps user on Terms page and shows an error',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final document = _documentFor('doctor', 'doctor_partner');
    ApiService.termsClient = MockClient((request) async {
      if (request.method == 'GET')
        return http.Response(jsonEncode(document), 200);
      return http.Response(
        jsonEncode({
          'success': false,
          'message': 'Acceptance could not be saved. Try again.',
        }),
        503,
      );
    });

    await tester.pumpWidget(
      _localizedApp(const TermsAcceptanceScreen(
        selectedRole: 'doctor',
        roleLabel: 'Doctor',
      )),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -12000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I Agree & Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsAcceptanceScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(
        find.text('Acceptance could not be saved. Try again.'), findsOneWidget);
  });

  testWidgets('valid current acceptance skips Terms and opens matching login',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'termsAcceptanceToken_patient': 'existing-token',
      'termsAcceptanceVersion_patient': '1.0.0',
    });
    ApiService.termsClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
            jsonEncode(_documentFor('patient', 'patient_individual')), 200);
      }
      expect(request.url.path, '/api/terms/acceptance/validate');
      expect(jsonDecode(request.body)['acceptanceToken'], 'existing-token');
      return http.Response(jsonEncode({
        'accepted': true,
        'role': 'patient',
        'termsVersion': '1.0.0',
      }), 200);
    });

    await tester.pumpWidget(_localizedApp(const TermsAcceptanceScreen(
      selectedRole: 'patient',
      roleLabel: 'Patient',
    )));
    await tester.pumpAndSettle();

    expect(find.byType(TermsAcceptanceScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).role, 'Patient');
  });

  testWidgets('changed terms version requires review and new acceptance',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'termsAcceptanceToken_patient': 'old-token',
      'termsAcceptanceVersion_patient': '1.0.0',
    });
    ApiService.termsClient = MockClient((request) async {
      if (request.method == 'GET') {
        final document = _documentFor('patient', 'patient_individual');
        document['version'] = '2.0.0';
        return http.Response(jsonEncode(document), 200);
      }
      if (request.url.path == '/api/terms/acceptance/validate') {
        return http.Response(jsonEncode({'accepted': false}), 200);
      }
      return http.Response(jsonEncode({
        'success': true,
        'acceptanceToken': jsonDecode(request.body)['onboardingSessionToken'],
        'role': 'patient',
        'termsVersion': '2.0.0',
      }), 201);
    });

    await tester.pumpWidget(_localizedApp(const TermsAcceptanceScreen(
      selectedRole: 'patient',
      roleLabel: 'Patient',
    )));
    await tester.pumpAndSettle();
    expect(find.text('For Patient · Version 2.0.0'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -12000));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I Agree & Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.widget<LoginScreen>(find.byType(LoginScreen)).role, 'Patient');
  });

  testWidgets('Terms page fits a narrow dark-theme viewport without overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    ApiService.termsClient = MockClient((request) async => http.Response(
        jsonEncode(_documentFor('patient', 'patient_individual')), 200));
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const TermsAcceptanceScreen(
          selectedRole: 'patient',
          roleLabel: 'Patient',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HealthHome Patient Terms'), findsOneWidget);
    expect(find.text('I Agree & Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}

Widget _localizedApp(Widget home, {Key? key}) => EasyLocalization(
      key: key,
      supportedLocales: const [Locale('en')],
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      path: 'lib/l10n',
      assetLoader: const _TestAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: home,
        ),
      ),
    );

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
        'welcome': 'Welcome!',
        'chooseYourRole': 'Choose your role',
        'patient': 'Patient',
        'doctorsAndMedicines': 'Doctors and medicines',
        'doctor': 'Doctor',
        'managePatients': 'Manage patients',
        'laboratory': 'Laboratory',
        'uploadReports': 'Upload reports',
        'pharmacy': 'Pharmacy',
        'medicineOrders': 'Medicine orders',
        'welcomeBack': 'Welcome Back!',
        'loginAs': 'Login as {{role}}',
        'login': 'Login',
        'mobileNumber': 'Mobile number',
        'password': 'Password',
        'newHere': 'New here?',
        'signUp': 'Sign up',
      };
}

FilledButton _continueButton(WidgetTester tester) =>
    tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('I Agree & Continue'),
        matching: find.byType(FilledButton),
      ),
    );

Map<String, dynamic> _documentFor(String role, String documentType) => {
      'success': true,
      'role': role,
      'documentType': documentType,
      'title': role == 'patient'
          ? 'HealthHome Patient Terms'
          : 'HealthHome $role Terms',
      'version': '1.0.0',
      'content': List.generate(
        24,
        (index) =>
            '${index + 1}. ${role.toUpperCase()} Section ${index + 1}\n\n'
            '${'This role-specific agreement text is included for scroll and layout testing. ' * 5}',
      ).join('\n\n'),
      'contentHash': 'test-hash-$role',
      'businessDetails': {
        'effectiveDate': '[TO BE PROVIDED]',
        'legalName': '[Full legal name to be provided]',
        'businessAddress': '[Business address to be provided]',
        'supportEmail': '[Support email to be provided]',
        'grievanceOfficerName': '[Grievance officer name to be provided]',
        'grievanceOfficerContact': '[Grievance officer contact to be provided]',
      },
      'policyVersion': {
        'privacy': '[TO BE PROVIDED]',
        'refundCancellation': '[TO BE PROVIDED]',
      },
    };
