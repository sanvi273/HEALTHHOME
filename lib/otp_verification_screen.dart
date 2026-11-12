import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'services/msg91_otp_bridge.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String challengeId;
  final String requestId;
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.challengeId,
    required this.requestId,
    this.purpose = 'login',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;
  int secondsRemaining = 30;
  int resendCount = 0;
  Timer? timer;
  String? error;

  @override
  void initState() {
    super.initState();
    Msg91OtpBridge.initialize(widget.phone);
    _startCountdown();
  }

  void _startCountdown() {
    timer?.cancel();
    setState(() => secondsRemaining = 30);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (secondsRemaining <= 1) {
        t.cancel();
        setState(() => secondsRemaining = 0);
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => error = 'Enter the six-digit code.');
      return;
    }
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      String? accessToken;
      if (Msg91OtpBridge.configured) {
        final widgetResponse =
            await Msg91OtpBridge.verify(widget.requestId, otp);
        if (!mounted) return;
        if (widgetResponse == null || widgetResponse['type'] != 'success') {
          setState(() => error = 'The code is invalid or expired.');
          return;
        }
        accessToken = (widgetResponse['access-token'] ??
                widgetResponse['accessToken'] ??
                widgetResponse['token'])
            ?.toString();
      }
      final response = widget.purpose == 'register'
          ? await ApiService.verifyRegistrationOtp(
              challengeId: widget.challengeId,
              otp: otp,
              accessToken: accessToken,
            )
          : widget.purpose == 'reset'
              ? await ApiService.verifyPasswordResetOtp(
                  challengeId: widget.challengeId,
                  otp: otp,
                  accessToken: accessToken,
                )
              : await ApiService.verifyLoginOtp(
                  challengeId: widget.challengeId,
                  otp: otp,
                  accessToken: accessToken,
                );
      if (!mounted) return;
      if (response['success'] == true) {
        if (mounted) Navigator.pop(context, response);
      } else if (mounted) {
        setState(() => error =
            response['message']?.toString() ?? 'Unable to verify code.');
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Network or verification error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resendOtp() async {
    if (secondsRemaining > 0 || resendCount >= 2 || isLoading) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await ApiService.resendLoginOtp(
        challengeId: widget.challengeId,
        purpose: widget.purpose,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        resendCount++;
        _startCountdown();
      } else if (mounted) {
        setState(() => error =
            response['message']?.toString() ?? 'Unable to resend code.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xff111827),
          title: const Text('Verify OTP',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text('Enter OTP',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827))),
                const SizedBox(height: 12),
                Text('Enter the 6-digit OTP sent to\n${widget.phone}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 35),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6)
                  ],
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                  decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      filled: true,
                      fillColor: const Color(0xffF5F7FB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none)),
                  onSubmitted: (_) => verifyOtp(),
                ),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00C2CB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify OTP',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: secondsRemaining == 0 && resendCount < 2
                        ? resendOtp
                        : null,
                    child: Text(resendCount >= 2
                        ? 'Resend limit reached'
                        : secondsRemaining > 0
                            ? 'Resend code in ${secondsRemaining}s'
                            : 'Resend code (${2 - resendCount} left)'),
                  ),
                ),
                Center(
                    child: TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Change mobile number'))),
              ],
            ),
          ),
        ),
      );
}
