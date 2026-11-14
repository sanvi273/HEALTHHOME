import 'package:flutter/material.dart';

import 'forgot_password_flow.dart';
import 'services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.role});

  final String role;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _requestSent = false;
  String? _error;

  String get _role => passwordResetRole(widget.role) ?? '';

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    if (!isValidPasswordResetPhone(phone)) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }
    if (_role.isEmpty) {
      setState(() => _error = 'Password reset is not available for this role.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.startPasswordReset(
        phone: phone,
        role: _role,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() => _requestSent = true);
      } else {
        setState(() => _error = response['message']?.toString() ??
            'Unable to process the request. Please try again.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6FBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xffF6FBFB),
        foregroundColor: const Color(0xff102A2D),
        elevation: 0,
        title: const Text('Forgot Password?'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xffDDEDEE)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _requestSent ? _sentView() : _requestView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _requestView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, color: Color(0xff00C2CB), size: 48),
          const SizedBox(height: 16),
          Text(
            'Enter your registered mobile number to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            onSubmitted: (_) => _loading ? null : _continue(),
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xffB42318))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _continue,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff00C2CB),
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      );

  Widget _sentView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: Color(0xff00C2CB), size: 48),
          const SizedBox(height: 16),
          Text(
            'If an account matches those details, a password reset link will be sent by SMS.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Open the link from your registered phone number to choose a new password. The link expires after 15 minutes.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      );
}
