import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'services/api_service.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  final String selectedRole;
  final String roleLabel;

  const TermsAcceptanceScreen({
    super.key,
    required this.selectedRole,
    required this.roleLabel,
  });

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _document;
  bool _loading = true;
  bool _submitting = false;
  bool _readToEnd = false;
  bool _agreed = false;
  String? _error;

  static const Map<String, String> _documentTypes = {
    'patient': 'patient_individual',
    'doctor': 'doctor_partner',
    'laboratory': 'laboratory_partner',
    'pharmacy': 'pharmacy_partner',
  };

  String get _tokenKey => 'termsAcceptanceToken_${widget.selectedRole}';
  String get _versionKey => 'termsAcceptanceVersion_${widget.selectedRole}';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTerms();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _readToEnd) return;
    final position = _scrollController.position;
    if (position.pixels + 24 >= position.maxScrollExtent) {
      setState(() => _readToEnd = true);
    }
  }

  Future<void> _loadTerms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final document = await ApiService.getCurrentTerms(widget.selectedRole);
      if (!mounted) return;
      if (document['success'] != true ||
          document['role']?.toString() != widget.selectedRole ||
          document['documentType']?.toString() !=
              _documentTypes[widget.selectedRole] ||
          (document['title']?.toString().trim().isEmpty ?? true) ||
          (document['version']?.toString().trim().isEmpty ?? true) ||
          document['content'] is! String ||
          (document['content'] as String?)?.trim().isEmpty != false ||
          (document['contentHash']?.toString().trim().isEmpty ?? true)) {
        throw Exception('The terms document is unavailable. Please try again.');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final savedVersion = prefs.getString(_versionKey);
      if (token != null &&
          token.isNotEmpty &&
          savedVersion == document['version']?.toString()) {
        final validation = await ApiService.validateTermsAcceptance(
          selectedRole: widget.selectedRole,
          acceptanceToken: token,
        );
        if (!mounted) return;
        if (validation['accepted'] == true &&
            validation['termsVersion']?.toString() ==
                document['version']?.toString()) {
          _continueToLogin();
          return;
        }
      }

      setState(() {
        _document = document;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not load the current terms. Check your connection and retry.';
      });
    }
  }

  Future<void> _acceptAndContinue() async {
    final document = _document;
    if (document == null || !_readToEnd || !_agreed || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ApiService.acceptTerms(
        selectedRole: widget.selectedRole,
        termsDocumentType: document['documentType'].toString(),
        termsVersion: document['version'].toString(),
        termsContentHash: document['contentHash'].toString(),
      );
      if (!mounted) return;
      final token = response['acceptanceToken']?.toString() ?? '';
      if (response['success'] != true || token.isEmpty) {
        setState(() {
          _error = response['message']?.toString() ??
              'Unable to save your acceptance. Please try again.';
        });
        return;
      }
      if (response['role']?.toString() != widget.selectedRole ||
          response['termsVersion']?.toString() !=
              document['version']?.toString()) {
        setState(() {
          _error =
              'The server confirmed a different terms version. Reload and review the current document.';
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_versionKey, document['version'].toString());
      if (!mounted) return;
      _continueToLogin();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Unable to save your acceptance. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _continueToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(role: widget.roleLabel),
      ),
    );
  }

  List<Widget> _documentParagraphs(String content) {
    final widgets = <Widget>[];
    final colors = Theme.of(context).colorScheme;
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(line,
              style: TextStyle(
                  fontSize: 17,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface)),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 8),
                child: Text('•', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: Text(line.substring(2),
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Text(line,
            style: TextStyle(
                fontSize: 15, height: 1.55, color: colors.onSurface)));
      }
    }
    return widgets;
  }

  Widget _detailsCard(Map<String, dynamic> document) {
    final colors = Theme.of(context).colorScheme;
    final details = Map<String, dynamic>.from(
        (document['businessDetails'] as Map?) ?? const {});
    final policies = Map<String, dynamic>.from(
        (document['policyVersion'] as Map?) ?? const {});
    final rows = <String, String>{
      'Effective date':
          details['effectiveDate']?.toString() ?? '[TO BE PROVIDED]',
      'Operator': details['legalName']?.toString() ?? '[TO BE PROVIDED]',
      'Business address':
          details['businessAddress']?.toString() ?? '[TO BE PROVIDED]',
      'Support email':
          details['supportEmail']?.toString() ?? '[TO BE PROVIDED]',
      'Grievance officer':
          details['grievanceOfficerName']?.toString() ?? '[TO BE PROVIDED]',
      'Grievance contact':
          details['grievanceOfficerContact']?.toString() ?? '[TO BE PROVIDED]',
      'Privacy policy version':
          policies['privacy']?.toString() ?? '[TO BE PROVIDED]',
      'Refund & cancellation policy version':
          policies['refundCancellation']?.toString() ?? '[TO BE PROVIDED]',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text('${entry.key}: ${entry.value}',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: colors.onSurfaceVariant)),
                ))
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: const Text('Terms & Conditions'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff00C2CB)))
          : _error != null && document == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadTerms,
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff00C2CB)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 850),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(document?['title']?.toString() ?? '',
                                    style: TextStyle(
                                        fontSize: 26,
                                        height: 1.2,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onSurface)),
                                const SizedBox(height: 10),
                                Text(
                                    'For ${widget.roleLabel} · Version ${document?['version'] ?? ''}',
                                    style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 14)),
                                const SizedBox(height: 18),
                                if (document != null) _detailsCard(document),
                                ..._documentParagraphs(
                                    document?['content']?.toString() ?? ''),
                                const SizedBox(height: 16),
                                if (!_readToEnd)
                                  Text(
                                      'Scroll to the end to enable acceptance.',
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, -3)),
                          ],
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 850),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: const Color(0xff00C2CB),
                                  value: _agreed,
                                  onChanged: _readToEnd
                                      ? (value) => setState(
                                          () => _agreed = value ?? false)
                                      : null,
                                  title: const Text(
                                      'I have read and agree to the Terms & Conditions.'),
                                ),
                                if (_error != null && document != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(_error!,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    onPressed:
                                        _readToEnd && _agreed && !_submitting
                                            ? _acceptAndContinue
                                            : null,
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff00C2CB)),
                                    child: _submitting
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Text('I Agree & Continue'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
