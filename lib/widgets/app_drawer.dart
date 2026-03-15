// lib/widgets/app_drawer.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:securescan/widgets/bottom_nav_shell.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'package:securescan/features/scan/screens/scan_screen_qr.dart';
import 'package:securescan/features/generate/screens/generator_screen.dart';
import 'package:securescan/features/generate/screens/my_qr_screen.dart';
import 'package:securescan/features/scan/screens/qr_result_screen.dart';
import 'package:securescan/l10n/app_localizations.dart';
import 'package:securescan/themes.dart';
import 'package:securescan/features/scan/services/scanner_service.dart';
import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/core/models/history_item.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.currentBottomIndex = 0,
    this.onSelectBottomNavIndex,
  });
  
  final int currentBottomIndex;
  final ValueChanged<int>? onSelectBottomNavIndex;

  static const _primaryBlue = Color(0xFF0A66FF);
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.securescan.securescan';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width * 0.66;

    return Drawer(
      width: width,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/secure_scan_logo.png', width: 64, height: 64, errorBuilder: (_, __, ___) => Container(color: Colors.grey[300])),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(l10n.copyright, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 18))),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerTile(title: l10n.home, iconPath: 'assets/icons/bottom_nav_icons/home_inactive.png', iconTint: currentBottomIndex == 0 ? _primaryBlue : Colors.grey[700], onTap: () => _navigateToShell(context, 0)),
            _DrawerTile(title: l10n.scanQr, iconPath: 'assets/icons/misc/scan_qr_icon_white.png', iconTint: _primaryBlue, onTap: () => _navigateToScanner(context)),
            //_DrawerTile(title: l10n.scanImage, iconPath: 'assets/icons/misc/scan_image_icon.png', iconTint: _primaryBlue, onTap: () => _scanFromGallery(context)),
            _DrawerTile(title: l10n.createQr, iconPath: 'assets/icons/misc/create_qr_icon_white.png', iconTint: _primaryBlue, onTap: () => _navigateToCreate(context)),
            _DrawerTile(title: l10n.myQr, iconPath: 'assets/icons/misc/my_qr_icon.png', iconTint: _primaryBlue, onTap: () => _navigateToMyQr(context)),
            _DrawerTile(title: l10n.history, iconPath: 'assets/icons/misc/history_App Drawer_icon.png', iconTint: _primaryBlue, onTap: () => _navigateToShell(context, 1)),
            _DrawerTile(title: l10n.settingsTitle, iconPath: 'assets/icons/bottom_nav_icons/settings_inactive.png', iconTint: _primaryBlue, onTap: () => _navigateToShell(context, 2)),
            _DrawerTile(title: l10n.shareApp, iconPath: 'assets/icons/misc/share_icon.png', iconTint: _primaryBlue, onTap: () => Share.share(l10n.shareMessage(_playStoreUrl))),
            _DrawerTile(title: l10n.changeTheme, iconPath: 'assets/icons/misc/theme_icon.png', iconTint: _primaryBlue, onTap: () => _toggleTheme(context)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _navigateToShell(BuildContext context, int index) {
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavShell(initialIndex: index)));
  }

  void _navigateToScanner(BuildContext context) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name == "ScanScreenQR") return;
    Navigator.pushReplacement(context, MaterialPageRoute(settings: const RouteSettings(name: "ScanScreenQR"), builder: (_) => const ScanScreenQR()));
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateQRScreen()));
  }

  void _navigateToMyQr(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyQrScreen()));
  }

  Future<void> _scanFromGallery(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop(); // Pop the drawer immediately

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Use the overlay context or check mounted to avoid using invalidated drawer context
    if (!context.mounted) return;

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final historyItem = await ScannerService.scanImage(image.path);
      
      if (!navigator.context.mounted) return;
      navigator.pop(); // dismiss loading

      if (historyItem != null) {
        // Add image bytes for immediate display
        final bytes = await File(image.path).readAsBytes();
        
        // Finalize and save to repo with image data
        final finalizedItem = await ScannerService.saveToHistory(
          raw: historyItem.value,
          type: historyItem.type,
          imageBytes: bytes,
          metadata: historyItem.metadata,
        );

        if (!navigator.context.mounted) return;
        navigator.push(MaterialPageRoute(builder: (_) => QrResultScreen(result: finalizedItem)));
      } else {
        if (!navigator.context.mounted) return;
        final l10n = AppLocalizations.of(navigator.context)!;
        showDialog(
          context: navigator.context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.scanDetail),
            content: Text(l10n.noCodeFound),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (navigator.context.mounted) {
        // Try to pop the loading dialog if it's still there
        try { navigator.pop(); } catch (_) {}
        ScaffoldMessenger.of(navigator.context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(navigator.context)!.failedToScan(e.toString()))));
      }
    }
  }

  Future<void> _toggleTheme(BuildContext context) async {
    Navigator.pop(context);
    final currentMode = SecureScanThemeController.instance.themeModeNotifier.value;
    ThemeMode newMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await SecureScanThemeController.instance.setTheme(SecureScanThemeController.themeModeToString(newMode));
  }
}

class _DrawerTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;
  final Color? iconTint;
  const _DrawerTile({required this.title, required this.iconPath, required this.onTap, this.iconTint});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(iconPath, width: 22, height: 22, color: iconTint),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
