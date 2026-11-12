import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_verification_screen.dart';
import 'services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;
  String? resetToken;
  String? error;

  Future<void> sendCode() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      return setState(() => error = 'Enter your mobile number.');
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiService.startPasswordReset(phone: phone);
      if (!mounted) return;
      final challengeId = response['challengeId']?.toString() ?? '';
      final requestId = response['requestId']?.toString() ?? '';
      if (challengeId.isEmpty || requestId.isEmpty) {
        setState(() => error = response['message']?.toString() ??
            'If the account is eligible, a code will be sent.');
        return;
      }
      if (!mounted) return;
      final verified = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
                phone: phone,
                challengeId: challengeId,
                requestId: requestId,
                purpose: 'reset')),
      );
      if (!mounted || verified == null) return;
      if (verified['success'] == true && verified['resetToken'] is String) {
        setState(() => resetToken = verified['resetToken'].toString());
      } else {
        setState(() => error =
            verified['message']?.toString() ?? 'Unable to verify code.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> savePassword() async {
    final password = passwordController.text;
    if (password != confirmController.text) {
      return setState(() => error = 'Passwords do not match.');
    }
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return setState(() => error =
          'Use at least 8 characters, including a letter and a number.');
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiService.resetPassword(
          resetToken: resetToken!, password: password);
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Password reset successfully. Sign in with your new password.')));
        Navigator.pop(context);
      } else {
        setState(() => error =
            response['message']?.toString() ?? 'Unable to reset password.');
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xff111827),
            elevation: 0,
            title: const Text('Forgot password')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Text(
                  resetToken == null
                      ? 'Verify your mobile number'
                      : 'Choose a new password',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827))),
              const SizedBox(height: 12),
              if (resetToken == null) ...[
                const Text(
                    'We will send a verification code if an eligible account exists.'),
                const SizedBox(height: 24),
                TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[+0-9 ()-]'))
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: loading ? null : sendCode,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff00C2CB)),
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Send verification code')),
              ] else ...[
                const Text(
                    'Password must be at least 8 characters and include a letter and a number.'),
                const SizedBox(height: 24),
                TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'New password',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: loading ? null : savePassword,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff00C2CB)),
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Reset password')),
              ],
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(error!,
                        style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
      );
}
