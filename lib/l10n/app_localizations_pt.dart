// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gerador de Scanner de QR e Código de Barras';

  @override
  String get onboarding1Title =>
      'Digitalize rapidamente QR e códigos de barras';

  @override
  String get onboarding1Subtitle =>
      'Digitalize rapidamente quaisquer códigos QR / códigos de barras e obtenha resultados instantaneamente';

  @override
  String get onboarding2Title => 'Obtenha informações do produto';

  @override
  String get onboarding2Subtitle =>
      'Digitalize o código de barras do produto para obter informações sobre o produto e outras informações sobre produtos';

  @override
  String get onboarding3Title => 'Crie vários códigos QR';

  @override
  String get onboarding3Subtitle =>
      'Um gerador poderoso que atende a todas as suas necessidades de criação de códigos QR';

  @override
  String get getStarted => 'Começar';

  @override
  String get next => 'Próximo';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get changeLanguage => 'Alterar idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get selectLanguageSubtitle =>
      'Selecione o seu idioma preferido para continuar';

  @override
  String get english => 'Inglês';

  @override
  String get japanese => 'Japonês';

  @override
  String get portuguese => 'Português';

  @override
  String get home => 'Início';

  @override
  String get scanQr => 'Digitalizar QR';

  @override
  String get scanImage => 'Digitalizar Imagem';

  @override
  String get myQr => 'Meu QR';

  @override
  String get shareApp => 'Partilhar App';

  @override
  String get changeTheme => 'Alterar Tema';

  @override
  String get editContact => 'Editar contacto';

  @override
  String get yourContactQr => 'O seu QR de Contacto';

  @override
  String get onboardingMyQrDesc =>
      'Preencha os seus dados de contacto uma vez. Da próxima vez que abrir o Meu QR, o seu QR de contacto será mostrado automaticamente.';

  @override
  String get nameWithAst => 'Nome *';

  @override
  String get phoneWithAst => 'Telefone *';

  @override
  String get company => 'Empresa';

  @override
  String get saveAndGenerate => 'Guardar e Gerar QR';

  @override
  String get noContactQrFound => 'Nenhum QR de contacto encontrado';

  @override
  String get createNow => 'Criar Agora';

  @override
  String get namePhoneRequired => 'Nome e Telefone são obrigatórios';

  @override
  String get privacyPolicy => 'Política de Privacidade e Permissões';

  @override
  String get termsConditions => 'Termos e Condições';

  @override
  String get appInfoSupport => 'Informação da App e Suporte';

  @override
  String get copyright => 'Gerador de Scanner QR e Código de Barras ©️ 2026';

  @override
  String themeSetTo(String mode) {
    return 'Tema definido para $mode';
  }

  @override
  String get systemMode => 'Modo de Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cameraNotWorking =>
      'A câmara não está a funcionar corretamente. Por favor, reinicie a aplicação.';

  @override
  String get noCodeFound => 'Nenhum código encontrado nesta imagem';

  @override
  String failedToScan(String error) {
    return 'Falha ao digitalizar a imagem: $error';
  }

  @override
  String get history => 'Histórico';

  @override
  String get scan => 'Scan';

  @override
  String get created => 'Criados';

  @override
  String get noHistoryFound => 'Nenhum histórico encontrado';

  @override
  String get delete => 'Eliminar';

  @override
  String get yourQrCode => 'O SEU CÓDIGO QR';

  @override
  String get close => 'Fechar';

  @override
  String get url => 'URL';

  @override
  String get phone => 'Telefone';

  @override
  String get email => 'Email';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get contact => 'Contacto';

  @override
  String get calendar => 'Calendário';

  @override
  String get location => 'Localização';

  @override
  String get json => 'JSON';

  @override
  String get content => 'Conteúdo';

  @override
  String get create => 'Criar';

  @override
  String get createQr => 'Criar QR';

  @override
  String get clipboardContent => 'Conteúdo da área de transferência';

  @override
  String get text => 'Texto';

  @override
  String get createQrCode => 'Criar código QR';

  @override
  String get nameRequired => 'Nome é obrigatório';

  @override
  String get phoneRequired => 'Número de telefone válido é obrigatório';

  @override
  String get emailRequired => 'Introduza um email válido';

  @override
  String get linkRequired => 'Link é obrigatório';

  @override
  String get validLinkRequired => 'Introduza um link válido (ex: exemplo.com)';

  @override
  String get ssidRequired => 'SSID é obrigatório';

  @override
  String get passwordRequired =>
      'Password é obrigatória para a encriptação selecionada';

  @override
  String get passwordMinLength => 'Password deve ter pelo menos 8 caracteres';

  @override
  String get fixErrors => 'Corrija os erros acima';

  @override
  String get enterText => 'Por favor, introduza o texto.';

  @override
  String qrSaved(String fileName) {
    return 'QR guardado em $fileName';
  }

  @override
  String get myGeneratedQr => 'O meu código QR gerado';

  @override
  String get scanResult => 'Resultado da digitalização';

  @override
  String get safeScan => 'SCAN SEGURO';

  @override
  String get securityVerified => 'Segurança verificada: Este scan é seguro.';

  @override
  String get website => 'Website';

  @override
  String get phoneNumber => 'Número de telefone';

  @override
  String get emailAddress => 'Endereço de email';

  @override
  String get wifiNetwork => 'Rede Wi-Fi';

  @override
  String get calendarEvent => 'Evento de calendário';

  @override
  String get jsonData => 'Dados JSON';

  @override
  String get book => 'Livro';

  @override
  String get product => 'Produto';

  @override
  String get scannedValue => 'Valor digitalizado';

  @override
  String get brand => 'Marca';

  @override
  String get scannedIsbn => 'ISBN digitalizado';

  @override
  String get scannedProductCode => 'Código de produto digitalizado';

  @override
  String get shopNow => 'Comprar agora';

  @override
  String get webSearch => 'Pesquisa Web';

  @override
  String get share => 'Partilhar';

  @override
  String get copy => 'Copiar';

  @override
  String get open => 'Abrir';

  @override
  String get call => 'Chamar';

  @override
  String get sms => 'SMS';

  @override
  String get copyPass => 'Copiar pass';

  @override
  String get addContact => 'Adicionar contacto';

  @override
  String get addEvent => 'Adicionar evento';

  @override
  String get openMap => 'Abrir mapa';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get wifiPassCopied => 'Password Wi-Fi copiada';

  @override
  String get contactDataCopied =>
      'Dados do contacto copiados – cole na App de Contactos.';

  @override
  String get importContactText =>
      'Importe este contacto para a sua App de Contactos.';

  @override
  String get couldNotOpenContacts =>
      'Não foi possível abrir Contactos – dados copiados.';

  @override
  String get eventDataCopied =>
      'Dados do evento copiados – importe-os no seu aplicativo de calendário.';

  @override
  String get thankYou => 'Obrigado por usar\nQR & Barcode Scanner Generator';

  @override
  String get pickContact => 'Escolher contato';

  @override
  String get failedToCapture => 'Falha ao capturar imagem';

  @override
  String errorSaving(Object error) {
    return 'Erro ao salvar imagem: $error';
  }

  @override
  String errorSharing(Object error) {
    return 'Erro ao compartilhar imagem: $error';
  }

  @override
  String get save => 'Salvar';

  @override
  String get emailWithAst => 'E-mail *';

  @override
  String get designation => 'Cargo';

  @override
  String get address => 'Endereço';

  @override
  String get urlNameWithAst => 'Nome do URL *';

  @override
  String get urlLinkWithAst => 'Link do URL *';

  @override
  String get wifiNameWithAst => 'Nome do WiFi (SSID) *';

  @override
  String get encryptionTypeWithAst => 'Tipo de Criptografia *';

  @override
  String get password => 'Senha';

  @override
  String get noPasswordRequired => 'Nenhuma senha necessária';

  @override
  String get phoneNumberWithAst => 'Número de Telefone *';

  @override
  String shareMessage(Object url) {
    return 'Estou usando o aplicativo QR & Barcode Scanner Generator, o leitor de QR e Código de Barras rápido e seguro. Experimente agora! $url';
  }

  @override
  String get cameraPermissionRequired =>
      'A permissão da câmera é necessária para escanear códigos.';

  @override
  String get openSettings => 'Abrir Configurações';

  @override
  String get permissionsTitle => 'Permissões';

  @override
  String get permissionsSubtitle => 'Gerenciar permissões do aplicativo';

  @override
  String get permissionCamera => 'Câmera';

  @override
  String get permissionGallery => 'Galeria';

  @override
  String get permissionCameraDesc =>
      'Necessário para escanear QR e códigos de barras';

  @override
  String get permissionGalleryDesc =>
      'Necessário para selecionar imagens da galeria';

  @override
  String get statusGranted => 'Concedido';

  @override
  String get statusDenied => 'Negado';

  @override
  String get downloadSuccess => 'Download Efetuado com Sucesso';

  @override
  String get legalInfo => 'Informação Legal';

  @override
  String get download => 'Download';

  @override
  String get edit => 'Editar';

  @override
  String get backToMain => 'Voltar ao Início';

  @override
  String get ok => 'OK';

  @override
  String get scanDetail => 'Detalhes da Digitalização';

  @override
  String get scanResultTitle => 'Resultado da Digitalização';

  @override
  String get qrCodeReady => 'Código QR Pronto!';

  @override
  String get qrGeneratedSaved =>
      'Seu código QR foi gerado e salvo no histórico.';

  @override
  String get qrSavedToGallery => 'Código QR salvo na galeria!';

  @override
  String sharePromoText(String url) {
    return 'Digitalize este código QR gerado pelo SecureScan: $url';
  }
}
