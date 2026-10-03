import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

/// Contacts and the companies they work at.
abstract interface class ContactsRepository {
  /// A page of contacts with a `GroupCounts` facet.
  Future<PageResult<Contact>> contacts(ContactQuery query);

  Future<Contact> contact(int id);

  /// Throws a 409 when the mobile number is already saved, unless
  /// [allowDuplicate].
  Future<Contact> createContact(
    ContactInput input, {
    bool allowDuplicate = false,
  });

  Future<Contact> editContact(
    int id,
    ContactInput input, {
    bool allowDuplicate = false,
  });

  Future<void> deleteContact(int id);

  /// Saved contacts sharing a mobile number in [phones].
  Future<List<DuplicateMatch>> contactDuplicates(
    List<String> phones, {
    int? excludeId,
  });

  Future<List<LinkedLead>> contactLeads(int id);

  Future<List<ContactActivity>> contactActivity(int id);

  /// The saved contact id for each phone-book number that already exists.
  Future<Map<String, int>> matchPhones(List<String> phones);

  /// Saves the picked phone-book entries; returns how many were added.
  Future<int> importContacts(List<ContactInput> inputs);

  /// A page of companies with a `Counts` facet (`All`, `Customers`).
  Future<PageResult<Company>> companies(CompanyQuery query);

  Future<Company> company(int id);

  Future<CompanyLookups> companyLookups();

  /// Throws a 409 when the name or number is already saved, unless
  /// [allowDuplicate].
  Future<Company> createCompany(
    CompanyInput input, {
    bool allowDuplicate = false,
  });

  Future<Company> editCompany(
    int id,
    CompanyInput input, {
    bool allowDuplicate = false,
  });

  /// Throws a 409 while the company still has leads.
  Future<void> deleteCompany(int id);

  Future<List<DuplicateMatch>> companyDuplicates({
    required String name,
    String? phone,
    int? excludeId,
  });

  /// The concern persons, primary first.
  Future<List<Contact>> companyContacts(int companyId);

  Future<List<LinkedLead>> companyLeads(int companyId);

  Future<void> setPrimaryContact(int companyId, int contactId);

  /// Takes the contact off the company; the contact stays saved.
  Future<void> detachContact(int contactId);
}
