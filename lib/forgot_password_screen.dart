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

  Color get _primaryColor {
    switch (_role) {
      case 'doctor':
      case 'pharmacy':
        return const Color(0xff14B8A6);
      case 'laboratory':
        return const Color(0xff20C6D3);
      case 'patient':
      default:
        return const Color(0xff00C2CB);
    }
  }

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
      backgroundColor: const Color(0xffEAF7ED),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 5,
                shadowColor: Colors.black26,
                color: const Color(0xffF8F3F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26),
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
          Icon(Icons.lock_reset, color: _primaryColor, size: 76),
          const SizedBox(height: 16),
          const Text(
            'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your registered phone number to receive a secure reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            onSubmitted: (_) => _loading ? null : _continue(),
            decoration: InputDecoration(
              labelText: 'Registered Phone Number',
              prefixIcon: const Icon(Icons.phone_android),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 18,
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xff817A84)),
              ),
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
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
        ],
      );

  Widget _sentView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.link, color: _primaryColor, size: 56),
          const SizedBox(height: 16),
          Text(
            'If an account matches those details, a secure reset link will be sent by SMS.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Open the link from your registered phone to choose a new password. The link expires after 15 minutes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      );
}
