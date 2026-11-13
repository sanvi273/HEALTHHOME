import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportCard extends StatelessWidget {
  const HelpSupportCard({super.key, this.horizontalMargin = 0});

  final double horizontalMargin;

  static const _phoneNumbers = ['9313069960', '9313788070'];

  Future<void> _openContactOptions(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help and Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a number to call us:'),
            const SizedBox(height: 8),
            for (final phoneNumber in _phoneNumbers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.call_outlined,
                  color: Color(0xff14B8A6),
                ),
                title: Text(phoneNumber),
                onTap: () => _callNumber(
                  context,
                  dialogContext,
                  phoneNumber,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(
    BuildContext pageContext,
    BuildContext dialogContext,
    String phoneNumber,
  ) async {
    Navigator.of(dialogContext).pop();

    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: phoneNumber),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && pageContext.mounted) {
        _showCallError(pageContext);
      }
    } catch (_) {
      if (pageContext.mounted) _showCallError(pageContext);
    }
  }

  void _showCallError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the phone app.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        left: horizontalMargin,
        top: 8,
        right: horizontalMargin,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => _openContactOptions(context),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1F14B8A6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Color(0xff14B8A6),
            ),
          ),
          title: const Text(
            'Help and Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: const Text(
            'Tap to contact our support team',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
          ),
        ),
      ),
    );
  }
}
