import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color primary = Color(0xFF00AEB8);
  static const Color background = Color(0xFFF4F8FA);
  static const Color ink = Color(0xFF18343B);

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String _selectedFilter = 'Pending';
  String? _loadError;
  List<dynamic> _applications = [];

  static const List<String> _filters = [
    'Pending',
    'Approved',
    'Rejected',
    'All',
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }
    return token;
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final token = await _requireToken();

      // The All endpoint is required so every status filter has real data.
      final dynamic response =
          await ApiService.getAllVerifications(token: token);

      List<dynamic> records = [];
      if (response is List) {
        records = List<dynamic>.from(response);
      } else if (response is Map) {
        final dynamic data = response['verifications'] ??
            response['applications'] ??
            response['data'];
        if (data is List) {
          records = List<dynamic>.from(data);
        } else if (data is Map && data['verifications'] is List) {
          records = List<dynamic>.from(data['verifications']);
        }
      }

      if (!mounted) return;
      setState(() {
        _applications = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  String _value(dynamic item, List<String> keys,
      {String fallback = 'Not provided'}) {
    if (item is! Map) return fallback;
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  String _nestedValue(dynamic item, String parent, List<String> keys) {
    if (item is! Map) return 'Not provided';
    final nested = item[parent];
    if (nested is Map) {
      for (final key in keys) {
        final value = nested[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return 'Not provided';
  }

  // Approval/rejection endpoints expect the MongoDB Verification document _id.
  // Do not fall back to verificationId because it is a separate business ID.
  String _id(dynamic item) =>
      _value(item, ['_id', 'id'], fallback: '');

  String _status(dynamic item) =>
      _value(item, ['status', 'verificationStatus'], fallback: 'PENDING')
          .toUpperCase()
          .replaceAll(' ', '_');

  bool _isPending(dynamic item) {
    final status = _status(item);
    return status == 'PENDING' ||
        status == 'UNDER_REVIEW' ||
        status == 'SUBMITTED';
  }

  int get _pendingCount => _applications.where(_isPending).length;
  int get _approvedCount =>
      _applications.where((e) => _status(e) == 'APPROVED').length;
  int get _rejectedCount =>
      _applications.where((e) => _status(e) == 'REJECTED').length;

  List<dynamic> get _filteredApplications {
    Iterable<dynamic> result = _applications;
    if (_selectedFilter == 'Pending') {
      result = result.where(_isPending);
    } else if (_selectedFilter == 'Approved') {
      result = result.where((e) => _status(e) == 'APPROVED');
    } else if (_selectedFilter == 'Rejected') {
      result = result.where((e) => _status(e) == 'REJECTED');
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) {
        final name = _value(
          item,
          ['professionalName', 'name', 'fullName'],
        );
        final phone = _nestedValue(
          item,
          'userId',
          ['phone', 'phoneNumber', 'mobile'],
        );
        final email = _nestedValue(item, 'userId', ['email']);
        final organization = _value(item, ['organizationName']);
        return '$name $phone $email $organization'
            .toLowerCase()
            .contains(query);
      });
    }
    return result.toList();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : ink,
        ),
      );
  }

  Future<void> _approve(dynamic item) async {
    final id = _id(item);
    if (id.isEmpty) {
      _message('Application ID is missing.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve application?'),
        content: const Text(
          'This professional account will be approved and can access the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      final token = await _requireToken();
      await ApiService.approveVerification(id: id, token: token);
      _message('Application approved successfully.');
      await _loadApplications();
    } catch (e) {
      _message('Approval failed: $e', error: true);
    }
  }



Future<void> _reject(dynamic item) async {
  final id = _id(item);

  if (id.isEmpty) {
    _message('Application ID is missing.', error: true);
    return;
  }

  String enteredReason = '';
  String? validationMessage;

  final reason = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Reject application'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please enter the reason for rejecting this application.',
                ),
                const SizedBox(height: 12),
                TextField(
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter rejection reason',
                    border: const OutlineInputBorder(),
                    errorText: validationMessage,
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) {
                    enteredReason = value;
                    if (validationMessage != null) {
                      setDialogState(() {
                        validationMessage = null;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  if (enteredReason.trim().isEmpty) {
                    setDialogState(() {
                      validationMessage =
                          'Please enter a rejection reason';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(
                    enteredReason.trim(),
                  );
                },
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || reason == null || reason.trim().isEmpty) {
    return;
  }

  try {
    final token = await _requireToken();

    await ApiService.rejectVerification(
      id: id,
      reason: reason.trim(),
      token: token,
    );

    if (!mounted) return;

    _message('Application rejected successfully.');

    await _loadApplications();
  } catch (e) {
    if (!mounted) return;

    _message('Rejection failed: $e', error: true);
  }
}


  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of HealthHome Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay logged in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isLoggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove authentication/session values without clearing app preferences
      // such as language or theme.
      await prefs.remove('token');
      await prefs.remove('isLoggedIn');
      await prefs.remove('role');
      await prefs.remove('userRole');
      await prefs.remove('user');
      await prefs.remove('userData');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _message('Unable to log out: $e', error: true);
    }
  }

  Future<bool> _handleBack() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave admin dashboard?'),
        content: const Text(
          'You will return to the previous screen. Your admin session will remain active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Color _statusColor(String status) {
    if (status == 'APPROVED') return const Color(0xFF168653);
    if (status == 'REJECTED') return const Color(0xFFC43D4B);
    return const Color(0xFFB7791F);
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFF1)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              color: ink,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filter) {
    final selected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: selected,
        onSelected: (_) => setState(() => _selectedFilter = filter),
        selectedColor: primary.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF007F87) : Colors.blueGrey.shade700,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? primary : const Color(0xFFE2EAED),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _message('This document does not have a valid web link.', error: true);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) _message('Could not open this document.', error: true);
  }

  List<dynamic> _documents(dynamic item) {
    if (item is! Map) return [];
    final docs = item['documents'] ?? item['uploadedDocuments'];
    if (docs is List) return docs;
    if (docs is Map) return docs.values.toList();
    return [];
  }

  String _documentLabel(dynamic document) {
    if (document is Map) {
      return _value(
        document,
        ['type', 'name', 'fileName', 'documentType', 'title'],
        fallback: 'Submitted document',
      );
    }
    return 'Submitted document';
  }

  String _documentUrl(dynamic document) {
    if (document is Map) {
      return _value(
        document,
        ['url', 'documentUrl', 'fileUrl', 'secure_url'],
        fallback: '',
      );
    }
    final value = document?.toString() ?? '';
    return value.startsWith('http') ? value : '';
  }

  void _showApplicationDetails(dynamic item) {
    final name = _value(item, ['professionalName', 'name', 'fullName']);
    final role = _value(
      item,
      ['role'],
      fallback: _nestedValue(item, 'userId', ['role']),
    );
    final phone = _nestedValue(
      item,
      'userId',
      ['phone', 'phoneNumber', 'mobile'],
    );
    final email = _nestedValue(item, 'userId', ['email']);
    final docs = _documents(item);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: const TextStyle(
                  color: ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(role.toUpperCase(),
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  )),
              const Divider(height: 28),
              _detailLine('Phone', phone),
              _detailLine('Email', email),
              _detailLine(
                'License number',
                _value(item, ['licenseNumber', 'registrationNumber']),
              ),
              _detailLine(
                'Organization',
                _value(item, ['organizationName', 'clinicName', 'labName']),
              ),
              _detailLine('Address', _value(item, ['address'])),
              _detailLine('Status', _status(item)),
              _detailLine(
                'Verification ID',
                _value(item, ['verificationId']),
              ),
              _detailLine(
                'Registration notes',
                _value(item, ['notes']),
              ),
              if (_status(item) == 'REJECTED')
                _detailLine(
                  'Rejection reason',
                  _value(item, ['rejectionReason']),
                ),
              const SizedBox(height: 16),
              const Text(
                'Submitted documents',
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Text(
                  'No documents attached to this application.',
                  style: TextStyle(color: Colors.blueGrey),
                )
              else
                ...docs.map((doc) {
                  final url = _documentUrl(doc);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F8F8),
                      child: Icon(Icons.description_outlined, color: primary),
                    ),
                    title: Text(_documentLabel(doc)),
                    subtitle: Text(
                      url.isEmpty ? 'Document link unavailable' : url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Open document',
                      onPressed: url.isEmpty ? null : () => _openDocument(url),
                      icon: const Icon(Icons.open_in_new, color: primary),
                    ),
                  );
                }),
              if (_isPending(item)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
onPressed: () {
  Navigator.of(sheetContext).pop();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _reject(item);
  });
},
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _approve(item);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationCard(dynamic item) {
    final name = _value(item, ['professionalName', 'name', 'fullName']);
    final role = _value(item, ['role'], fallback: 'Professional');
    final status = _status(item);
    final color = _statusColor(status);
    final phone = _nestedValue(
      item,
      'userId',
      ['phone', 'phoneNumber', 'mobile'],
    );
    final email = _nestedValue(item, 'userId', ['email']);
    final organization = _value(
      item,
      ['organizationName', 'clinicName', 'labName'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFF1)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _compactInfo(Icons.phone_outlined, phone),
          const SizedBox(height: 7),
          _compactInfo(Icons.email_outlined, email),
          const SizedBox(height: 7),
          _compactInfo(Icons.business_outlined, organization),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showApplicationDetails(item),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View details'),
                style: TextButton.styleFrom(foregroundColor: primary),
              ),
              const Spacer(),
              if (_isPending(item)) ...[
                
IconButton(
  tooltip: 'Reject',
  onPressed: () async {
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    await _reject(item);
  },
  icon: const Icon(Icons.close, color: Colors.red),
),

                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => _approve(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.blueGrey.shade300),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFF1)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey.shade200),
          const SizedBox(height: 12),
          Text(
            _loadError == null
                ? 'No $_selectedFilter applications'
                : 'Could not load applications',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _loadError == null
                ? 'Applications matching this filter will appear here.'
                : _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadApplications,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApplications;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _handleBack() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: ink),
            onPressed: () async {
              if (await _handleBack() && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HealthHome',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Text(
                'ADMIN CONTROL CENTER',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh applications',
              onPressed: _isLoading ? null : _loadApplications,
              icon: const Icon(Icons.refresh_rounded, color: ink),
            ),
            PopupMenuButton<String>(
              tooltip: 'Admin menu',
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 19),
                      SizedBox(width: 10),
                      Text('Log out'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: primary.withValues(alpha: 0.13),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: primary,
                    size: 21,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoggingOut
            ? const Center(child: CircularProgressIndicator(color: primary))
            : RefreshIndicator(
                onRefresh: _loadApplications,
                color: primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00AEB8), Color(0xFF087F8C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, Admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'Manage professional verification requests and keep HealthHome trusted.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    height: 1.4,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.17),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Overview',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      childAspectRatio: 1.10,
                      children: [
                        _statCard(
                          title: 'Total applications',
                          count: _applications.length,
                          icon: Icons.folder_copy_outlined,
                          color: const Color(0xFF2878B8),
                        ),
                        _statCard(
                          title: 'Pending review',
                          count: _pendingCount,
                          icon: Icons.pending_actions_outlined,
                          color: const Color(0xFFB7791F),
                        ),
                        _statCard(
                          title: 'Approved',
                          count: _approvedCount,
                          icon: Icons.verified_outlined,
                          color: const Color(0xFF168653),
                        ),
                        _statCard(
                          title: 'Rejected',
                          count: _rejectedCount,
                          icon: Icons.cancel_outlined,
                          color: const Color(0xFFC43D4B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Verification requests',
                            style: TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length} found',
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search name, phone or email',
                        prefixIcon: const Icon(Icons.search, color: primary),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5ECEF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5ECEF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map(_filterChip).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 45),
                        child: Center(
                          child: CircularProgressIndicator(color: primary),
                        ),
                      )
                    else if (_loadError != null || filtered.isEmpty)
                      _emptyState()
                    else
                      ...filtered.map(_applicationCard),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'HealthHome • Admin Portal',
                        style: TextStyle(
                          color: Colors.blueGrey.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
