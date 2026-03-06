// lib/features/scan/screens/qr_result_screen.dart
// Full-screen result page with CTAs, Ad space, and captured image.
//
// UPDATED: show Brand / Product name (when available) instead of the
// generic "Scanned value" for product barcodes. Falls back to product
// code / raw value when brand/product name are not available.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:securescan/services/language_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:securescan/l10n/app_localizations.dart';

import '../../../widgets/bottom_nav_shell.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securescan/services/product_service.dart';
import 'scan_screen_qr.dart'; 

class QrResultScreen extends StatefulWidget {
  final QrResultData result;

  const QrResultScreen({super.key, required this.result});

  @override
  State<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends State<QrResultScreen> {
  late Map<String, dynamic> _currentData;
  bool _isLoadingProduct = false;
  static const Color _primaryBlue = Color(0xFF0A66FF);

  @override
  void initState() {
    super.initState();
    _currentData = widget.result.data != null
        ? Map<String, dynamic>.from(widget.result.data!)
        : {};

    // If it's a product and we don't have brand/name info, fetch it now
    if (_isProduct &&
        _currentData['brand'] == null &&
        _currentData['product_name'] == null) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingProduct = true);

    try {
      final code = _currentData['code'] ?? widget.result.raw;
      final info = await ProductService.fetchProductInfo(code.toString());
      if (info != null && mounted) {
        setState(() {
          _currentData.addAll(info);
          _isLoadingProduct = false;
        });
        
        // Update history in background to include the newly found info
        _updateHistoryInBackground();
      } else if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  Future<void> _updateHistoryInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('scan_history') ?? [];
      if (list.isEmpty) return;

      // Find this item in history and update it
      // Note: This is an optimization, we don't strictly NEED to update history,
      // but it's nice for the history screen later.
      for (int i = list.length - 1; i >= 0; i--) {
        final map = jsonDecode(list[i]);
        if (map['raw'] == widget.result.raw && 
            (map['ts'] == widget.result.timestamp.toIso8601String() || i == list.length - 1)) {
          final payloadData = map['data'] != null ? Map<String, dynamic>.from(map['data']) : <String, dynamic>{};
          payloadData.addAll(_currentData);
          map['data'] = payloadData;
          list[i] = jsonEncode(map);
          await prefs.setStringList('scan_history', list);
          break;
        }
      }
    } catch (_) {}
  }

  bool _looksLikeProductBarcode() {
    try {
      if (_currentData['isIsbn'] == true) return true;
      if (_currentData['isProduct'] == true) return true;

      final fmt = (widget.result.format ?? '').toLowerCase();
      if (fmt.contains('ean') || fmt.contains('upc') || fmt.contains('isbn')) {
        return true;
      }

      final raw = widget.result.raw.trim();
      final digitOnly = RegExp(r'^\d+$').hasMatch(raw);
      if (digitOnly &&
          (raw.length == 8 ||
              raw.length == 12 ||
              raw.length == 13 ||
              raw.length == 14)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool get _isUrl => widget.result.kind == 'url';
  bool get _isProduct => widget.result.kind == 'product' || _looksLikeProductBarcode();
  bool get _isPhone => widget.result.kind == 'phone' && !_looksLikeProductBarcode();
  bool get _isEmail => widget.result.kind == 'email';
  bool get _isWifi => widget.result.kind == 'wifi';
  bool get _isVCard => widget.result.kind == 'vcard';
  bool get _isCalendar => widget.result.kind == 'calendar';
  bool get _isGeo => widget.result.kind == 'geo';
  bool get _isJson => widget.result.kind == 'json';
  bool get _isText => widget.result.kind == 'text';

  String get _bannerUnitId => kDebugMode 
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : 'ca-app-pub-4377808055186677/5171383893';

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'QrResultScreen',
      parameters: {'result_type': widget.result.kind},
    );

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const BottomNavShell()),
              (route) => false,
            );
          },
        ),
        title: Text(AppLocalizations.of(context)!.scanResult, style: const TextStyle(color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.safeScan,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _securityStatus(context, textTheme),
              const SizedBox(height: 16),
              _headerCard(context, textTheme),
              const SizedBox(height: 16),
              _valueCard(context, textTheme),
              const SizedBox(height: 16),
              _ctaRow(context, textTheme),
              const SizedBox(height: 16),
              _adSpace(),
              if (widget.result.imageBytes != null) ...[
                const SizedBox(height: 16),
                _capturedImageSection(textTheme, widget.result.imageBytes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- Security Status --------------------
  
  Widget _securityStatus(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.securityVerified,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Header --------------------
 
  Widget _headerCard(BuildContext context, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = _typeLabel(context);
    final formatLabel = widget.result.format ?? 'Unknown format';
    final timeStr = _formatTimestamp(widget.result.timestamp);

    IconData leadingIcon;
    if (_isProduct) {
      leadingIcon = Icons.inventory_2;
    } else {
      switch (widget.result.kind) {
        case 'url':
          leadingIcon = Icons.public;
          break;
        case 'phone':
          leadingIcon = Icons.phone;
          break;
        case 'email':
          leadingIcon = Icons.email_outlined;
          break;
        case 'wifi':
          leadingIcon = Icons.wifi;
          break;
        case 'vcard':
          leadingIcon = Icons.person;
          break;
        case 'calendar':
          leadingIcon = Icons.event;
          break;
        case 'geo':
          leadingIcon = Icons.location_on;
          break;
        case 'json':
          leadingIcon = Icons.data_object;
          break;
        default:
          leadingIcon = Icons.qr_code_2;
      }
    }

    return InkWell(
      onTap: () {
        if (_isUrl) {
          _onOpenUrl(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryBlue.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadingIcon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(context) + (_isUrl ? ' (Tap to open)' : ''),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeStr • $formatLabel',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // If it's an ISBN, prefer "Book"
    final isIsbn = (widget.result.data?['isIsbn'] == true);
    if (isIsbn) return l10n.book;

    if (_isProduct) return l10n.product;

    switch (widget.result.kind) {
      case 'url':
        return l10n.website;
      case 'phone':
        return l10n.phoneNumber;
      case 'email':
        return l10n.emailAddress;
      case 'wifi':
        return l10n.wifiNetwork;
      case 'vcard':
        return l10n.contact;
      case 'calendar':
        return l10n.calendarEvent;
      case 'geo':
        return l10n.location;
      case 'json':
        return l10n.jsonData;
      default:
        return l10n.content;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final locale = LanguageController.instance.currentLanguageCode;
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  // -------------------- Value card --------------------
  //
  // UPDATED: prefer widget.result.data['brand'] / ['product_name'] for products.
  // Show a clear fallback order:
  //  - brand (primary)
  //  - product_name (secondary)
  //  - code (if product)
  //  - raw scanned value

  Widget _valueCard(BuildContext context, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    final bool isProductIsbn = _isProduct && (_currentData['isIsbn'] == true);

    String title;
    String mainLine;
    String? subLine;

    if (_isProduct) {
      final brand = (_currentData['brand'] as String?)?.trim();
      final productName = (_currentData['product_name'] as String?)?.trim();
      final code = _currentData['code'] ?? widget.result.raw;

      if (brand != null && brand.isNotEmpty) {
        title = l10n.brand;
        mainLine = brand;
        if (productName != null && productName.isNotEmpty) {
          subLine = productName;
        } else {
          subLine = code?.toString();
        }
      } else if (productName != null && productName.isNotEmpty) {
        title = l10n.product;
        mainLine = productName;
        subLine = code?.toString();
      } else {
        title = isProductIsbn ? l10n.scannedIsbn : l10n.scannedProductCode;
        mainLine = (code ?? '').toString();
      }
    } else if (_isEmail && _currentData['mailto'] is String) {
      title = 'Email';
      mainLine = _currentData['mailto'] as String;
    } else {
      title = l10n.scannedValue;
      mainLine = widget.result.raw;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              if (_isLoadingProduct)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isUrl
              ? InkWell(
                  onTap: () => _onOpenUrl(context),
                  child: Text(
                    mainLine,
                    style: textTheme.bodyLarge?.copyWith(
                      color: _primaryBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: _primaryBlue.withOpacity(0.5),
                    ),
                  ),
                )
              : SelectableText(
                  mainLine,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                ),
          if (subLine != null) ...[
            const SizedBox(height: 8),
            Text(
              subLine,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------- CTA Row --------------------

  Widget _ctaRow(BuildContext context, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    final List<_CtaConfig> ctas = [];

    if (_isProduct) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.storefront,
          label: l10n.shopNow,
          onTap: () => _onShopNow(context),
        ),
        _CtaConfig(
          icon: Icons.search,
          label: l10n.webSearch,
          onTap: () => _onWebSearch(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: l10n.share,
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: l10n.copy,
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isUrl) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.open_in_browser,
          label: l10n.open,
          onTap: () => _onOpenUrl(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isPhone) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.call,
          label: 'Call',
          onTap: () => _onCall(context),
        ),
        _CtaConfig(icon: Icons.sms, label: l10n.sms, onTap: () => _onSms(context)),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isEmail) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.email,
          label: 'Email',
          onTap: () => _onComposeEmail(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isWifi) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.lock_open,
          label: 'Copy pass',
          onTap: () => _onCopyWifiPassword(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isVCard) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.call,
          label: 'Call',
          onTap: () => _onCall(context),
        ),
        _CtaConfig(
          icon: Icons.person_add,
          label: 'Add contact',
          onTap: () => _onAddContact(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isCalendar) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.event_available,
          label: 'Add event',
          onTap: () => _onAddCalendar(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isGeo) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.map,
          label: 'Open map',
          onTap: () => _onOpenMap(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else if (_isJson || _isText) {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.search,
          label: 'Web search',
          onTap: () => _onWebSearch(context),
        ),
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    } else {
      ctas.addAll([
        _CtaConfig(
          icon: Icons.share,
          label: 'Share',
          onTap: () => _onShare(context),
        ),
        _CtaConfig(
          icon: Icons.copy_all,
          label: 'Copy',
          onTap: () => _onCopy(context),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryBlue.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ctas
            .map((c) => _ctaItem(icon: c.icon, label: c.label, onTap: c.onTap))
            .toList(),
      ),
    );
  }

  Widget _ctaItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primaryBlue,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ---- CTA behaviour ----

  Future<void> _onShopNow(BuildContext context) async {
    final query = _isProduct
        ? (widget.result.data?['code'] ?? widget.result.raw).toString()
        : widget.result.raw;

    final uri = Uri.https('www.google.com', '/search', {
      'q': query,
      'tbm': 'shop',
    });

    await _launchOrSnack(context, uri);
  }

  Future<void> _onWebSearch(BuildContext context) async {
    final q = _displayValueForSearch();
    final uri = Uri.https('www.google.com', '/search', {'q': q});
    await _launchOrSnack(context, uri);
  }

  Future<void> _onOpenUrl(BuildContext context) async {
    final uri = Uri.parse(_displayValueForSearch());
    await _launchOrSnack(context, uri, openDirect: true);
  }

  Future<void> _onShare(BuildContext context) async {
    await Share.share(_displayValueForSearch());
  }

  Future<void> _onCopy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayValueForSearch()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)));
  }

  Future<void> _onCall(BuildContext context) async {
    String value = _displayValueForSearch();
    String? phoneToCall;

    // If this is a vCard payload, try to extract the first phone number
    if (_isVCard || value.contains('BEGIN:VCARD')) {
      final lines = value.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final upper = line.toUpperCase();
        if (upper.startsWith('TEL')) {
          // vCard TEL;TYPE=CELL:+123456789 or TEL:+123456789
          final parts = line.split(':');
          if (parts.length > 1) {
            final candidate = parts.last.trim();
            if (candidate.isNotEmpty) {
              phoneToCall = candidate;
              break;
            }
          }
        }
      }
    }

    // Fallback: if we didn’t find a phone in vCard, use the scanned value
    phoneToCall ??= value;

    final uri = Uri.parse('tel:$phoneToCall');
    await _launchOrSnack(context, uri, openDirect: true);
  }

  Future<void> _onSms(BuildContext context) async {
    final uri = Uri.parse('sms:${_displayValueForSearch()}');
    await _launchOrSnack(context, uri, openDirect: true);
  }

  Future<void> _onComposeEmail(BuildContext context) async {
    final addr = _displayValueForSearch();
    final uri = Uri.parse('mailto:$addr');
    await _launchOrSnack(context, uri, openDirect: true);
  }

  Future<void> _onCopyWifiPassword(BuildContext context) async {
    final pass = (widget.result.data?['password'] ?? '') as String;
    final text = pass.isEmpty ? _displayValueForSearch() : pass;
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.wifiPassCopied)));
  }

  /// Create a .vcf file from the vCard text and let the OS
  /// open it with the default Contacts app (via share sheet).
  Future<void> _onAddContact(BuildContext context) async {
    try {
      final vcard =
          _displayValueForSearch(); // should be full BEGIN:VCARD ... text

      if (!vcard.contains('BEGIN:VCARD')) {
        // Fallback: just copy text if this isn't a vCard payload
        await Clipboard.setData(ClipboardData(text: vcard));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.contactDataCopied),
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/contact_${DateTime.now().millisecondsSinceEpoch}.vcf',
      );
      await file.writeAsString(vcard);

      final xFile = XFile(file.path, mimeType: 'text/x-vcard');

      // This will show the system share sheet; on phones, Contacts
      // app will usually appear as an option to directly import.
      await Share.shareXFiles(
        [xFile],
        subject: 'Add contact',
        text: 'Import this contact into your Contacts app.',
      );
    } catch (_) {
      // Last-resort fallback
      await Clipboard.setData(ClipboardData(text: _displayValueForSearch()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Contacts – contact data copied instead.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onAddCalendar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayValueForSearch()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDataCopied),
      ),
    );
  }

  Future<void> _onOpenMap(BuildContext context) async {
    double? lat = widget.result.data?['lat'] is num
        ? (widget.result.data!['lat'] as num).toDouble()
        : null;
    double? lng = widget.result.data?['lng'] is num
        ? (widget.result.data!['lng'] as num).toDouble()
        : null;

    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      final q = _displayValueForSearch();
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }

    await _launchOrSnack(context, uri, openDirect: true);
  }

  Future<void> _launchOrSnack(
    BuildContext context,
    Uri uri, {
    bool openDirect = false,
  }) async {
    try {
      if (openDirect) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Cannot open URL');
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text(AppLocalizations.of(context)!.failedToScan('Link'))));
      }
    }
  }

  // -------------------- Ad + image --------------------

  Widget _adSpace() {
    final BannerAd banner = BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    banner.load();

    return Container(
      width: double.infinity,
      height: banner.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: banner),
    );
  }



  // -------------------- Captured Image --------------------

  Widget _capturedImageSection(TextTheme textTheme, Uint8List bytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Captured image',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------- Utilities --------------------

  // Value used for sharing / web search / copy etc. Prefer brand/product_name
  // for product results because that is more useful to users when searching.
  String _displayValueForSearch() {
    if (_isProduct) {
      final brand = (widget.result.data?['brand'] as String?)?.trim();
      final productName = (widget.result.data?['product_name'] as String?)?.trim();
      final code = widget.result.data?['code'] ?? widget.result.raw;

      if (brand != null &&
          brand.isNotEmpty &&
          productName != null &&
          productName.isNotEmpty) {
        return '$brand $productName';
      }
      if (brand != null && brand.isNotEmpty) return brand;
      if (productName != null && productName.isNotEmpty) return productName;
      return code?.toString() ?? widget.result.raw;
    }

    if (_isEmail && widget.result.data?['mailto'] is String) {
      return widget.result.data!['mailto'] as String;
    }

    return widget.result.raw;
  }
}

// Simple config holder for CTAs
class _CtaConfig {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _CtaConfig({required this.icon, required this.label, required this.onTap});
}
