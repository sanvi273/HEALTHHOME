import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({
    super.key,
    required this.role,
    required this.initialProfile,
    required this.onProfileUpdated,
  });

  final String role;
  final Map<String, dynamic> initialProfile;
  final Future<void> Function(Map<String, dynamic> profile)
      onProfileUpdated;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final updatedProfile = await Navigator.of(context)
            .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => EditProfileScreen(
              role: role,
              initialProfile: initialProfile,
            ),
          ),
        );
        if (updatedProfile != null) {
          await onProfileUpdated(updatedProfile);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff0D9488),
        side: const BorderSide(color: Color(0xff0D9488)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.role,
    required this.initialProfile,
  });

  final String role;
  final Map<String, dynamic> initialProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _accent = Color(0xff0D9488);
  final _formKey = GlobalKey<FormState>();
  late final List<_ProfileField> _fields;
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fields = _fieldsForRole(widget.role);
    for (final field in _fields) {
      _controllers[field.key] = TextEditingController(
        text: widget.initialProfile[field.key]?.toString() ?? '',
      );
    }
    _loadProfile();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<_ProfileField> _fieldsForRole(String role) {
    const common = _ProfileField(
      key: 'name',
      label: 'Full name',
      isRequired: true,
      keyboardType: TextInputType.name,
    );
    switch (role) {
      case 'patient':
        return [
          common,
          const _ProfileField(key: 'age', label: 'Age', keyboardType: TextInputType.number),
          const _ProfileField(key: 'gender', label: 'Gender', keyboardType: TextInputType.text),
          const _ProfileField(key: 'bloodGroup', label: 'Blood group', keyboardType: TextInputType.text),
          const _ProfileField(key: 'height', label: 'Height (cm)', keyboardType: TextInputType.numberWithOptions(decimal: true)),
          const _ProfileField(key: 'weight', label: 'Weight (kg)', keyboardType: TextInputType.numberWithOptions(decimal: true)),
        ];
      case 'doctor':
        return [
          common,
          const _ProfileField(key: 'specialization', label: 'Specialization', isRequired: true),
          const _ProfileField(key: 'experience', label: 'Experience', isRequired: true),
          const _ProfileField(key: 'fees', label: 'Consultation fees', isRequired: true, keyboardType: TextInputType.numberWithOptions(decimal: true)),
          const _ProfileField(key: 'hospital', label: 'Hospital / clinic', isRequired: true),
          const _ProfileField(key: 'about', label: 'About', maxLines: 4),
        ];
      case 'laboratory':
        return [
          common,
          const _ProfileField(key: 'labType', label: 'Laboratory type', isRequired: true),
          const _ProfileField(key: 'experience', label: 'Experience', isRequired: true),
          const _ProfileField(key: 'address', label: 'Address', isRequired: true, maxLines: 3),
        ];
      case 'pharmacy':
        return [
          common,
          const _ProfileField(key: 'shopType', label: 'Shop type', isRequired: true),
          const _ProfileField(key: 'experience', label: 'Experience', isRequired: true),
          const _ProfileField(key: 'address', label: 'Address', isRequired: true, maxLines: 3),
        ];
      default:
        return [common];
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.trim().isEmpty) {
        throw Exception('Your session has expired. Please sign in again.');
      }
      final response = await ApiService.getMyProfile(token: token);
      final rawProfile = response['profile'];
      if (rawProfile is! Map) {
        throw Exception('Your profile could not be loaded.');
      }
      _applyProfile(Map<String, dynamic>.from(rawProfile));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyProfile(Map<String, dynamic> profile) {
    for (final field in _fields) {
      final value = profile[field.key];
      if (value != null) {
        _controllers[field.key]!.text = value.toString();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{
        for (final field in _fields)
          field.key: _controllers[field.key]!.text.trim(),
      };
      final response = await ApiService.updateMyProfile(profile: updates);
      final rawProfile = response['profile'];
      if (rawProfile is! Map) {
        throw Exception('The updated profile was not returned by the server.');
      }
      final profile = Map<String, dynamic>.from(rawProfile);
      await _cacheProfile(profile);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cacheProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final name = profile['name']?.toString() ?? '';
    await prefs.setString('userName', name);
    switch (widget.role) {
      case 'patient':
        await prefs.setString('patientName', name);
        break;
      case 'doctor':
        await prefs.setString('doctorName', name);
        for (final key in const [
          'specialization',
          'experience',
          'fees',
          'hospital',
          'about',
        ]) {
          await prefs.setString('doctor${key[0].toUpperCase()}${key.substring(1)}', profile[key]?.toString() ?? '');
        }
        break;
      case 'laboratory':
        await prefs.setString('labName', name);
        break;
      case 'pharmacy':
        await prefs.setString('pharmacyName', name);
        break;
    }
  }

  String? _validateField(_ProfileField field, String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (field.isRequired && value.isEmpty) {
      return 'Please enter ${field.label.toLowerCase()}.';
    }
    if (field.key == 'age' && value.isNotEmpty) {
      final age = int.tryParse(value);
      if (age == null || age < 0 || age > 120) {
        return 'Enter an age from 0 to 120.';
      }
    }
    if ((field.key == 'height' || field.key == 'weight') && value.isNotEmpty) {
      final number = double.tryParse(value);
      if (number == null || number <= 0) {
        return 'Enter a valid ${field.label.toLowerCase()}.';
      }
    }
    return null;
  }

  String get _title {
    switch (widget.role) {
      case 'patient':
        return 'Edit patient profile';
      case 'doctor':
        return 'Edit doctor profile';
      case 'laboratory':
        return 'Edit laboratory profile';
      case 'pharmacy':
        return 'Edit pharmacy profile';
      default:
        return 'Edit profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_loadError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Could not refresh your saved profile. Review the values below before saving. $_loadError',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                  for (final field in _fields) ...[
                    TextFormField(
                      controller: _controllers[field.key],
                      keyboardType: field.keyboardType,
                      maxLines: field.maxLines,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) => _validateField(field, value),
                      decoration: InputDecoration(
                        labelText: field.label,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving…' : 'Save changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileField {
  const _ProfileField({
    required this.key,
    required this.label,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
}
