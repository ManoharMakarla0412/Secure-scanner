enum QrType {
  text,
  url,
  wifi,
  contact,
  phone,
  email,
  calendar,
  location,
  json,
  product;

  String get name => toString().split('.').last;

  static QrType fromString(String value) {
    return QrType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => QrType.text,
    );
  }
}
