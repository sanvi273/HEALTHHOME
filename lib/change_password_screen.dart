import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'services/api_service.dart';

const _passwordPrimary = Color(0xff18C5C5);
const _passwordBackground = Color(0xffF5F7FB);
const _passwordCard = Colors.white;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  bool _completed = false;
  String _role = '';
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
      _phoneController.text = prefs.getString('userPhone') ??
          prefs.getString('pharmacyPhone') ??
          prefs.getString('labPhone') ??
          '';
      _role = (prefs.getString('userRole') ?? '').trim().toLowerCase();
    });
  }

  bool _isValidPassword(String value) =>
      value.length >= 6 &&
      value.length <= 128 &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);

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
    if (!_isValidPassword(password)) {
      setState(() => _error =
          'Use at least 6 characters, including a letter and a number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.changePassword(password: password);
      if (!mounted) return;
      if (response['success'] != true) {
        setState(() => _error = response['message']?.toString() ??
            'Unable to update your password. Please try again.');
        return;
      }

      await _clearLocalSession();
      if (!mounted) return;
      setState(() => _completed = true);
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

  String _loginRole() {
    switch (_role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Doctor';
      case 'laboratory':
      case 'lab':
        return 'Laboratory';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return 'Patient';
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(role: _loginRole())),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _passwordBackground,
      appBar: AppBar(
        backgroundColor: _passwordPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Change Password'),
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
                color: _passwordCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26),
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
          const Icon(Icons.lock_reset, color: _passwordPrimary, size: 76),
          const SizedBox(height: 16),
          const Text(
            'Change Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Update the password for your signed-in HealthHome account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),
          _field(
            controller: _phoneController,
            label: 'Registered Phone Number',
            icon: Icons.phone_android,
            readOnly: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _field(
            controller: _passwordController,
            label: 'New Password',
            icon: Icons.lock_outline,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
              onPressed: () => setState(
                () => _passwordVisible = !_passwordVisible,
              ),
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            controller: _confirmController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: !_confirmVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loading ? null : _updatePassword(),
            suffixIcon: IconButton(
              tooltip: _confirmVisible ? 'Hide password' : 'Show password',
              onPressed: () => setState(
                () => _confirmVisible = !_confirmVisible,
              ),
              icon: Icon(
                _confirmVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Use at least 6 characters, including a letter and a number.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xffB42318))),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: _loading ? null : _updatePassword,
              style: FilledButton.styleFrom(
                backgroundColor: _passwordPrimary,
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
                  : const Text(
                      'Update Password',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff59545E)),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xff817A84)),
        ),
      ),
    );
  }

  Widget _successView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              color: _passwordPrimary, size: 58),
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
            onPressed: _backToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: _passwordPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back to Login'),
          ),
        ],
      );
}

class ChangePasswordEntry extends StatelessWidget {
  const ChangePasswordEntry({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE1ECE4)),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _passwordPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.lock_reset, color: _passwordPrimary),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Update your signed-in account password'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const ChangePasswordScreen(),
            ),
          );
        },
      ),
    );
  }
}
