import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhome/forgot_password_flow.dart';
import 'package:healthhome/forgot_password_screen.dart';
import 'package:healthhome/reset_password_screen.dart';
import 'package:healthhome/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('password reset role and input rules', () {
    test('enables only patient, doctor, laboratory, and pharmacy', () {
      for (final role in passwordResetRoles) {
        expect(passwordResetRole(role.toUpperCase()), role);
      }
      expect(passwordResetRole('admin'), isNull);
      expect(passwordResetRole('unknown'), isNull);
    });

    test('uses the login mobile validation and reset password policy', () {
      expect(isValidPasswordResetPhone('9876543210'), isTrue);
      expect(isValidPasswordResetPhone('+91 98765-43210'), isTrue);
      expect(isValidPasswordResetPhone('123'), isFalse);
      expect(isValidResetPassword('StrongPass1'), isTrue);
      expect(isValidResetPassword('12345678'), isFalse);
      expect(isValidResetPassword('lettersOnly'), isFalse);
      expect(isValidResetPassword('a1'), isFalse);
    });

    test(
        'accepts a role-bound app reset link and rejects admin or malformed links',
        () {
      final valid = PasswordResetDeepLink.parse(
        Uri.parse('healthhome://reset-password?token=${'a' * 43}&role=doctor'),
      );
      expect(valid?.role, 'doctor');
      expect(valid?.isLogin, isFalse);
      expect(valid?.token, 'a' * 43);

      final login = PasswordResetDeepLink.parse(
        Uri.parse('healthhome://login?role=pharmacy'),
      );
      expect(login?.role, 'pharmacy');
      expect(login?.isLogin, isTrue);

      expect(
        PasswordResetDeepLink.parse(
          Uri.parse('healthhome://reset-password?token=${'a' * 43}&role=admin'),
        ),
        isNull,
      );
      expect(
        PasswordResetDeepLink.parse(
          Uri.parse('healthhome://reset-password?token=short&role=patient'),
        ),
        isNull,
      );
    });
  });

  testWidgets(
      'forgot-password sends only phone and selected role, then explains the SMS link',
      (tester) async {
    final originalClient = ApiService.passwordResetClient;
    http.Request? capturedRequest;
    ApiService.passwordResetClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'message':
              'If an account matches those details, a password reset link will be sent by SMS.',
        }),
        200,
      );
    });
    addTearDown(() {
      ApiService.passwordResetClient.close();
      ApiService.passwordResetClient = originalClient;
    });

    await tester.pumpWidget(
      const MaterialApp(home: ForgotPasswordScreen(role: 'Laboratory')),
    );
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(capturedRequest?.url.path, '/api/auth/forgot-password');
    final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
    expect(body, {'phone': '9876543210', 'role': 'laboratory'});
    expect(body.containsKey('otp'), isFalse);
    expect(
        find.textContaining('reset link will be sent by SMS'), findsOneWidget);
    expect(
        find.text(
            'Open the link from your registered phone number to choose a new password. The link expires after 15 minutes.'),
        findsOneWidget);
  });

  testWidgets(
      'reset screen rejects empty and mismatched passwords without submitting',
      (tester) async {
    var requests = 0;
    final originalClient = ApiService.passwordResetClient;
    ApiService.passwordResetClient = MockClient((request) async {
      requests += 1;
      return http.Response('{"success":true}', 200);
    });
    addTearDown(() {
      ApiService.passwordResetClient.close();
      ApiService.passwordResetClient = originalClient;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(role: 'Doctor', resetToken: 'a' * 43),
      ),
    );
    await tester.tap(find.text('Update Password'));
    await tester.pump();
    expect(find.text('Enter and confirm your new password.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'StrongPass1');
    await tester.enterText(find.byType(TextField).at(1), 'DifferentPass1');
    await tester.tap(find.text('Update Password'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('password visibility controls and successful reset are available',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'token': 'old-session-token',
      'userPhone': '9876543210',
      'userRole': 'pharmacy',
    });
    final originalClient = ApiService.passwordResetClient;
    http.Request? capturedRequest;
    ApiService.passwordResetClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
          '{"success":true,"message":"Password updated successfully."}', 200);
    });
    addTearDown(() {
      ApiService.passwordResetClient.close();
      ApiService.passwordResetClient = originalClient;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          role: 'Pharmacy',
          resetToken: 'a' * 43,
        ),
      ),
    );
    expect(find.byTooltip('Show password'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'StrongPass1');
    await tester.enterText(find.byType(TextField).at(1), 'StrongPass1');
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    final request = capturedRequest!;
    expect(request.url.path, '/api/auth/reset-password');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['role'], 'pharmacy');
    expect(body['resetToken'], 'a' * 43);
    expect(body['password'], 'StrongPass1');
    expect(find.text('Password Updated Successfully'), findsOneWidget);
    expect(find.textContaining('You can now log in using your new password.'),
        findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('isLoggedIn'), isFalse);
    expect(preferences.getString('token'), isNull);
  });
}
