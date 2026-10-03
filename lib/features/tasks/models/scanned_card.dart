/// The fields a card scan reads, by the keys the reader returns.
enum CardField { contactName, designation, companyName, phone, email, address }

/// What the reader found on a visiting card; blank where nothing was printed.
/// [unsure] lists the fields it could not read clearly.
class ScannedCard {
  const ScannedCard({
    this.contactName = '',
    this.designation = '',
    this.companyName = '',
    this.department = '',
    this.phones = const [],
    this.emails = const [],
    this.website = '',
    this.address = '',
    this.unsure = const {},
  });

  final String contactName;
  final String designation;
  final String companyName;
  final String department;
  final List<String> phones;
  final List<String> emails;
  final String website;
  final String address;
  final Set<CardField> unsure;

  String get phone => phones.isEmpty ? '' : phones.first;
  String get email => emails.isEmpty ? '' : emails.first;

  bool get isEmpty =>
      contactName.isEmpty &&
      companyName.isEmpty &&
      phones.isEmpty &&
      emails.isEmpty &&
      address.isEmpty;

  /// How many of the review fields came back filled.
  int get filledCount => [
    contactName,
    designation,
    companyName,
    phone,
    email,
    address,
  ].where((value) => value.isNotEmpty).length;

  String valueOf(CardField field) => switch (field) {
    CardField.contactName => contactName,
    CardField.designation => designation,
    CardField.companyName => companyName,
    CardField.phone => phone,
    CardField.email => email,
    CardField.address => address,
  };

  ScannedCard edited(Map<CardField, String> values) {
    String pick(CardField field) => (values[field] ?? valueOf(field)).trim();
    final phone = pick(CardField.phone);
    final email = pick(CardField.email);
    return ScannedCard(
      contactName: pick(CardField.contactName),
      designation: pick(CardField.designation),
      companyName: pick(CardField.companyName),
      department: department,
      phones: [if (phone.isNotEmpty) phone, ...phones.skip(1)],
      emails: [if (email.isNotEmpty) email, ...emails.skip(1)],
      website: website,
      address: pick(CardField.address),
      unsure: unsure,
    );
  }

  factory ScannedCard.fromJson(Map<String, dynamic> json) => ScannedCard(
    contactName: _text(json['contactName']),
    designation: _text(json['designation']),
    companyName: _text(json['companyName']),
    department: _text(json['department']),
    phones: _texts(json['phones']),
    emails: _texts(json['emails']),
    website: _text(json['website']),
    address: _text(json['address']),
    unsure: {
      for (final name in _texts(json['unclearFields']))
        for (final field in CardField.values)
          if (field.name == name || '${field.name}s' == name) field,
    },
  );

  static String _text(Object? value) => value is String ? value.trim() : '';

  static List<String> _texts(Object? value) => value is List
      ? value.map(_text).where((text) => text.isNotEmpty).toList()
      : const [];
}

enum ScanMode { card, qr }

/// What a scan produced: a contact to review, or a QR code that holds
/// something else.
sealed class ScanResult {
  const ScanResult();
}

class CardScanResult extends ScanResult {
  const CardScanResult(this.card);

  final ScannedCard card;
}

class QrScanResult extends ScanResult {
  const QrScanResult(this.payload);

  final String payload;

  Uri? get link {
    final uri = Uri.tryParse(payload.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return uri;
  }

  /// A contact QR (vCard or MECARD) reads as a card; anything else stays a
  /// QR result.
  static ScanResult parse(String payload) {
    final text = payload.trim();
    final upper = text.toUpperCase();
    if (upper.startsWith('BEGIN:VCARD')) return CardScanResult(_vCard(text));
    if (upper.startsWith('MECARD:')) return CardScanResult(_meCard(text));
    return QrScanResult(text);
  }

  static ScannedCard _vCard(String text) {
    final fields = <String, List<String>>{};
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final key = line.substring(0, colon).split(';').first.toUpperCase();
      final value = line.substring(colon + 1).trim();
      if (value.isEmpty) continue;
      fields.putIfAbsent(key, () => []).add(value);
    }
    String first(String key) => fields[key]?.first ?? '';
    return ScannedCard(
      contactName: first('FN').isNotEmpty
          ? first('FN')
          : first('N').split(';').where((p) => p.isNotEmpty).join(' '),
      designation: first('TITLE'),
      companyName: first('ORG').replaceAll(';', ' ').trim(),
      phones: fields['TEL'] ?? const [],
      emails: fields['EMAIL'] ?? const [],
      website: first('URL'),
      address: first('ADR').split(';').where((p) => p.isNotEmpty).join(', '),
    );
  }

  static ScannedCard _meCard(String text) {
    final fields = <String, List<String>>{};
    for (final part in text.substring('MECARD:'.length).split(';')) {
      final colon = part.indexOf(':');
      if (colon <= 0) continue;
      fields
          .putIfAbsent(part.substring(0, colon).toUpperCase(), () => [])
          .add(part.substring(colon + 1).trim());
    }
    String first(String key) => fields[key]?.first ?? '';
    final name = first('N').split(',').reversed.join(' ').trim();
    return ScannedCard(
      contactName: name,
      designation: first('TITLE'),
      companyName: first('ORG'),
      phones: fields['TEL'] ?? const [],
      emails: fields['EMAIL'] ?? const [],
      website: first('URL'),
      address: first('ADR'),
    );
  }
}
