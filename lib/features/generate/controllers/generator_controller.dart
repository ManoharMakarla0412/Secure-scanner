import 'package:flutter/material.dart';
import 'package:securescan/core/enums/qr_type.dart';
import 'package:securescan/core/models/history_item.dart';
import 'package:securescan/core/repositories/history_repository.dart';
import 'package:securescan/l10n/app_localizations.dart';

class GeneratorController extends ChangeNotifier {
  final QrType selectedType;
  
  // Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final companyController = TextEditingController();
  final designationController = TextEditingController();
  final addressController = TextEditingController();
  final urlNameController = TextEditingController();
  final urlLinkController = TextEditingController();
  final wifiNameController = TextEditingController();
  final wifiPasswordController = TextEditingController();
  final textController = TextEditingController();

  String fullPhoneNumber = ''; // Stores the phone number with country code
  
  // Calendar specific
  final eventTitleController = TextEditingController();
  final eventLocationController = TextEditingController();
  final eventDescController = TextEditingController();
  
  // Location specific
  final latController = TextEditingController();
  final lngController = TextEditingController();
  
  String encryptionValue = "WPA/WPA2";
  bool wifiPasswordVisible = false;
  bool isCreated = false;
  String qrData = "";

  // Error states
  String? nameError;
  String? phoneError;
  String? emailError;
  String? urlNameError;
  String? urlLinkError;
  String? wifiNameError;
  String? wifiPasswordError;
  String? textError;
  String? eventTitleError;
  String? latError;
  String? lngError;

  GeneratorController(this.selectedType) {
    if (selectedType == QrType.url) {
      urlLinkController.text = 'https://';
    }
  }

  void toggleWifiPasswordVisibility() {
    wifiPasswordVisible = !wifiPasswordVisible;
    notifyListeners();
  }

  void setEncryption(String? value) {
    if (value != null) {
      encryptionValue = value;
      notifyListeners();
    }
  }

  void setIsCreated(bool value) {
    isCreated = value;
    notifyListeners();
  }

  bool validate(AppLocalizations l10n, {bool setStateErrors = true}) {
    bool isValid = true;
    String? nErr, pErr, eErr, unErr, ulErr, wnErr, wpErr, tErr, etErr, latErr, lngErr;

    switch (selectedType) {
      case QrType.url:
        if (urlNameController.text.trim().isEmpty) {
          unErr = l10n.nameRequired;
          isValid = false;
        }
        final link = urlLinkController.text.trim();
        if (link.isEmpty || link == 'https://') {
          ulErr = l10n.linkRequired;
          isValid = false;
        } else {
          final l = link.toLowerCase();
          if (!l.contains('.') && !l.startsWith('http')) {
            ulErr = l10n.validLinkRequired;
            isValid = false;
          }
        }
        break;
      case QrType.wifi:
        if (wifiNameController.text.trim().isEmpty) {
          wnErr = l10n.ssidRequired;
          isValid = false;
        }
        if (encryptionValue.toLowerCase() != 'none') {
          final pass = wifiPasswordController.text;
          if (pass.isEmpty) {
            wpErr = l10n.passwordRequired;
            isValid = false;
          } else if (pass.length < 8) {
            wpErr = l10n.passwordMinLength;
            isValid = false;
          }
        }
        break;
      case QrType.contact:
        if (nameController.text.trim().isEmpty) {
          nErr = l10n.nameRequired;
          isValid = false;
        }
        if (phoneController.text.trim().isEmpty) {
          pErr = l10n.phoneRequired;
          isValid = false;
        }
        break;
      case QrType.phone:
        if (phoneController.text.trim().isEmpty) {
          pErr = l10n.phoneRequired;
          isValid = false;
        }
        break;
      case QrType.email:
        final email = emailController.text.trim();
        if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          eErr = l10n.emailRequired;
          isValid = false;
        }
        break;
      case QrType.text:
        if (textController.text.trim().isEmpty) {
          tErr = l10n.enterText;
          isValid = false;
        }
        break;
      case QrType.calendar:
        if (eventTitleController.text.trim().isEmpty) {
          etErr = l10n.nameRequired;
          isValid = false;
        }
        break;
      case QrType.location:
        if (latController.text.trim().isEmpty) {
          latErr = l10n.nameRequired;
          isValid = false;
        }
        if (lngController.text.trim().isEmpty) {
          lngErr = l10n.nameRequired;
          isValid = false;
        }
        break;
      default:
        break;
    }

    if (setStateErrors) {
      nameError = nErr;
      phoneError = pErr;
      emailError = eErr;
      urlNameError = unErr;
      urlLinkError = ulErr;
      wifiNameError = wnErr;
      wifiPasswordError = wpErr;
      textError = tErr;
      eventTitleError = etErr;
      this.latError = latErr;
      this.lngError = lngErr;
      notifyListeners();
    }
    return isValid;
  }

  Future<void> generateQRCode(AppLocalizations l10n) async {
    if (!validate(l10n)) return;

    qrData = _buildQrData();
    isCreated = true;

    final newItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType,
      value: qrData,
      timestamp: DateTime.now(),
      isCreated: true,
    );
    await HistoryRepository.instance.saveCreatedItem(newItem);
    
    notifyListeners();
  }

  String _buildQrData() {
    switch (selectedType) {
      case QrType.url:
        return urlLinkController.text.trim();
      case QrType.wifi:
        return "WIFI:S:${wifiNameController.text.trim()};T:$encryptionValue;P:${wifiPasswordController.text.trim()};;";
      case QrType.contact:
        final phoneToUse = fullPhoneNumber.isNotEmpty ? fullPhoneNumber : phoneController.text.trim();
        return "MECARD:N:${nameController.text.trim()};TEL:$phoneToUse;EMAIL:${emailController.text.trim()};ADR:${addressController.text.trim()};ORG:${companyController.text.trim()};TITLE:${designationController.text.trim()};;";
      case QrType.phone:
        final phoneToUse = fullPhoneNumber.isNotEmpty ? fullPhoneNumber : phoneController.text.trim();
        return "TEL:$phoneToUse";
      case QrType.email:
        return "MAILTO:${emailController.text.trim()}";
      case QrType.text:
        return textController.text.trim();
      case QrType.calendar:
        return "BEGIN:VEVENT\nSUMMARY:${eventTitleController.text.trim()}\nLOCATION:${eventLocationController.text.trim()}\nDESCRIPTION:${eventDescController.text.trim()}\nEND:VEVENT";
      case QrType.location:
        return "geo:${latController.text.trim()},${lngController.text.trim()}";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    companyController.dispose();
    designationController.dispose();
    addressController.dispose();
    urlNameController.dispose();
    urlLinkController.dispose();
    wifiNameController.dispose();
    wifiPasswordController.dispose();
    textController.dispose();
    eventTitleController.dispose();
    eventLocationController.dispose();
    eventDescController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }
}
