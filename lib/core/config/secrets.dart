class Secrets {
  /// Use --dart-define=BARCODE_LOOKUP_API_KEY=your_key to inject at build time.
  static const String barcodeLookupApiKey = String.fromEnvironment(
    'BARCODE_LOOKUP_API_KEY',
    defaultValue: '',
  );

  /// Use --dart-define=SAFE_BROWSING_API_KEY=your_key to inject at build time.
  static const String safeBrowsingApiKey = String.fromEnvironment(
    'SAFE_BROWSING_API_KEY',
    defaultValue: '',
  );
}
