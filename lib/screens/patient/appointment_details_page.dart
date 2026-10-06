import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../services/api_service.dart';

class AgoraVideoCallPage extends StatefulWidget {
  final String doctorName;
  final String patientName;
  final String appointmentId;
  final String meetingId;
  final bool isDoctor;

  const AgoraVideoCallPage({
    super.key,
    required this.doctorName,
    required this.patientName,
    required this.appointmentId,
    required this.meetingId,
    required this.isDoctor,
  });

  @override
  State<AgoraVideoCallPage> createState() =>
      _AgoraVideoCallPageState();
}

class _AgoraVideoCallPageState
    extends State<AgoraVideoCallPage> {
  RtcEngine? _engine;

  bool loading = true;
  bool joined = false;
  bool microphoneEnabled = true;
  bool cameraEnabled = true;

  String status = "Preparing video consultation...";

  String? channelName;
  int? localUid;
  int? remoteUid;

  @override
  void initState() {
    super.initState();
    _startAgoraCall();
  }

  // ============================================================
  // CREATE UNIQUE UID
  // ============================================================

  int _buildAgoraUid(
    String appointmentId,
    bool isDoctor,
  ) {
    final clean =
        appointmentId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');

    int seed;

    if (clean.length >= 8) {
      seed = int.tryParse(
            clean.substring(clean.length - 8),
            radix: 16,
          ) ??
          DateTime.now().millisecondsSinceEpoch;
    } else {
      seed = DateTime.now().millisecondsSinceEpoch;
    }

    final base = seed % 100000000;

    return (base * 2) + (isDoctor ? 1 : 2);
  }

  // ============================================================
  // START AGORA CALL
  // ============================================================

  Future<void> _startAgoraCall() async {
    try {
      if (!mounted) return;

      setState(() {
        loading = true;
        status = "Getting secure video connection...";
      });

      // --------------------------------------------------------
      // 1. CREATE UID
      // --------------------------------------------------------

      final uid = _buildAgoraUid(
        widget.appointmentId,
        widget.isDoctor,
      );

      localUid = uid;

      debugPrint("=================================");
      debugPrint("AGORA VIDEO CONSULTATION");
      debugPrint("APPOINTMENT ID: ${widget.appointmentId}");
      debugPrint("UID: $uid");
      debugPrint("IS DOCTOR: ${widget.isDoctor}");
      debugPrint("=================================");

      // --------------------------------------------------------
      // 2. DOCTOR STARTS CONSULTATION
      // --------------------------------------------------------

      if (widget.isDoctor) {
        setState(() {
          status = "Starting consultation...";
        });

        final startResponse =
            await ApiService.startConsultation(
          widget.appointmentId,
        );

        debugPrint(
          "START CONSULTATION RESPONSE: $startResponse",
        );
      }

      // --------------------------------------------------------
      // 3. GET AGORA TOKEN FROM BACKEND
      // --------------------------------------------------------

      setState(() {
        status = "Generating secure Agora token...";
      });

      final tokenResponse =
          await ApiService.generateAgoraToken(
        appointmentId: widget.appointmentId,
        uid: uid,
      );

      debugPrint(
        "AGORA TOKEN RESPONSE: $tokenResponse",
      );

      if (tokenResponse["success"] != true) {
        throw Exception(
          tokenResponse["message"] ??
              "Unable to generate Agora token",
        );
      }

      final String appId =
          tokenResponse["appId"].toString();

      final String token =
          tokenResponse["token"].toString();

      final String backendChannel =
          tokenResponse["channelName"].toString();

      channelName = backendChannel;

      // --------------------------------------------------------
      // 4. INITIALIZE AGORA ENGINE
      // --------------------------------------------------------

      setState(() {
        status = "Initializing video...";
      });

      final engine = createAgoraRtcEngine();

      _engine = engine;

      await engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile:
              ChannelProfileType.channelProfileCommunication,
        ),
      );

      // --------------------------------------------------------
      // 5. REGISTER AGORA EVENTS
      // --------------------------------------------------------

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess:
              (RtcConnection connection, int elapsed) {
            debugPrint(
              "AGORA JOIN SUCCESS"
              " | CHANNEL: ${connection.channelId}"
              " | UID: ${connection.localUid}",
            );

            if (!mounted) return;

            setState(() {
              joined = true;
              loading = false;
              status = "Connected";
            });
          },

          onUserJoined:
              (
                RtcConnection connection,
                int remoteUidValue,
                int elapsed,
              ) {
            debugPrint(
              "REMOTE USER JOINED: $remoteUidValue",
            );

            if (!mounted) return;

            setState(() {
              remoteUid = remoteUidValue;
              status = "Doctor connected";
            });
          },

          onUserOffline:
              (
                RtcConnection connection,
                int remoteUidValue,
                UserOfflineReasonType reason,
              ) {
            debugPrint(
              "REMOTE USER LEFT: $remoteUidValue",
            );

            if (!mounted) return;

            setState(() {
              remoteUid = null;
              status = "Other participant left";
            });
          },

          onError:
              (ErrorCodeType err, String msg) {
            debugPrint(
              "AGORA ERROR: $err - $msg",
            );
          },
        ),
      );

      // --------------------------------------------------------
      // 6. ENABLE VIDEO
      // --------------------------------------------------------

      await engine.enableVideo();

      await engine.enableAudio();

      // --------------------------------------------------------
      // 7. START LOCAL CAMERA PREVIEW
      // --------------------------------------------------------

      await engine.startPreview();

      // --------------------------------------------------------
      // 8. JOIN AGORA CHANNEL
      // --------------------------------------------------------

      setState(() {
        status = "Joining consultation...";
      });

      await engine.joinChannel(
        token: token,
        channelId: backendChannel,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType:
              ClientRoleType.clientRoleBroadcaster,
          channelProfile:
              ChannelProfileType.channelProfileCommunication,
        ),
      );

      // --------------------------------------------------------
      // 9. MARK CONSULTATION AS JOINED
      // --------------------------------------------------------

      await ApiService.joinConsultation(
        widget.appointmentId,
      );

      debugPrint(
        "AGORA CHANNEL JOIN REQUEST SENT",
      );
    } catch (e) {
      debugPrint(
        "AGORA VIDEO CALL ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        status =
            "Unable to start video consultation.\n\n$e";
      });
    }
  }

  // ============================================================
  // MICROPHONE
  // ============================================================

  Future<void> _toggleMicrophone() async {
    final engine = _engine;

    if (engine == null) return;

    final newValue = !microphoneEnabled;

    await engine.muteLocalAudioStream(
      !newValue,
    );

    if (!mounted) return;

    setState(() {
      microphoneEnabled = newValue;
    });
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _toggleCamera() async {
    final engine = _engine;

    if (engine == null) return;

    final newValue = !cameraEnabled;

    await engine.muteLocalVideoStream(
      !newValue,
    );

    if (!mounted) return;

    setState(() {
      cameraEnabled = newValue;
    });
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<void> _endCall() async {
    try {
      final engine = _engine;

      if (engine != null) {
        await engine.leaveChannel();
        await engine.stopPreview();
        await engine.release();
      }

      _engine = null;

      // Complete consultation in backend
      await ApiService.completeConsultation(
        widget.appointmentId,
      );
    } catch (e) {
      debugPrint(
        "END AGORA CALL ERROR: $e",
      );
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ============================================================
  // LOCAL VIDEO
  // ============================================================

  Widget _buildLocalVideo() {
    final engine = _engine;

    if (engine == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00C2CB),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(
          uid: 0,
        ),
      ),
    );
  }

  // ============================================================
  // REMOTE VIDEO
  // ============================================================

  Widget _buildRemoteVideo() {
    final engine = _engine;

    if (engine == null || remoteUid == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 90,
                color: Colors.white54,
              ),
              const SizedBox(height: 20),
              Text(
                widget.isDoctor
                    ? "Waiting for patient..."
                    : "Waiting for doctor...",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller:
          VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(
          uid: remoteUid,
        ),
        connection: RtcConnection(
          channelId: channelName,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Video Consultation",
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          // ======================================================
          // REMOTE VIDEO
          // ======================================================

          Positioned.fill(
            child: _buildRemoteVideo(),
          ),

          // ======================================================
          // LOCAL VIDEO
          // ======================================================

          if (joined)
            Positioned(
              top: 20,
              right: 20,
              width: 120,
              height: 170,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey.shade900,
                  child: _buildLocalVideo(),
                ),
              ),
            ),

          // ======================================================
          // CONNECTION STATUS
          // ======================================================

          if (!joined)
            Positioned(
              left: 20,
              right: 20,
              top: 30,
              child: Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (loading)
                      const CircularProgressIndicator(
                        color: Color(0xff00C2CB),
                      ),

                    const SizedBox(height: 15),

                    Text(
                      status,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // PARTICIPANT NAME
          // ======================================================

          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: 0.55),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                widget.isDoctor
                    ? widget.patientName
                    : widget.doctorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          // ======================================================
          // BOTTOM CONTROLS
          // ======================================================

          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: 0.70),
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  // MICROPHONE
                  _controlButton(
                    icon: microphoneEnabled
                        ? Icons.mic
                        : Icons.mic_off,
                    onPressed:
                        _toggleMicrophone,
                  ),

                  // CAMERA
                  _controlButton(
                    icon: cameraEnabled
                        ? Icons.videocam
                        : Icons.videocam_off,
                    onPressed:
                        _toggleCamera,
                  ),

                  // END CALL
                  _controlButton(
                    icon: Icons.call_end,
                    backgroundColor:
                        Colors.red,
                    onPressed: _endCall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTROL BUTTON
  // ============================================================

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor ??
            Colors.white.withValues(
              alpha: 0.20,
            ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 27,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}