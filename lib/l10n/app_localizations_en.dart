// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QR & Barcode Scanner Generator';

  @override
  String get onboarding1Title => 'Quick scan QR & Barcodes';

  @override
  String get onboarding1Subtitle =>
      'Quick scan any QR codes /barcodes and get results instantly';

  @override
  String get onboarding2Title => 'Get product information';

  @override
  String get onboarding2Subtitle =>
      'Scan product barcode to get product information and other products information';

  @override
  String get onboarding3Title => 'Create Multiple QR codes';

  @override
  String get onboarding3Subtitle =>
      'A powerful generator meets all your needs for creating QR codes';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectLanguageSubtitle =>
      'Select your preferred language to continue';

  @override
  String get english => 'English';

  @override
  String get japanese => 'Japanese';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get home => 'Home';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get scanImage => 'Scan Image';

  @override
  String get myQr => 'My QR';

  @override
  String get shareApp => 'Share App';

  @override
  String get changeTheme => 'Change Theme';

  @override
  String get editContact => 'Edit contact';

  @override
  String get yourContactQr => 'Your Contact QR';

  @override
  String get onboardingMyQrDesc =>
      'Fill your contact details once. Next time you open My QR, your contact QR will be shown automatically.';

  @override
  String get nameWithAst => 'Name *';

  @override
  String get phoneWithAst => 'Phone *';

  @override
  String get company => 'Company';

  @override
  String get saveAndGenerate => 'Save & Generate QR';

  @override
  String get noContactQrFound => 'No contact QR found';

  @override
  String get createNow => 'Create Now';

  @override
  String get namePhoneRequired => 'Name and Phone are required';

  @override
  String get privacyPolicy => 'Privacy & Permissions Policy';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get appInfoSupport => 'App Info & Support';

  @override
  String get copyright => 'QR & Barcode Scanner Generator ©️ 2026';

  @override
  String themeSetTo(String mode) {
    return 'Theme set to $mode';
  }

  @override
  String get systemMode => 'System Mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get cancel => 'Cancel';

  @override
  String get cameraNotWorking =>
      'Camera not working properly. Please re-open the app';

  @override
  String get noCodeFound => 'No code found in this image';

  @override
  String failedToScan(String error) {
    return 'Failed to scan image: $error';
  }

  @override
  String get history => 'History';

  @override
  String get scan => 'Scan';

  @override
  String get created => 'Created';

  @override
  String get noHistoryFound => 'No history found';

  @override
  String get delete => 'Delete';

  @override
  String get yourQrCode => 'YOUR QR CODE';

  @override
  String get close => 'Close';

  @override
  String get url => 'URL';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get contact => 'Contact';

  @override
  String get calendar => 'Calendar';

  @override
  String get location => 'Location';

  @override
  String get json => 'JSON';

  @override
  String get content => 'Content';

  @override
  String get create => 'Create';

  @override
  String get createQr => 'Create QR';

  @override
  String get clipboardContent => 'Content from clipboard';

  @override
  String get text => 'Text';

  @override
  String get createQrCode => 'Create QR Code';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneRequired => 'Valid phone number is required';

  @override
  String get emailRequired => 'Enter a valid email';

  @override
  String get linkRequired => 'Link is required';

  @override
  String get validLinkRequired => 'Enter a valid link (e.g. example.com)';

  @override
  String get ssidRequired => 'SSID is required';

  @override
  String get passwordRequired => 'Password is required for selected encryption';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get fixErrors => 'Please fix the errors above';

  @override
  String get enterText => 'Please enter text.';

  @override
  String qrSaved(String fileName) {
    return 'QR saved to $fileName';
  }

  @override
  String get myGeneratedQr => 'My generated QR Code';

  @override
  String get scanResult => 'Scan result';

  @override
  String get safeScan => 'SAFE SCAN';

  @override
  String get securityVerified => 'Security verified: This scan is safe to use.';

  @override
  String get website => 'Website';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get emailAddress => 'Email address';

  @override
  String get wifiNetwork => 'Wi-Fi network';

  @override
  String get calendarEvent => 'Calendar event';

  @override
  String get jsonData => 'JSON data';

  @override
  String get book => 'Book';

  @override
  String get product => 'Product';

  @override
  String get scannedValue => 'Scanned value';

  @override
  String get brand => 'Brand';

  @override
  String get scannedIsbn => 'Scanned ISBN';

  @override
  String get scannedProductCode => 'Scanned Product Code';

  @override
  String get shopNow => 'Shop now';

  @override
  String get webSearch => 'Web search';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get open => 'Open';

  @override
  String get call => 'Call';

  @override
  String get sms => 'SMS';

  @override
  String get copyPass => 'Copy pass';

  @override
  String get addContact => 'Add contact';

  @override
  String get addEvent => 'Add event';

  @override
  String get openMap => 'Open map';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get wifiPassCopied => 'Wi-Fi password copied';

  @override
  String get contactDataCopied =>
      'Contact data copied – paste it into Contacts.';

  @override
  String get importContactText => 'Import this contact into your Contacts app.';

  @override
  String get couldNotOpenContacts =>
      'Could not open Contacts – contact data copied instead.';

  @override
  String get eventDataCopied =>
      'Event data copied – import it into your Calendar app.';

  @override
  String get thankYou => 'Thank you for using\nQR & Barcode Scanner Generator';

  @override
  String get pickContact => 'Pick contact';

  @override
  String get failedToCapture => 'Failed to capture image';

  @override
  String errorSaving(Object error) {
    return 'Error saving image: $error';
  }

  @override
  String errorSharing(Object error) {
    return 'Error sharing image: $error';
  }

  @override
  String get save => 'Save';

  @override
  String get emailWithAst => 'Email *';

  @override
  String get designation => 'Designation';

  @override
  String get address => 'Address';

  @override
  String get urlNameWithAst => 'URL Name *';

  @override
  String get urlLinkWithAst => 'URL Link *';

  @override
  String get wifiNameWithAst => 'WiFi Name (SSID) *';

  @override
  String get encryptionTypeWithAst => 'Encryption Type *';

  @override
  String get password => 'Password';

  @override
  String get noPasswordRequired => 'No password required';

  @override
  String get phoneNumberWithAst => 'Phone Number *';

  @override
  String shareMessage(Object url) {
    return 'I am using QR & Barcode Scanner Generator App, the fast and secure QR and Barcode reader. Try it now! $url';
  }

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to scan codes.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsSubtitle => 'Manage app permissions';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionGallery => 'Gallery';

  @override
  String get permissionCameraDesc => 'Required for scanning QR and Barcodes';

  @override
  String get permissionGalleryDesc =>
      'Required for picking images from gallery';

  @override
  String get statusGranted => 'Granted';

  @override
  String get statusDenied => 'Denied';
}
