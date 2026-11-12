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
          document['content'] is! String ||
          document['contentHash'] is! String) {
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
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(line,
              style: const TextStyle(
                  fontSize: 17,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff111827))),
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
                    style: const TextStyle(
                        fontSize: 15, height: 1.5, color: Color(0xff374151))),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Text(line,
            style: const TextStyle(
                fontSize: 15, height: 1.55, color: Color(0xff374151))));
      }
    }
    return widgets;
  }

  Widget _detailsCard(Map<String, dynamic> document) {
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
        color: const Color(0xffF2FBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffCDEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text('${entry.key}: ${entry.value}',
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xff374151))),
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
    return Scaffold(
      backgroundColor: const Color(0xffF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff111827),
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
                                    style: const TextStyle(
                                        fontSize: 26,
                                        height: 1.2,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff111827))),
                                const SizedBox(height: 10),
                                Text(
                                    'For ${widget.roleLabel} · Version ${document?['version'] ?? ''}',
                                    style: const TextStyle(
                                        color: Color(0xff6B7280),
                                        fontSize: 14)),
                                const SizedBox(height: 18),
                                if (document != null) _detailsCard(document),
                                ..._documentParagraphs(
                                    document?['content']?.toString() ?? ''),
                                const SizedBox(height: 16),
                                if (!_readToEnd)
                                  const Text(
                                      'Scroll to the end to enable acceptance.',
                                      style: TextStyle(
                                          color: Color(0xff6B7280),
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
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
