import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/themes.dart';
import 'package:securescan/widgets/bottom_nav_shell.dart';

class InitialPermissionsScreen extends StatefulWidget {
  const InitialPermissionsScreen({super.key});

  @override
  State<InitialPermissionsScreen> createState() => _InitialPermissionsScreenState();
}

class _InitialPermissionsScreenState extends State<InitialPermissionsScreen> with WidgetsBindingObserver {
  bool _cameraGranted = false;
  bool _galleryGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    
    bool gallery = false;
    if (Platform.isAndroid) {
      final photos = await Permission.photos.status;
      final storage = await Permission.storage.status;
      gallery = photos.isGranted || storage.isGranted;
    } else {
      gallery = (await Permission.photos.status).isGranted;
    }

    if (mounted) {
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _galleryGranted = gallery;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    if (permission == Permission.photos && Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    } else {
      await permission.request();
    }
    _checkPermissions();
  }

  Future<void> _onContinue() async {
    // Only allow continue if camera is granted, as it's the core feature
    if (_cameraGranted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavShell()),
        );
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.permissionCameraDesc)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.permissionsTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "To provide you with the best experience, we need access to your camera and gallery.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              _buildPermissionItem(
                icon: Icons.camera_alt_rounded,
                title: l10n.permissionCamera,
                description: l10n.permissionCameraDesc,
                isGranted: _cameraGranted,
                onTap: () => _requestPermission(Permission.camera),
              ),
              const SizedBox(height: 24),
              _buildPermissionItem(
                icon: Icons.photo_library_rounded,
                title: l10n.permissionGallery,
                description: l10n.permissionGalleryDesc,
                isGranted: _galleryGranted,
                onTap: () => _requestPermission(Permission.photos),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cameraGranted ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SecureScanTheme.accentBlue,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.getStarted.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_cameraGranted)
                Center(
                  child: Text(
                    l10n.cameraPermissionRequired,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isGranted ? SecureScanTheme.accentBlue.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGranted ? SecureScanTheme.accentBlue : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted ? SecureScanTheme.accentBlue : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                   if (!isGranted)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.white : SecureScanTheme.accentBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isGranted)
              const Icon(Icons.check_circle, color: SecureScanTheme.accentBlue, size: 28)
            else
              const Icon(Icons.add_circle_outline, color: SecureScanTheme.accentBlue, size: 28),
          ],
        ),
      ),
    );
  }
}
