import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/features/contacts/data/device_contacts_source.dart';
import 'package:salesroot/features/contacts/models/phone_book_entry.dart';

const List<(String, String, String?)> _phoneBook = [
  ('Rahima Begum', '01912 345 678', null),
  ('Rahman Hardware', '01711 987 654', 'Rahman Hardware'),
  ('Rashed Sarker', '01611 444 555', null),
  ('Ahsan Habib (Electrician)', '01819-332211', null),
  ('Bilkis Ara', '+880 1552 908 771', null),
  ('Delowar Contractor', '01733 120 455', null),
  ('Faisal Solar Dealer', '01977-654321', 'Faisal Enterprise'),
  ('Hasina Mam Office', '02-9881234', null),
  ('Imtiaz Bhai', '01821 667 890', null),
  ('Jahanara Textile', '01716 554 433', 'Jahanara Textile'),
  ('Khairul Islam', '01613 222 101', null),
  ('Lutfor Rahman MD', '01714 998 877', 'Lutfor Agro'),
  ('Mamun Generator', '01930 121 314', null),
  ('Nazrul Mistri', '01558 707 070', null),
  ('Obaidul Kader', '01815 600 700', null),
  ('Parvin Sultana', '01711 456 123', null),
  ('Quamrul Hasan', '01674 333 999', 'Hasan Builders'),
  ('Rokon Uddin', '01920 404 505', null),
  ('Sumon Accounts', '01712 101 202', null),
  ('Tania Akter', '01687 889 900', null),
];

/// A realistic phone book. A few entries are numbers already saved as
/// contacts, written the way a phone stores them, so the import can mark them.
class FakeDeviceContactsSource implements DeviceContactsSource {
  FakeDeviceContactsSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<bool> requestAccess() =>
      _backend.network('Device contacts access', () => true);

  @override
  Future<List<PhoneBookEntry>> entries() =>
      _backend.network('Device contacts', () {
        final graph = _backend.graph;
        final saved = [
          for (final contact in graph.contacts.take(40))
            if (contact.id % 9 == 1) contact,
        ];
        return [
          for (final (i, (name, phone, company)) in _phoneBook.indexed)
            PhoneBookEntry(
              deviceId: 'pb-$i',
              name: name,
              phones: [phone],
              company: company,
            ),
          for (final contact in saved)
            PhoneBookEntry(
              deviceId: 'pb-saved-${contact.id}',
              name: contact.name,
              phones: ['0${contact.phone.substring(4)}'],
              email: contact.email,
            ),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
}
