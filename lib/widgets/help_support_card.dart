import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportCard extends StatelessWidget {
  const HelpSupportCard({super.key});

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openContactOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0x1F14B8A6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Color(0xff14B8A6),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help and Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to contact our support team',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
