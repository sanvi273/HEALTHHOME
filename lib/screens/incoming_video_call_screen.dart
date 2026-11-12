import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/incoming_call_service.dart';
import '../services/telegram/AgoraVideoCallPage.dart';

class IncomingVideoCallScreen extends StatefulWidget {
  final String callId;
  final String appointmentId;
  final String doctorName;
  final String doctorImage;
  final VoidCallback onClosed;

  const IncomingVideoCallScreen(
      {super.key,
      required this.callId,
      required this.appointmentId,
      required this.doctorName,
      required this.doctorImage,
      required this.onClosed});

  @override
  State<IncomingVideoCallScreen> createState() =>
      _IncomingVideoCallScreenState();
}

class _IncomingVideoCallScreenState extends State<IncomingVideoCallScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _decline() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.declineVideoCall(widget.callId);
      await _dismiss();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.acceptVideoCall(widget.callId);
      if (!mounted) return;
      await IncomingCallService.cancelNotification(widget.callId);
      if (!mounted) return;
      widget.onClosed();
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => AgoraVideoCallPage(
                doctorName: widget.doctorName,
                patientName: 'Patient',
                appointmentId: widget.appointmentId,
                meetingId: 'healthhome-${widget.appointmentId}',
                isDoctor: false,
                callId: widget.callId,
              )));
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _dismiss() async {
    await IncomingCallService.cancelNotification(widget.callId);
    widget.onClosed();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff00C2CB),
        body: SafeArea(
            child: Center(
                child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('INCOMING VIDEO CONSULTATION',
                style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white24,
                backgroundImage: widget.doctorImage.isNotEmpty
                    ? NetworkImage(widget.doctorImage)
                    : null,
                child: widget.doctorImage.isEmpty
                    ? const Icon(Icons.medical_services,
                        color: Colors.white, size: 56)
                    : null),
            const SizedBox(height: 20),
            Text(widget.doctorName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const Text('is ready to consult with you',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white))),
            const SizedBox(height: 48),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _CallAction(
                  icon: Icons.call_end,
                  label: 'Decline',
                  color: Colors.red,
                  onPressed: _busy ? null : _decline),
              _CallAction(
                  icon: Icons.videocam,
                  label: 'Accept',
                  color: Colors.green,
                  onPressed: _busy ? null : _accept),
            ]),
            if (_busy)
              const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(color: Colors.white)),
          ]),
        ))),
      );
}

class _CallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const _CallAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onPressed});
  @override
  Widget build(BuildContext context) => Column(children: [
        FloatingActionButton.large(
            heroTag: label,
            backgroundColor: color,
            onPressed: onPressed,
            child: Icon(icon, color: Colors.white, size: 32)),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ]);
}
