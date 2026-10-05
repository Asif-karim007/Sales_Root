/// One person in the phone's address book.
class PhoneBookEntry {
  const PhoneBookEntry({
    required this.deviceId,
    required this.name,
    required this.phones,
    this.email,
    this.company,
  });

  final String deviceId;
  final String name;
  final List<String> phones;
  final String? email;
  final String? company;
}

/// A phone-book entry with the saved contact it already matches, if any.
class ImportCandidate {
  const ImportCandidate({required this.entry, this.existingContactId});

  final PhoneBookEntry entry;
  final String? existingContactId;

  bool get exists => existingContactId != null;
}
