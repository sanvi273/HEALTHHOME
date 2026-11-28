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

  // Log only Firebase error codes/messages. Never log ID tokens, verification
  // IDs, or phone numbers here.
  static void _logError(String phase, Object error) {
    if (error is FirebaseAuthException) {
      debugPrint(
        'PHONE AUTH $phase FAILED code=${error.code} message=${error.message}',
      );
      return;
    }
    debugPrint('PHONE AUTH $phase FAILED error=$error');
  }

  static Future<PhoneOtpChallenge> sendCode(
    String e164Phone, {
    int? forceResendingToken,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    if (kIsWeb) {
      try {
        final confirmation = await _auth.signInWithPhoneNumber(e164Phone);
        debugPrint('PHONE AUTH REQUEST/WEB SUCCEEDED');
        return PhoneOtpChallenge(webConfirmation: confirmation);
      } catch (error) {
        _logError('REQUEST/WEB', error);
        rethrow;
      }
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
        _logError('REQUEST/NATIVE', error);
        if (!result.isCompleted) result.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        debugPrint('PHONE AUTH REQUEST/NATIVE SUCCEEDED');
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
    try {
      if (challenge.webConfirmation != null) {
        final result = await challenge.webConfirmation!.confirm(smsCode);
        debugPrint('PHONE AUTH VERIFY/WEB SUCCEEDED');
        return result;
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
      final result = await _auth.signInWithCredential(credential);
      debugPrint('PHONE AUTH VERIFY/NATIVE SUCCEEDED');
      return result;
    } catch (error) {
      _logError('VERIFY', error);
      rethrow;
    }
  }

  static Future<UserCredential> signInAutomatically(
    PhoneAuthCredential credential,
  ) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      debugPrint('PHONE AUTH VERIFY/AUTO SUCCEEDED');
      return result;
    } catch (error) {
      _logError('VERIFY/AUTO', error);
      rethrow;
    }
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
