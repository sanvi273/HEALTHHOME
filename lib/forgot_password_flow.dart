const Set<String> passwordResetRoles = {
  'patient',
  'doctor',
  'laboratory',
  'pharmacy',
};

String? passwordResetRole(String value) {
  final role = value.trim().toLowerCase();
  return passwordResetRoles.contains(role) ? role : null;
}

String passwordResetRoleLabel(String role) {
  switch (passwordResetRole(role)) {
    case 'patient':
      return 'Patient';
    case 'doctor':
      return 'Doctor';
    case 'laboratory':
      return 'Laboratory';
    case 'pharmacy':
      return 'Pharmacy';
    default:
      return '';
  }
}

bool isValidPasswordResetPhone(String phone) {
  final value = phone.trim();
  final compact = value.replaceAll(RegExp(r'[\s()-]'), '');
  return RegExp(r'^[6-9]\d{9}$').hasMatch(value) ||
      RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(compact);
}

bool isValidResetPassword(String password) =>
    password.length >= 8 &&
    password.length <= 128 &&
    RegExp(r'[A-Za-z]').hasMatch(password) &&
    RegExp(r'\d').hasMatch(password);

class PasswordResetDeepLink {
  const PasswordResetDeepLink({
    required this.role,
    required this.isLogin,
    this.token,
  });

  final String role;
  final bool isLogin;
  final String? token;

  static PasswordResetDeepLink? parse(Uri? uri) {
    if (uri == null || uri.scheme != 'healthhome') return null;
    final role = passwordResetRole(uri.queryParameters['role'] ?? '');
    if (role == null) return null;

    if (uri.host == 'login') {
      return PasswordResetDeepLink(role: role, isLogin: true);
    }
    if (uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token == null || !RegExp(r'^[A-Za-z0-9_-]{40,64}$').hasMatch(token)) {
        return null;
      }
      return PasswordResetDeepLink(
        role: role,
        isLogin: false,
        token: token,
      );
    }
    return null;
  }
}
