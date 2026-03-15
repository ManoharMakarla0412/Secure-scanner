// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'QR＆バーコードスキャナー・ジェネレーター';

  @override
  String get onboarding1Title => 'QRコードとバーコードを素早くスキャン';

  @override
  String get onboarding1Subtitle => 'あらゆるQRコードやバーコードを素早くスキャンし、即座に結果を取得します';

  @override
  String get onboarding2Title => '商品情報を取得';

  @override
  String get onboarding2Subtitle => '商品のバーコードをスキャンして、商品情報やその他の商品情報を取得します';

  @override
  String get onboarding3Title => '複数のQRコードを作成';

  @override
  String get onboarding3Subtitle => 'QRコード作成に関するあらゆるニーズに応える強力なジェネレーター';

  @override
  String get getStarted => 'はじめる';

  @override
  String get next => '次へ';

  @override
  String get settingsTitle => '設定';

  @override
  String get changeLanguage => '言語を変更';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get selectLanguageSubtitle => '続行するには、お好みの言語を選択してください';

  @override
  String get english => '英語';

  @override
  String get japanese => '日本語';

  @override
  String get portuguese => 'ポルトガル語';

  @override
  String get home => 'ホーム';

  @override
  String get scanQr => 'QRをスキャン';

  @override
  String get scanImage => '画像をスキャン';

  @override
  String get myQr => '自身のQR';

  @override
  String get shareApp => 'アプリを共有';

  @override
  String get changeTheme => 'テーマを変更';

  @override
  String get editContact => '連絡先を編集';

  @override
  String get yourContactQr => 'あなたの連絡先QR';

  @override
  String get onboardingMyQrDesc =>
      '連絡先情報を一度入力してください。次から「自身のQR」を開くと、自動的にQRコードが表示されます。';

  @override
  String get nameWithAst => '名前 *';

  @override
  String get phoneWithAst => '電話番号 *';

  @override
  String get company => '会社';

  @override
  String get saveAndGenerate => '保存してQRを生成';

  @override
  String get noContactQrFound => '連絡先QRが見つかりません';

  @override
  String get createNow => '今すぐ作成';

  @override
  String get namePhoneRequired => '名前と電話番号は必須です';

  @override
  String get privacyPolicy => 'プライバシーと権限のポリシー';

  @override
  String get termsConditions => '利用規約';

  @override
  String get appInfoSupport => 'アプリ情報とサポート';

  @override
  String get copyright => 'QR & Barcode Scanner Generator ©️ 2026';

  @override
  String themeSetTo(String mode) {
    return 'テーマが $mode に設定されました';
  }

  @override
  String get systemMode => 'システムモード';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get cancel => 'キャンセル';

  @override
  String get cameraNotWorking => 'カメラが正常に動作していません。アプリを再起動してください';

  @override
  String get noCodeFound => 'この画像にはコードが見つかりませんでした';

  @override
  String failedToScan(String error) {
    return 'スキャンに失敗しました: $error';
  }

  @override
  String get history => '履歴';

  @override
  String get scan => 'スキャン';

  @override
  String get created => '作成済み';

  @override
  String get noHistoryFound => '履歴が見つかりません';

  @override
  String get delete => '削除';

  @override
  String get yourQrCode => 'あなたのQRコード';

  @override
  String get close => '閉じる';

  @override
  String get url => 'URL';

  @override
  String get phone => '電話';

  @override
  String get email => 'メール';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get contact => '連絡先';

  @override
  String get calendar => 'カレンダー';

  @override
  String get location => '場所';

  @override
  String get json => 'JSON';

  @override
  String get content => 'コンテンツ';

  @override
  String get create => '作成';

  @override
  String get createQr => 'QR作成';

  @override
  String get clipboardContent => 'クリップボードのコンテンツ';

  @override
  String get text => 'テキスト';

  @override
  String get createQrCode => 'QRコードを作成';

  @override
  String get nameRequired => '名前は必須です';

  @override
  String get phoneRequired => '有効な電話番号が必要です';

  @override
  String get emailRequired => '有効なメールアドレスを入力してください';

  @override
  String get linkRequired => 'リンクは必須です';

  @override
  String get validLinkRequired => '有効なリンクを入力してください（例：example.com）';

  @override
  String get ssidRequired => 'SSIDは必須です';

  @override
  String get passwordRequired => '選択した暗号化モードにはパスワードが必要です';

  @override
  String get passwordMinLength => 'パスワードは8文字以上である必要があります';

  @override
  String get fixErrors => '上記のエラーを修正してください';

  @override
  String get enterText => 'テキストを入力してください。';

  @override
  String qrSaved(String fileName) {
    return 'QRが$fileNameに保存されました';
  }

  @override
  String get myGeneratedQr => '私が作成したQRコード';

  @override
  String get scanResult => 'スキャン結果';

  @override
  String get safeScan => 'セーフスキャン';

  @override
  String get securityVerified => 'セキュリティ確認済み：このスキャンは安全に使用できます。';

  @override
  String get website => 'ウェブサイト';

  @override
  String get phoneNumber => '電話番号';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get wifiNetwork => 'Wi-Fiネットワーク';

  @override
  String get calendarEvent => 'カレンダーイベント';

  @override
  String get jsonData => 'JSONデータ';

  @override
  String get book => '本';

  @override
  String get product => '商品';

  @override
  String get scannedValue => 'スキャンされた値';

  @override
  String get brand => 'ブランド';

  @override
  String get scannedIsbn => 'スキャンされたISBN';

  @override
  String get scannedProductCode => 'スキャンされた商品コード';

  @override
  String get shopNow => '今すぐ購入';

  @override
  String get webSearch => 'ウェブ検索';

  @override
  String get share => '共有';

  @override
  String get copy => 'コピー';

  @override
  String get open => '開く';

  @override
  String get call => '電話をかける';

  @override
  String get sms => 'SMS送信';

  @override
  String get copyPass => 'パスワードをコピー';

  @override
  String get addContact => '連絡先を追加';

  @override
  String get addEvent => 'イベントを追加';

  @override
  String get openMap => '地図を開く';

  @override
  String get copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String get wifiPassCopied => 'Wi-Fiパスワードをコピーしました';

  @override
  String get contactDataCopied => '連絡先データをコピーしました。連絡先アプリに貼り付けてください。';

  @override
  String get importContactText => 'この連絡先を連絡先アプリにインポートします。';

  @override
  String get couldNotOpenContacts => '連絡先を開けませんでした。代わりに連絡先データをコピーしました。';

  @override
  String get eventDataCopied => 'イベントデータをコピーしました。カレンダーアプリにインポートしてください。';

  @override
  String get thankYou => 'QR＆バーコードスキャナー・ジェネレーターをご利用いただきありがとうございます';

  @override
  String get pickContact => '連絡先を選択';

  @override
  String get failedToCapture => '画像のキャプチャに失敗しました';

  @override
  String errorSaving(Object error) {
    return '画像の保存中にエラーが発生しました: $error';
  }

  @override
  String errorSharing(Object error) {
    return '画像の共有中にエラーが発生しました: $error';
  }

  @override
  String get save => '保存';

  @override
  String get emailWithAst => 'メールアドレス *';

  @override
  String get designation => '役職';

  @override
  String get address => '住所';

  @override
  String get urlNameWithAst => 'URL名 *';

  @override
  String get urlLinkWithAst => 'URLリンク *';

  @override
  String get wifiNameWithAst => 'WiFi名 (SSID) *';

  @override
  String get encryptionTypeWithAst => '暗号化タイプ *';

  @override
  String get password => 'パスワード';

  @override
  String get noPasswordRequired => 'パスワード不要';

  @override
  String get phoneNumberWithAst => '電話番号 *';

  @override
  String shareMessage(Object url) {
    return '高速で安全なQR＆バーコードリーダー、QR＆バーコードスキャナー・ジェネレーターアプリを使用しています。今すぐお試しください！ $url';
  }

  @override
  String get cameraPermissionRequired => 'コードをスキャンするにはカメラの許可が必要です。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get permissionsTitle => '権限';

  @override
  String get permissionsSubtitle => 'アプリの権限を管理';

  @override
  String get permissionCamera => 'カメラ';

  @override
  String get permissionGallery => 'ギャラリー';

  @override
  String get permissionCameraDesc => 'QRコードやバーコードのスキャンに必要です';

  @override
  String get permissionGalleryDesc => 'ギャラリーから画像を選択するために必要です';

  @override
  String get statusGranted => '許可済み';

  @override
  String get statusDenied => '拒否済み';

  @override
  String get downloadSuccess => 'ダウンロード成功';

  @override
  String get legalInfo => '法的情報';

  @override
  String get download => 'ダウンロード';

  @override
  String get edit => '編集';

  @override
  String get backToMain => 'メインに戻る';

  @override
  String get ok => 'OK';

  @override
  String get scanDetail => 'スキャンの詳細';

  @override
  String get scanResultTitle => 'スキャン結果';

  @override
  String get qrCodeReady => 'QRコードの準備ができました！';

  @override
  String get qrGeneratedSaved => 'QRコードが生成され、履歴に保存されました。';

  @override
  String get qrSavedToGallery => 'QRコードがギャラリーに保存されました！';

  @override
  String sharePromoText(String url) {
    return 'SecureScanで生成されたこのQRコードをスキャンしてください: $url';
  }
}
