import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/data/contacts_api.dart';
import 'package:salesroot/features/contacts/data/contacts_repository.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/company_detail.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

/// Contacts and companies over `/contacts` and `/companies`. The server
/// refuses a duplicate number with a 422 (`V-003` for a contact, `V-026` for
/// a company); it is rethrown as a 409 so the forms can offer the match.
class ApiContactsRepository implements ContactsRepository {
  ApiContactsRepository(this._api);

  static const _duplicateCodes = {'V-003', 'V-026'};
  static const _scanSize = 200;
  static const _scanPages = 25;

  final ContactsApi _api;

  @override
  Future<PageResult<Contact>> contacts(ContactQuery query) async {
    final json = await apiRequest(
      'Contact list',
      () => _api.contacts(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), Contact.fromJson);
  }

  @override
  Future<ContactDetail> contact(String id) async => ContactDetail.fromJson(
    jsonMap(await apiRequest('Contact $id', () => _api.contact(id))),
  );

  @override
  Future<Contact> createContact(ContactInput input) =>
      _contact('Contact create', () => _api.createContact(input.toJson()));

  @override
  Future<Contact> editContact(String id, ContactInput input) => _contact(
    'Contact save',
    () => _api.editContact(id, input.toJson(edit: true)),
  );

  @override
  Future<void> deleteContact(String id) =>
      apiRequest('Contact delete', () => _api.deleteContact(id));

  @override
  Future<List<DuplicateMatch>> contactDuplicates(
    List<String> phones, {
    String? excludeId,
  }) async {
    final keys = {for (final phone in phones) BdPhone.key(phone)}
      ..removeWhere((key) => key.length < 10);
    final found = <String, Contact>{};
    for (final key in keys) {
      final page = await contacts(ContactQuery(search: '0$key'));
      for (final contact in page.items) {
        if (contact.id == excludeId) continue;
        if (contact.mobiles.any((phone) => BdPhone.key(phone) == key)) {
          found[contact.id] = contact;
        }
      }
    }
    return [
      for (final contact in found.values)
        DuplicateMatch(
          id: contact.id,
          name: contact.name,
          subtitle: contact.companyName,
          phone: contact.phone,
        ),
    ];
  }

  @override
  Future<Map<String, String>> matchPhones(List<String> phones) async {
    final saved = <String, String>{};
    for (var page = 1; page <= _scanPages; page++) {
      final result = await contacts(ContactQuery(page: page, size: _scanSize));
      for (final contact in result.items) {
        for (final phone in contact.mobiles) {
          saved.putIfAbsent(BdPhone.key(phone), () => contact.id);
        }
      }
      if (result.items.isEmpty || page * _scanSize >= result.totalCount) {
        break;
      }
    }
    return {for (final phone in phones) phone: ?saved[BdPhone.key(phone)]};
  }

  @override
  Future<int> importContacts(List<ContactInput> inputs) async {
    var added = 0;
    for (final input in inputs) {
      try {
        await createContact(input);
        added++;
      } on ApiFailure catch (failure) {
        if (!failure.isConflict && !failure.isValidation) rethrow;
      }
    }
    return added;
  }

  @override
  Future<PageResult<Company>> companies(CompanyQuery query) async {
    final json = await apiRequest(
      'Company list',
      () => _api.companies(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), Company.fromJson);
  }

  @override
  Future<CompanyDetail> company(String id) async => CompanyDetail.fromJson(
    jsonMap(await apiRequest('Company $id', () => _api.company(id))),
  );

  @override
  Future<ContactsPack> pack() async => ContactsPack.fromWorkspace(
    jsonMap(await apiRequest('Workspace', _api.workspace)),
  );

  @override
  Future<Company> createCompany(
    CompanyInput input, {
    bool allowDuplicate = false,
  }) => _company(
    'Company create',
    () => _api.createCompany(_companyBody(input, allowDuplicate)),
  );

  @override
  Future<Company> editCompany(
    String id,
    CompanyInput input, {
    bool allowDuplicate = false,
  }) => _company(
    'Company save',
    () => _api.editCompany(id, _companyBody(input, allowDuplicate, edit: true)),
  );

  @override
  Future<void> deleteCompany(String id) =>
      apiRequest('Company delete', () => _api.deleteCompany(id));

  @override
  Future<List<DuplicateMatch>> companyDuplicates({
    required String name,
    String? phone,
    String? excludeId,
  }) async {
    final key = phone == null ? '' : BdPhone.key(phone);
    final byPhone = key.length >= 10;
    final page = await companies(
      CompanyQuery(search: byPhone ? '0$key' : name),
    );
    final wanted = _normalise(name);
    return [
      for (final company in page.items)
        if (company.id != excludeId &&
            (byPhone
                ? BdPhone.key(company.contactNumber ?? '') == key
                : _normalise(company.name) == wanted))
          DuplicateMatch(
            id: company.id,
            name: company.name,
            subtitle: company.area,
            phone: company.contactNumber,
            isCompany: true,
          ),
    ];
  }

  static Map<String, dynamic> _companyBody(
    CompanyInput input,
    bool allowDuplicate, {
    bool edit = false,
  }) => {
    ...input.toJson(edit: edit),
    if (allowDuplicate) 'allowDuplicate': true,
  };

  static String _normalise(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9ঀ-৿]'), '');

  Future<Contact> _contact(
    String label,
    Future<dynamic> Function() request,
  ) async => Contact.fromJson(jsonMap(await _write(label, request)));

  Future<Company> _company(
    String label,
    Future<dynamic> Function() request,
  ) async => Company.fromJson(jsonMap(await _write(label, request)));

  Future<dynamic> _write(
    String label,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await apiRequest(label, request);
    } on ApiFailure catch (failure) {
      if (!_duplicateCodes.contains(failure.code)) rethrow;
      throw ApiFailure(
        409,
        failure.message,
        fieldErrors: failure.fieldErrors,
        code: failure.code,
      );
    }
  }
}
