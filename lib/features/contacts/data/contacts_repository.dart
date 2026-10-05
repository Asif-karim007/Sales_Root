import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/company_detail.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

/// Contacts and the companies they work at.
abstract interface class ContactsRepository {
  Future<PageResult<Contact>> contacts(ContactQuery query);

  Future<ContactDetail> contact(String id);

  /// Throws a 409 when the mobile number is already saved.
  Future<Contact> createContact(ContactInput input);

  /// Throws a 409 when the mobile number is already saved.
  Future<Contact> editContact(String id, ContactInput input);

  Future<void> deleteContact(String id);

  /// Saved contacts sharing a mobile number in [phones].
  Future<List<DuplicateMatch>> contactDuplicates(
    List<String> phones, {
    String? excludeId,
  });

  /// The saved contact id for each phone-book number that already exists.
  Future<Map<String, String>> matchPhones(List<String> phones);

  /// Saves the picked phone-book entries; returns how many were added.
  Future<int> importContacts(List<ContactInput> inputs);

  Future<PageResult<Company>> companies(CompanyQuery query);

  Future<CompanyDetail> company(String id);

  /// The workspace's names for companies and contacts and its company fields.
  Future<ContactsPack> pack();

  /// Throws a 409 when the number is already saved, unless [allowDuplicate].
  Future<Company> createCompany(
    CompanyInput input, {
    bool allowDuplicate = false,
  });

  /// Throws a 409 when the number is already saved, unless [allowDuplicate].
  Future<Company> editCompany(
    String id,
    CompanyInput input, {
    bool allowDuplicate = false,
  });

  Future<void> deleteCompany(String id);

  Future<List<DuplicateMatch>> companyDuplicates({
    required String name,
    String? phone,
    String? excludeId,
  });
}
