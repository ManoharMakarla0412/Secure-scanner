import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:securescan/l10n/app_localizations.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _statuses = {};

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
    // For gallery, we might need multiple permissions depending on Android version
    // But usually photos/storage is what we need.
    final galleryStatus = await Permission.photos.status;
    
    // On some android versions photos might not be enough, check storage too
    var storageStatus = await Permission.storage.status;

    if (mounted) {
      setState(() {
        _statuses = {
          Permission.camera: cameraStatus,
          Permission.photos: (galleryStatus.isGranted || storageStatus.isGranted) 
              ? PermissionStatus.granted 
              : galleryStatus,
        };
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.permissionsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPermissionTile(
            icon: Icons.camera_alt_outlined,
            title: l10n.permissionCamera,
            subtitle: l10n.permissionCameraDesc,
            status: _statuses[Permission.camera] ?? PermissionStatus.denied,
            onTap: () => _requestPermission(Permission.camera),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            icon: Icons.photo_library_outlined,
            title: l10n.permissionGallery,
            subtitle: l10n.permissionGalleryDesc,
            status: _statuses[Permission.photos] ?? PermissionStatus.denied,
            onTap: () => _requestPermission(Permission.photos),
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(l10n.openSettings),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isGranted = status.isGranted;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: isDark 
          ? [] 
          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGranted ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  isGranted ? l10n.statusGranted : l10n.statusDenied,
                  style: TextStyle(
                    color: isGranted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: onTap,
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
        ],
      ),
    );
  }
}
