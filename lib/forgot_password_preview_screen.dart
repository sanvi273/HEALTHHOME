import 'package:flutter/material.dart';

const _primary = Color(0xff4CAF50);
const _background = Color(0xffE8F5E9);
const _cardColor = Color(0xffF8F3F9);

/// UI preview for the requested forgot-password design.
/// It intentionally does not call a password-reset API.
class ForgotPasswordPreviewScreen extends StatefulWidget {
  const ForgotPasswordPreviewScreen({super.key});

  @override
  State<ForgotPasswordPreviewScreen> createState() =>
      _ForgotPasswordPreviewScreenState();
}

class _ForgotPasswordPreviewScreenState
    extends State<ForgotPasswordPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitPreview() async {
    if (!_formKey.currentState!.validate()) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password not changed'),
        content: const Text(
          'This is a visual preview only. To change your real password, '
          'sign in and open Profile > Change Password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 5,
                shadowColor: Colors.black26,
                color: _cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_reset,
                            color: _primary, size: 76),
                        const SizedBox(height: 16),
                        const Text(
                          'Reset Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enter your registered phone number and create a new password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, height: 1.45),
                        ),
                        const SizedBox(height: 24),
                        _field(
                          controller: _phoneController,
                          label: 'Registered Phone Number',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final digits = (value ?? '').replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
                            return digits.length < 8
                                ? 'Enter a valid phone number.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _passwordController,
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          obscureText: !_passwordVisible,
                          validator: (value) {
                            final password = value ?? '';
                            if (password.length < 8 ||
                                !RegExp(r'[A-Za-z]').hasMatch(password) ||
                                !RegExp(r'\d').hasMatch(password)) {
                              return 'Use 8+ characters with a letter and a number.';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            tooltip: _passwordVisible
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            icon: Icon(_passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _confirmController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: !_confirmVisible,
                          validator: (value) => value != _passwordController.text
                              ? 'Passwords do not match.'
                              : null,
                          suffixIcon: IconButton(
                            tooltip: _confirmVisible
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () => setState(
                              () => _confirmVisible = !_confirmVisible,
                            ),
                            icon: Icon(_confirmVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _submitPreview,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff59545E)),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xff817A84)),
        ),
      ),
    );
  }
}
