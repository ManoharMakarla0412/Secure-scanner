import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QR & Barcode Scanner Generator'**
  String get appTitle;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Quick scan QR & Barcodes'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick scan any QR codes /barcodes and get results instantly'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Get product information'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan product barcode to get product information and other products information'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Create Multiple QR codes'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'A powerful generator meets all your needs for creating QR codes'**
  String get onboarding3Subtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue'**
  String get selectLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @scanImage.
  ///
  /// In en, this message translates to:
  /// **'Scan Image'**
  String get scanImage;

  /// No description provided for @myQr.
  ///
  /// In en, this message translates to:
  /// **'My QR'**
  String get myQr;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContact;

  /// No description provided for @yourContactQr.
  ///
  /// In en, this message translates to:
  /// **'Your Contact QR'**
  String get yourContactQr;

  /// No description provided for @onboardingMyQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill your contact details once. Next time you open My QR, your contact QR will be shown automatically.'**
  String get onboardingMyQrDesc;

  /// No description provided for @nameWithAst.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameWithAst;

  /// No description provided for @phoneWithAst.
  ///
  /// In en, this message translates to:
  /// **'Phone *'**
  String get phoneWithAst;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @saveAndGenerate.
  ///
  /// In en, this message translates to:
  /// **'Save & Generate QR'**
  String get saveAndGenerate;

  /// No description provided for @noContactQrFound.
  ///
  /// In en, this message translates to:
  /// **'No contact QR found'**
  String get noContactQrFound;

  /// No description provided for @createNow.
  ///
  /// In en, this message translates to:
  /// **'Create Now'**
  String get createNow;

  /// No description provided for @namePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and Phone are required'**
  String get namePhoneRequired;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Permissions Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @appInfoSupport.
  ///
  /// In en, this message translates to:
  /// **'App Info & Support'**
  String get appInfoSupport;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'QR & Barcode Scanner Generator ©️ 2026'**
  String get copyright;

  /// No description provided for @themeSetTo.
  ///
  /// In en, this message translates to:
  /// **'Theme set to {mode}'**
  String themeSetTo(String mode);

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get systemMode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cameraNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Camera not working properly. Please re-open the app'**
  String get cameraNotWorking;

  /// No description provided for @noCodeFound.
  ///
  /// In en, this message translates to:
  /// **'No code found in this image'**
  String get noCodeFound;

  /// No description provided for @failedToScan.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan image: {error}'**
  String failedToScan(String error);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistoryFound;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @yourQrCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR QR CODE'**
  String get yourQrCode;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @json.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get json;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createQr.
  ///
  /// In en, this message translates to:
  /// **'Create QR'**
  String get createQr;

  /// No description provided for @clipboardContent.
  ///
  /// In en, this message translates to:
  /// **'Content from clipboard'**
  String get clipboardContent;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @createQrCode.
  ///
  /// In en, this message translates to:
  /// **'Create QR Code'**
  String get createQrCode;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid phone number is required'**
  String get phoneRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailRequired;

  /// No description provided for @linkRequired.
  ///
  /// In en, this message translates to:
  /// **'Link is required'**
  String get linkRequired;

  /// No description provided for @validLinkRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid link (e.g. example.com)'**
  String get validLinkRequired;

  /// No description provided for @ssidRequired.
  ///
  /// In en, this message translates to:
  /// **'SSID is required'**
  String get ssidRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required for selected encryption'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @fixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors above'**
  String get fixErrors;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter text.'**
  String get enterText;

  /// No description provided for @qrSaved.
  ///
  /// In en, this message translates to:
  /// **'QR saved to {fileName}'**
  String qrSaved(String fileName);

  /// No description provided for @myGeneratedQr.
  ///
  /// In en, this message translates to:
  /// **'My generated QR Code'**
  String get myGeneratedQr;

  /// No description provided for @scanResult.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get scanResult;

  /// No description provided for @safeScan.
  ///
  /// In en, this message translates to:
  /// **'SAFE SCAN'**
  String get safeScan;

  /// No description provided for @securityVerified.
  ///
  /// In en, this message translates to:
  /// **'Security verified: This scan is safe to use.'**
  String get securityVerified;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @wifiNetwork.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi network'**
  String get wifiNetwork;

  /// No description provided for @calendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Calendar event'**
  String get calendarEvent;

  /// No description provided for @jsonData.
  ///
  /// In en, this message translates to:
  /// **'JSON data'**
  String get jsonData;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @scannedValue.
  ///
  /// In en, this message translates to:
  /// **'Scanned value'**
  String get scannedValue;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @scannedIsbn.
  ///
  /// In en, this message translates to:
  /// **'Scanned ISBN'**
  String get scannedIsbn;

  /// No description provided for @scannedProductCode.
  ///
  /// In en, this message translates to:
  /// **'Scanned Product Code'**
  String get scannedProductCode;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop now'**
  String get shopNow;

  /// No description provided for @webSearch.
  ///
  /// In en, this message translates to:
  /// **'Web search'**
  String get webSearch;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @copyPass.
  ///
  /// In en, this message translates to:
  /// **'Copy pass'**
  String get copyPass;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @wifiPassCopied.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi password copied'**
  String get wifiPassCopied;

  /// No description provided for @contactDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Contact data copied – paste it into Contacts.'**
  String get contactDataCopied;

  /// No description provided for @importContactText.
  ///
  /// In en, this message translates to:
  /// **'Import this contact into your Contacts app.'**
  String get importContactText;

  /// No description provided for @couldNotOpenContacts.
  ///
  /// In en, this message translates to:
  /// **'Could not open Contacts – contact data copied instead.'**
  String get couldNotOpenContacts;

  /// No description provided for @eventDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Event data copied – import it into your Calendar app.'**
  String get eventDataCopied;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using\nQR & Barcode Scanner Generator'**
  String get thankYou;

  /// No description provided for @pickContact.
  ///
  /// In en, this message translates to:
  /// **'Pick contact'**
  String get pickContact;

  /// No description provided for @failedToCapture.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture image'**
  String get failedToCapture;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {error}'**
  String errorSaving(Object error);

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing image: {error}'**
  String errorSharing(Object error);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @emailWithAst.
  ///
  /// In en, this message translates to:
  /// **'Email *'**
  String get emailWithAst;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @urlNameWithAst.
  ///
  /// In en, this message translates to:
  /// **'URL Name *'**
  String get urlNameWithAst;

  /// No description provided for @urlLinkWithAst.
  ///
  /// In en, this message translates to:
  /// **'URL Link *'**
  String get urlLinkWithAst;

  /// No description provided for @wifiNameWithAst.
  ///
  /// In en, this message translates to:
  /// **'WiFi Name (SSID) *'**
  String get wifiNameWithAst;

  /// No description provided for @encryptionTypeWithAst.
  ///
  /// In en, this message translates to:
  /// **'Encryption Type *'**
  String get encryptionTypeWithAst;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @noPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'No password required'**
  String get noPasswordRequired;

  /// No description provided for @phoneNumberWithAst.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumberWithAst;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'I am using QR & Barcode Scanner Generator App, the fast and secure QR and Barcode reader. Try it now! {url}'**
  String shareMessage(Object url);

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan codes.'**
  String get cameraPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage app permissions'**
  String get permissionsSubtitle;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get permissionGallery;

  /// No description provided for @permissionCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for scanning QR and Barcodes'**
  String get permissionCameraDesc;

  /// No description provided for @permissionGalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for picking images from gallery'**
  String get permissionGalleryDesc;

  /// No description provided for @statusGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get statusGranted;

  /// No description provided for @statusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get statusDenied;

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download Successful'**
  String get downloadSuccess;

  /// No description provided for @legalInfo.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalInfo;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @backToMain.
  ///
  /// In en, this message translates to:
  /// **'Back to Main'**
  String get backToMain;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @scanDetail.
  ///
  /// In en, this message translates to:
  /// **'Scan Detail'**
  String get scanDetail;

  /// No description provided for @scanResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get scanResultTitle;

  /// No description provided for @qrCodeReady.
  ///
  /// In en, this message translates to:
  /// **'QR Code Ready!'**
  String get qrCodeReady;

  /// No description provided for @qrGeneratedSaved.
  ///
  /// In en, this message translates to:
  /// **'Your QR code has been generated and saved to history.'**
  String get qrGeneratedSaved;

  /// No description provided for @qrSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'QR Code saved to gallery!'**
  String get qrSavedToGallery;

  /// No description provided for @sharePromoText.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code generated by SecureScan: {url}'**
  String sharePromoText(String url);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
