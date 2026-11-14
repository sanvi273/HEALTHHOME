import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forgot_password_flow.dart';
import 'login_screen.dart';
import 'services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.role,
    required this.resetToken,
  });

  final String role;
  final String resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _completed = false;
  String? _error;

  String get _role => passwordResetRole(widget.role) ?? '';

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    if (password.isEmpty || _confirmController.text.isEmpty) {
      setState(() => _error = 'Enter and confirm your new password.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!isValidResetPassword(password)) {
      setState(() => _error =
          'Use at least 8 characters, including a letter and a number.');
      return;
    }
    if (_role.isEmpty) {
      setState(() => _error = 'This reset link is invalid.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.completePasswordReset(
        resetToken: widget.resetToken,
        role: _role,
        password: password,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        await _clearLocalSession();
        if (!mounted) return;
        setState(() => _completed = true);
      } else {
        setState(() => _error = response['message']?.toString() ??
            'Unable to update password. Please request a new link.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userPhone');
    await prefs.remove('userRole');
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(role: passwordResetRoleLabel(_role)),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
        title: const Text('Reset Password'),
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
                  child: _completed ? _successView() : _passwordForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, color: Color(0xff00C2CB), size: 48),
          const SizedBox(height: 16),
          Text('New Password', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Use at least 8 characters, including a letter and a number.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New Password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                tooltip: _passwordVisible ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: !_confirmVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _loading ? null : _updatePassword(),
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                tooltip: _confirmVisible ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
                icon: Icon(
                    _confirmVisible ? Icons.visibility_off : Icons.visibility),
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
              onPressed: _loading ? null : _updatePassword,
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
                  : const Text('Update Password'),
            ),
          ),
        ],
      );

  Widget _successView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xff00A8A8), size: 54),
          const SizedBox(height: 16),
          Text(
            'Password Updated Successfully',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Your password has been changed successfully. You can now log in using your new password.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _backToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff00C2CB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Login'),
          ),
        ],
      );
}
