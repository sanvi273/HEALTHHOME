import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class HealthHomeProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color backgroundColor;
  final Color iconColor;

  const HealthHomeProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.fallbackIcon,
    this.backgroundColor = const Color(0xffE8F7F5),
    this.iconColor = const Color(0xff14B8A6),
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? "";
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: url.isEmpty
          ? Icon(fallbackIcon, size: radius * 1.1, color: iconColor)
          : ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    size: radius * 1.1,
                    color: iconColor,
                  ),
                ),
              ),
            ),
    );
  }
}

class ProfileImageEditor extends StatefulWidget {
  final Color accentColor;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final String? initialImageUrl;

  const ProfileImageEditor({
    super.key,
    required this.accentColor,
    required this.fallbackIcon,
    this.backgroundColor = const Color(0xffE8F7F5),
    this.initialImageUrl,
  });

  @override
  State<ProfileImageEditor> createState() => _ProfileImageEditorState();
}

class _ProfileImageEditorState extends State<ProfileImageEditor> {
  static const int _maxBytes = 5 * 1024 * 1024;

  String _imageUrl = "";
  String _filename = "";
  Uint8List? _selectedBytes;
  bool _loadingProfile = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl?.trim() ?? "";
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      if (token.isEmpty) return;

      final response = await ApiService.getMyProfile(token: token);
      final profile = response["profile"];
      final image = profile is Map
          ? (profile["profileImageUrl"] ??
                  profile["profileImage"] ??
                  profile["photo"] ??
                  "")
              .toString()
              .trim()
          : "";

      if (mounted && image.isNotEmpty) {
        setState(() => _imageUrl = image);
      }
    } catch (error) {
      debugPrint("Unable to load saved profile photo: $error");
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (picked == null) return;

      final extension = picked.name.contains(".")
          ? picked.name.split(".").last.toLowerCase()
          : "";
      if (!["jpg", "jpeg", "png", "webp"].contains(extension)) {
        _showMessage("Choose a JPG, JPEG, PNG, or WEBP image.", isError: true);
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || !_hasSupportedImageSignature(bytes)) {
        _showMessage("The selected file is not a supported image.", isError: true);
        return;
      }
      if (bytes.length > _maxBytes) {
        _showMessage("Profile photos must be 5 MB or smaller.", isError: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedBytes = bytes;
        _filename = picked.name;
      });
    } catch (error) {
      _showMessage("Unable to select that photo. Please try again.", isError: true);
      debugPrint("PROFILE IMAGE PICK ERROR: $error");
    }
  }

  bool _hasSupportedImageSignature(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return true;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return true;
    }
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == "RIFF" &&
        String.fromCharCodes(bytes.sublist(8, 12)) == "WEBP";
  }

  Future<void> _uploadSelectedImage() async {
    final bytes = _selectedBytes;
    if (bytes == null || _uploading) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      if (token.isEmpty) {
        throw Exception("Your sign-in session expired. Please sign in again.");
      }

      final response = await ApiService.uploadMyProfileImage(
        token: token,
        bytes: bytes,
        filename: _filename,
      );
      final profile = response["profile"];
      final imageUrl = (response["profileImageUrl"] ??
                  (profile is Map ? profile["profileImageUrl"] : null) ??
                  "")
              .toString()
              .trim();
      if (response["success"] != true || imageUrl.isEmpty) {
        throw Exception(response["message"] ?? "Photo upload failed.");
      }

      await prefs.setString("profileImageUrl", imageUrl);
      if (!mounted) return;
      setState(() {
        _imageUrl = imageUrl;
        _selectedBytes = null;
        _filename = "";
      });
      _showMessage("Profile photo uploaded successfully.");
    } catch (error) {
      _showMessage(error.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedBytes != null || _imageUrl.isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: widget.backgroundColor,
              child: _selectedBytes != null
                  ? ClipOval(
                      child: Image.memory(
                        _selectedBytes!,
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _imageUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _imageUrl,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              widget.fallbackIcon,
                              size: 58,
                              color: widget.accentColor,
                            ),
                          ),
                        )
                      : _loadingProfile
                          ? SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.accentColor,
                              ),
                            )
                          : Icon(
                              widget.fallbackIcon,
                              size: 58,
                              color: widget.accentColor,
                            ),
            ),
            Positioned(
              right: -2,
              bottom: 0,
              child: Material(
                color: widget.accentColor,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: hasImage ? "Change photo" : "Upload photo",
                  onPressed: _uploading ? null : _showImageSourceOptions,
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 19),
                  constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedBytes == null)
          TextButton.icon(
            onPressed: _uploading ? null : _showImageSourceOptions,
            icon: Icon(
              hasImage ? Icons.edit_outlined : Icons.add_a_photo_outlined,
              color: widget.accentColor,
            ),
            label: Text(
              hasImage ? "Change Photo" : "Upload Photo",
              style: TextStyle(color: widget.accentColor),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _uploading
                    ? null
                    : () => setState(() {
                          _selectedBytes = null;
                          _filename = "";
                        }),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _uploading ? null : _uploadSelectedImage,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                ),
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_uploading ? "Uploading" : "Confirm & Upload"),
              ),
            ],
          ),
      ],
    );
  }
}
