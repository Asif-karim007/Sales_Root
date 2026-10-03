import 'package:salesroot/features/contacts/models/phone_book_entry.dart';

/// The phone's address book. The real source needs a contacts plugin such as
/// `flutter_contacts`; until then [FakeDeviceContactsSource] stands in.
abstract interface class DeviceContactsSource {
  /// Asks for (or checks) read access; false when the user refused.
  Future<bool> requestAccess();

  Future<List<PhoneBookEntry>> entries();
}
