import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneOtpChallenge {
  const PhoneOtpChallenge({
    this.verificationId,
    this.resendToken,
    this.webConfirmation,
  });

  final String? verificationId;
  final int? resendToken;
  final ConfirmationResult? webConfirmation;

  bool get isWeb => webConfirmation != null;
}

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<PhoneOtpChallenge> sendCode(
    String e164Phone, {
    int? forceResendingToken,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    if (kIsWeb) {
      final confirmation = await _auth.signInWithPhoneNumber(e164Phone);
      return PhoneOtpChallenge(webConfirmation: confirmation);
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw FirebaseAuthException(
        code: 'phone-auth-unsupported-platform',
        message: 'Phone OTP is available in the mobile app and web browser.',
      );
    }

    final result = Completer<PhoneOtpChallenge>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) {
        onAutoVerified?.call(credential);
      },
      verificationFailed: (error) {
        if (!result.isCompleted) result.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!result.isCompleted) {
          result.complete(PhoneOtpChallenge(
            verificationId: verificationId,
            resendToken: resendToken,
          ));
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!result.isCompleted) {
          result.complete(PhoneOtpChallenge(verificationId: verificationId));
        }
      },
    );

    return result.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw FirebaseAuthException(
        code: 'otp-request-timeout',
        message: 'The OTP request timed out. Please try again.',
      ),
    );
  }

  static Future<UserCredential> confirmCode(
    PhoneOtpChallenge challenge,
    String smsCode,
  ) async {
    if (challenge.webConfirmation != null) {
      return challenge.webConfirmation!.confirm(smsCode);
    }

    final verificationId = challenge.verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Request a new OTP before verifying.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> signInAutomatically(
    PhoneAuthCredential credential,
  ) {
    return _auth.signInWithCredential(credential);
  }

  static Future<String> currentIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'phone-auth-session-missing',
        message: 'Verify your phone number before continuing.',
      );
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(
        code: 'phone-auth-token-missing',
        message: 'Could not create a verified phone session. Please try again.',
      );
    }
    return token;
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint('Firebase sign-out failed: $error');
    }
  }
}
