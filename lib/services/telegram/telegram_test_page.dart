import 'package:flutter/material.dart';

import 'telegram_service.dart';

class TelegramTestPage extends StatefulWidget {
  const TelegramTestPage({
    super.key,
  });

  @override
  State<TelegramTestPage> createState() =>
      _TelegramTestPageState();
}

class _TelegramTestPageState
    extends State<TelegramTestPage> {
  final TelegramService telegramService =
      TelegramService.instance;

  String status = 'Not initialized';

  String authorizationState = '';

  @override
  void initState() {
    super.initState();

    _initializeTelegram();
  }

  Future<void> _initializeTelegram() async {
    if (!mounted) return;

    setState(() {
      status = 'Initializing TDLib...';
      authorizationState = '';
    });

    try {
      await telegramService.initialize();

      if (!mounted) return;

      setState(() {
        status =
            'TDLib client initialized successfully.\n\n'
            'Now check the Debug Console for the '
            'authorization state.';
      });
    } catch (e) {
      debugPrint(
        'TELEGRAM TEST ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        status =
            'TDLib initialization failed.\n\n$e';
      });
    }
  }

  @override
  void dispose() {
    telegramService.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Telegram TDLib Test',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'HealthHome Telegram',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'TDLib connection test',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffEAFBFC),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _initializeTelegram,
                icon: const Icon(
                  Icons.telegram,
                ),
                label: const Text(
                  'Initialize TDLib',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff00C2CB),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}