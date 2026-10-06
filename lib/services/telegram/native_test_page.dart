import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeTestPage extends StatefulWidget {
  const NativeTestPage({super.key});

  @override
  State<NativeTestPage> createState() => _NativeTestPageState();
}

class _NativeTestPageState extends State<NativeTestPage> {
  static const MethodChannel _channel = MethodChannel('healthhome_tgcalls');

  String result = 'Not tested';

  Future<void> testNative() async {
    try {
      final response = await _channel.invokeMethod<String>('testNative');

      setState(() {
        result = response ?? 'No response';
      });
    } catch (e) {
      setState(() {
        result = 'ERROR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              result,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: testNative,
              child: const Text('TEST NATIVE BRIDGE'),
            ),
          ],
        ),
      ),
    );
  }
}