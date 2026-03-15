import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/core/models/history_item.dart';
import 'package:securescan/core/repositories/history_repository.dart';
import 'package:securescan/core/utils/date_helper.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:securescan/services/language_service.dart';
import 'package:securescan/widgets/banner_ad_widget.dart';

import 'package:securescan/l10n/app_localizations.dart';
import '../../../themes.dart';

import 'created_qr_modal_screen.dart';
import 'package:securescan/features/scan/screens/qr_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isScanSelected = true;
  final GlobalKey _qrGlobalKey = GlobalKey();

  List<HistoryItem> scannedItems = [];
  List<HistoryItem> createdItems = [];

  // Ad Unit IDs managed in AdManager

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    final results = await Future.wait([
      HistoryRepository.instance.getScanHistory(),
      HistoryRepository.instance.getCreatedHistory(),
    ]);

    setState(() {
      scannedItems = results[0];
      createdItems = results[1];
    });
  }

  // ---------- Helpers ----------

  String _labelForType(QrType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case QrType.url:
        return l10n.url;
      case QrType.phone:
        return l10n.phone;
      case QrType.email:
        return l10n.email;
      case QrType.wifi:
        return l10n.wifi;
      case QrType.contact:
        return l10n.contact;
      case QrType.calendar:
        return l10n.calendar;
      case QrType.location:
        return l10n.location;
      case QrType.json:
        return l10n.json;
      default:
        return l10n.content;
    }
  }


  String? _parseWifiSsid(String wifiPayload) {
    if (!wifiPayload.startsWith('WIFI:')) return null;
    final rest = wifiPayload.substring(5);
    final parts = rest.split(';');
    for (final p in parts) {
      if (p.startsWith('S:')) return p.substring(2);
    }
    return null;
  }

  Map<String, String> _parseMecard(String mecard) {
    final out = <String, String>{};
    if (!mecard.toUpperCase().startsWith('MECARD:')) return out;
    final rest = mecard.substring(7);
    final segs = rest.split(';');
    for (final seg in segs) {
      final idx = seg.indexOf(':');
      if (idx <= 0) continue;
      final k = seg.substring(0, idx).toUpperCase();
      final v = seg.substring(idx + 1);
      out[k] = v;
    }
    return {
      'name': out['N'] ?? '',
      'tel': out['TEL'] ?? '',
      'email': out['EMAIL'] ?? '',
    };
  }

  IconData _getIcon(QrType type) {
    switch (type) {
      case QrType.url:
        return FontAwesomeIcons.globe;
      case QrType.email:
        return FontAwesomeIcons.envelope;
      case QrType.contact:
        return FontAwesomeIcons.user;
      case QrType.phone:
        return FontAwesomeIcons.phone;
      case QrType.wifi:
        return FontAwesomeIcons.wifi;
      case QrType.calendar:
        return FontAwesomeIcons.calendarDays;
      case QrType.location:
        return FontAwesomeIcons.locationDot;
      case QrType.json:
        return FontAwesomeIcons.code;
      default:
        return Icons.info_outline;
    }
  }

  // Ad loading handled by BannerAdWidget

  @override
  void dispose() {
    super.dispose();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final List<HistoryItem> historyItems = isScanSelected
        ? scannedItems
        : createdItems;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.history,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ---------------- Drawer ----------------
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Toggle
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isScanSelected = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isScanSelected
                            ? SecureScanTheme.accentBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.scan,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isScanSelected
                              ? Colors.white
                              : colorScheme.onBackground.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isScanSelected = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isScanSelected
                            ? SecureScanTheme.accentBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.created,
                        style: textTheme.bodyMedium?.copyWith(
                          color: !isScanSelected
                              ? Colors.white
                              : colorScheme.onBackground.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllHistory,
              child: historyItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 160),
                        Center(
                          child: Text(
                            l10n.noHistoryFound,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: historyItems.length,
                      itemBuilder: (context, index) {
                        final item = historyItems[index];

                        // Always show 3-dots menu (Delete) for both Scan and Created tabs.
                        final trailingWidget = PopupMenuButton<String>(
                          color: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          onSelected: (value) async {
                            if (value == 'Delete') {
                              if (isScanSelected) {
                                await HistoryRepository.instance.deleteScanItem(item.id);
                              } else {
                                await HistoryRepository.instance.deleteCreatedItem(item.id);
                              }
                              _loadAllHistory();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'Delete',
                              child: Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );

                        return InkWell(
                          onTap: () => _onHistoryItemTap(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFBFBFBF),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Left
                                  Container(
                                    width: 80,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFF4F4F4),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getIcon(item.type),
                                          color: SecureScanTheme.accentBlue,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _labelForType(item.type),
                                          textAlign: TextAlign.center,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: SecureScanTheme.accentBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Right
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayValue ?? item.value,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          DateHelper.formatHistoryDate(item.timestamp),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // trailing
                                const SizedBox(width: 8),
                                trailingWidget,
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          const BannerAdWidget(),
        ],
      ),
    );
  }

  void _onHistoryItemTap(HistoryItem item) async {
    if (!item.isCreated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrResultScreen(result: item),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatedQrModalScreen(
            type: item.type.name,
            value: item.value,
            time: DateHelper.formatCreatedDate(item.timestamp),
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  // ----------- Dialog -----------

  void _showQrPreviewDialog(QrType type, String value, String time) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(_getIcon(type), color: SecureScanTheme.accentBlue, size: 22),
              const SizedBox(width: 10),
              Text(
                _labelForType(type),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                RepaintBoundary(
                  key: _qrGlobalKey,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: SecureScanTheme.accentBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.yourQrCode,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: value,
                            version: QrVersions.auto,
                            backgroundColor: Colors.white,
                            gapless: false,
                            errorCorrectionLevel: QrErrorCorrectLevel.Q,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.thankYou,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.close,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
