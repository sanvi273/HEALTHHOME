import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';

const _primary = Color(0xff18C5C5);
const _background = Color(0xffF5F7FB);
const _cardColor = Colors.white;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _checkingSession = true;
  bool _hasSession = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedInAccount();
  }

  Future<void> _loadSignedInAccount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasSession = (prefs.getString('token') ?? '').trim().isNotEmpty;
      _checkingSession = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidPassword(String value) =>
      value.length >= 6 &&
      value.length <= 128 &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);

  bool _isValidPhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '').length >= 8;

  Future<void> _updatePassword() async {
    if (!_hasSession) {
      setState(() => _error =
          'Sign in first, then change your password from your Profile.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.changePassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (response['success'] != true) {
        setState(() => _error = response['message']?.toString() ??
            'Unable to update your password. Please try again.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      for (final key in [
        'token',
        'userName',
        'userPhone',
        'userRole',
        'pharmacyPhone',
        'labPhone',
      ]) {
        await prefs.remove(key);
      }
      if (!mounted) return;
      setState(() => _completed = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff111827),
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
                elevation: 2,
                shadowColor: Colors.black12,
                color: _cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(color: Color(0xffE5E7EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: _completed
                      ? _successView()
                      : Form(
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
                                validator: (value) =>
                                    _isValidPhone(value ?? '')
                                        ? null
                                        : 'Enter a valid registered phone number.',
                              ),
                              const SizedBox(height: 16),
                              _field(
                                controller: _passwordController,
                                label: 'New Password',
                                icon: Icons.lock_outline,
                                obscureText: !_passwordVisible,
                                validator: (value) {
                                  final password = value ?? '';
                                  if (!_isValidPassword(password)) {
                                    return 'Use at least 6 characters with a letter and a number.';
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
                                validator: (value) =>
                                    value != _passwordController.text
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
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Color(0xffB42318)),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 58,
                                child: FilledButton(
                                  onPressed: _loading || _checkingSession
                                      ? null
                                      : _updatePassword,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                            child: _loading || _checkingSession
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
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
    bool readOnly = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xffF5F7FB),
        prefixIcon: Icon(icon, color: _primary),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _successView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline, color: _primary, size: 58),
          const SizedBox(height: 18),
          const Text(
            'Password Updated',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your password has been changed. Sign in again with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back to Login'),
          ),
        ],
      );
}
