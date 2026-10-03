import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/contacts/data/contacts_fixtures.dart';
import 'package:salesroot/features/contacts/data/contacts_repository.dart';
import 'package:salesroot/features/contacts/data/customer_fixtures.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

const _contactEditable = {
  'Name',
  'Designation',
  'ProspectId',
  'Mobiles',
  'Emails',
  'Address',
  'DateOfBirth',
  'Note',
  'Tags',
  'Source',
};

const _companyEditable = {
  'Name',
  'IndustryType',
  'ZoneName',
  'ContactNumber',
  'Email',
  'WebsiteProspect',
  'Addresses',
  'Latitude',
  'Longitude',
  'Note',
  'Tags',
  'CreditLimit',
  'CreditDays',
};

class FakeContactsRepository implements ContactsRepository {
  FakeContactsRepository(this._backend);

  final FakeBackend _backend;
  final Map<int, CustomerLedger> _ledgers = {};

  SeedGraph get _graph => _backend.graph;
  FakeTable get _contacts => _backend.table('contacts', contactFixtures);
  FakeTable get _companies => _backend.table('companies', companyFixtures);
  FakeTable get _activity =>
      _backend.table('contact_activity', contactActivityFixtures);

  Map<String, dynamic> get _me {
    final me = _graph.me;
    return {'Id': me.id, 'Name': me.name};
  }

  bool _owns(Map<String, dynamic> row, String key) =>
      _backend.role != WorkspaceRole.member ||
      jsonInt((row[key] as Map<String, dynamic>?)?['Id']) == _backend.meId;

  CustomerLedger _ledger(Map<String, dynamic> company) {
    final id = company['Id'] as int;
    return _ledgers.putIfAbsent(
      id,
      () => CustomerLedger.of(_graph, id, company['Name'] as String),
    );
  }

  Map<String, dynamic> _contactJson(Map<String, dynamic> row) {
    final companyId = jsonInt(row['ProspectId']);
    final company = companyId == null ? null : _companies.byIdOrNull(companyId);
    return {
      ...row,
      if (company != null) 'ProspectName': company['Name'],
      if (company != null) 'ProspectIsClient': _ledger(company).isClient,
      'CanEdit': true,
      'CanDelete': _owns(row, 'CreatedBy'),
    };
  }

  Map<String, dynamic> _companyJson(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> people,
  ) {
    final id = row['Id'] as int;
    final ledger = _ledger(row);
    final leads = _graph.leads.where((lead) => lead.companyId == id);
    final primary = people.where((p) => p['IsPrimary'] == true).firstOrNull;
    final mobiles = jsonStrings(primary?['Mobiles']);
    return {
      ...row,
      'IndustryTypeBn': industryBn(row['IndustryType'] as String?),
      'ZoneNameBn': areaBn(row['ZoneName'] as String?),
      'IsClient': ledger.isClient,
      'ClientSince': jsonUtc(ledger.clientSince),
      'TotalSales': ledger.totalSales,
      'Outstanding': ledger.outstanding,
      'ContactCount': people.length,
      if (primary != null)
        'PrimaryContact': {
          'Id': primary['Id'],
          'Name': primary['Name'],
          'Designation': primary['Designation'],
          'Mobile': mobiles.isEmpty ? null : mobiles.first,
        },
      'Counts': {
        'Leads': leads.length,
        'OpenLeads': leads.where((lead) => lead.isOpen).length,
      },
      'CanEdit': true,
      'CanDelete': _owns(row, 'AssignedTo'),
    }..removeWhere((_, value) => value == null);
  }

  Map<int, List<Map<String, dynamic>>> _peopleByCompany() {
    final byCompany = <int, List<Map<String, dynamic>>>{};
    for (final row in _contacts.rows) {
      final companyId = jsonInt(row['ProspectId']);
      if (companyId == null) continue;
      byCompany.putIfAbsent(companyId, () => []).add(row);
    }
    return byCompany;
  }

  static String _letterOf(String name) {
    final first = name.trim().isEmpty ? '#' : name.trim()[0].toUpperCase();
    return RegExp('[A-Z]').hasMatch(first) ? first : '#';
  }

  static bool _phoneMatches(Map<String, dynamic> row, String query) {
    final digits = query.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return false;
    return jsonStrings(
      row['Mobiles'],
    ).any((phone) => '0${BdPhone.key(phone)}'.contains(digits));
  }

  List<String> _validMobiles(Map<String, dynamic> body) {
    final raw = jsonStrings(body['Mobiles']);
    if (raw.isEmpty) {
      throw const ApiFailure(
        400,
        'Mobile number is required',
        fieldErrors: {'Mobiles': 'Mobile number is required'},
      );
    }
    final mobiles = <String>[];
    for (final phone in raw) {
      final mobile = BdPhone.mobile(phone);
      if (mobile == null) {
        throw const ApiFailure(
          400,
          'Enter a valid mobile number',
          fieldErrors: {'Mobiles': 'Enter a valid mobile number'},
        );
      }
      mobiles.add(mobile);
    }
    return mobiles;
  }

  List<DuplicateMatch> _contactMatches(List<String> phones, int? excludeId) {
    final keys = {for (final phone in phones) BdPhone.key(phone)};
    return [
      for (final row in _contacts.rows)
        if (row['Id'] != excludeId &&
            jsonStrings(
              row['Mobiles'],
            ).any((phone) => keys.contains(BdPhone.key(phone))))
          DuplicateMatch.fromJson(_matchOfContact(row)),
    ];
  }

  Map<String, dynamic> _matchOfContact(Map<String, dynamic> row) {
    final json = _contactJson(row);
    final mobiles = jsonStrings(row['Mobiles']);
    return {
      'Id': row['Id'],
      'Name': row['Name'],
      'Subtitle': [
        json['ProspectName'],
        row['Designation'],
      ].whereType<String>().join(' · '),
      'Phone': mobiles.isEmpty ? null : mobiles.first,
      'Kind': 'Contact',
    };
  }

  void _promoteNextPrimary(int companyId) {
    final rows = _contacts.rows.where(
      (row) => jsonInt(row['ProspectId']) == companyId,
    );
    if (rows.isEmpty || rows.any((row) => row['IsPrimary'] == true)) return;
    _contacts.update(rows.first['Id'] as int, {'IsPrimary': true});
  }

  @override
  Future<PageResult<Contact>> contacts(
    ContactQuery query,
  ) => _backend.run('Contacts list', () {
    final recent = _graph.daysAgo(30);
    bool inGroup(Map<String, dynamic> row, ContactGroup group) =>
        switch (group) {
          ContactGroup.all => true,
          ContactGroup.primary => row['IsPrimary'] == true,
          ContactGroup.independent => row['ProspectId'] == null,
          ContactGroup.recent =>
            jsonDate(row['CreatedOn'])?.isAfter(recent) ?? false,
        };

    final searched = [
      for (final row in _contacts.rows.map(_contactJson))
        if (fakeMatches(row, query.search, [
              'Name',
              'ProspectName',
              'Designation',
            ]) ||
            _phoneMatches(row, query.search))
          row,
    ];
    final letter = query.letter;
    final rows =
        searched
            .where((row) => inGroup(row, query.group))
            .where(
              (row) =>
                  letter == null || _letterOf(row['Name'] as String) == letter,
            )
            .toList()
          ..sort(
            query.group == ContactGroup.recent
                ? (a, b) => '${b['CreatedOn']}'.compareTo('${a['CreatedOn']}')
                : (a, b) => '${a['Name']}'.toLowerCase().compareTo(
                    '${b['Name']}'.toLowerCase(),
                  ),
          );
    return PageResult.fromJson(
      fakePage(
        rows,
        page: query.page,
        extra: {
          'GroupCounts': {
            for (final group in ContactGroup.values)
              group.wire: searched.where((row) => inGroup(row, group)).length,
          },
        },
      ),
      Contact.fromJson,
    );
  }, module: AppModule.contact);

  @override
  Future<Contact> contact(int id) => _backend.run(
    'Contact detail',
    () => Contact.fromJson(_contactJson(_contacts.byId(id))),
    module: AppModule.contact,
  );

  @override
  Future<Contact> createContact(
    ContactInput input, {
    bool allowDuplicate = false,
  }) => _backend.run(
    'Contact create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Name']);
      final mobiles = _validMobiles(body);
      if (!allowDuplicate && _contactMatches(mobiles, null).isNotEmpty) {
        throw const ApiFailure(409, 'This number is already saved');
      }
      final companyId = jsonInt(body['ProspectId']);
      if (companyId != null) _companies.byId(companyId);
      final hasPrimary = _contacts.rows.any(
        (row) =>
            companyId != null &&
            jsonInt(row['ProspectId']) == companyId &&
            row['IsPrimary'] == true,
      );
      final row = _contacts.insert({
        ...body,
        'Mobiles': mobiles,
        'IsPrimary': companyId != null && !hasPrimary,
        'CreatedOn': jsonUtc(DateTime.now()),
        'CreatedBy': _me,
      });
      return Contact.fromJson(_contactJson(row));
    },
    module: AppModule.contact,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<Contact> editContact(
    int id,
    ContactInput input, {
    bool allowDuplicate = false,
  }) => _backend.run(
    'Contact edit',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Name']);
      final mobiles = _validMobiles(body);
      if (!allowDuplicate && _contactMatches(mobiles, id).isNotEmpty) {
        throw const ApiFailure(409, 'This number is already saved');
      }
      final row = _contacts.byId(id);
      final before = jsonInt(row['ProspectId']);
      final after = jsonInt(body['ProspectId']);
      if (after != null) _companies.byId(after);
      row
        ..removeWhere((key, _) => _contactEditable.contains(key))
        ..addAll({...body, 'Mobiles': mobiles});
      if (before != after) {
        row['IsPrimary'] = false;
        if (before != null) _promoteNextPrimary(before);
        if (after != null) _promoteNextPrimary(after);
      }
      return Contact.fromJson(_contactJson(row));
    },
    module: AppModule.contact,
    right: ModuleRight.edit,
  );

  @override
  Future<void> deleteContact(int id) => _backend.run(
    'Contact delete',
    () {
      final row = _contacts.byId(id);
      if (!_owns(row, 'CreatedBy')) {
        throw const ApiFailure(403, 'Only the person who added it can delete');
      }
      final companyId = jsonInt(row['ProspectId']);
      _contacts.delete(id);
      if (companyId != null) _promoteNextPrimary(companyId);
    },
    module: AppModule.contact,
    right: ModuleRight.delete,
  );

  @override
  Future<List<DuplicateMatch>> contactDuplicates(
    List<String> phones, {
    int? excludeId,
  }) => _backend.run(
    'Contact duplicates',
    () => _contactMatches(phones, excludeId),
    module: AppModule.contact,
  );

  @override
  Future<List<LinkedLead>> contactLeads(int id) =>
      _backend.run('Contact leads', () {
        _contacts.byId(id);
        return _leads(_graph.leads.where((lead) => lead.contactId == id));
      }, module: AppModule.contact);

  List<LinkedLead> _leads(Iterable<SeedLead> leads) =>
      [
        for (final lead in leads)
          LinkedLead.fromJson(linkedLeadJson(_graph, lead)),
      ]..sort((a, b) {
        if (a.status != b.status) {
          return a.status.index.compareTo(b.status.index);
        }
        return (b.updatedOn ?? DateTime(2000)).compareTo(
          a.updatedOn ?? DateTime(2000),
        );
      });

  @override
  Future<List<ContactActivity>> contactActivity(int id) =>
      _backend.run('Contact activity', () {
        _contacts.byId(id);
        return [
          for (final row in _activity.rows)
            if (row['ContactId'] == id) ContactActivity.fromJson(row),
        ]..sort((a, b) => b.on.compareTo(a.on));
      }, module: AppModule.contact);

  @override
  Future<Map<String, int>> matchPhones(List<String> phones) =>
      _backend.run('Contact phone match', () {
        final byKey = <String, int>{
          for (final row in _contacts.rows)
            for (final phone in jsonStrings(row['Mobiles']))
              BdPhone.key(phone): row['Id'] as int,
        };
        return {for (final phone in phones) phone: ?byKey[BdPhone.key(phone)]};
      }, module: AppModule.contact);

  @override
  Future<int> importContacts(List<ContactInput> inputs) => _backend.run(
    'Contact import',
    () {
      var added = 0;
      for (final input in inputs) {
        final body = input.toJson();
        fakeRequire(body, ['Name']);
        final mobiles = [
          for (final phone in input.mobiles) ?BdPhone.any(phone),
        ];
        if (mobiles.isEmpty || _contactMatches(mobiles, null).isNotEmpty) {
          continue;
        }
        _contacts.insert({
          ...body,
          'Mobiles': mobiles,
          'IsPrimary': false,
          'Source': 'Phone book',
          'CreatedOn': jsonUtc(DateTime.now()),
          'CreatedBy': _me,
        });
        added++;
      }
      return added;
    },
    module: AppModule.contact,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<PageResult<Company>> companies(CompanyQuery query) =>
      _backend.run('Companies list', () {
        final people = _peopleByCompany();
        final filtered = [
          for (final row in _companies.rows)
            if (fakeMatches(row, query.search, [
                  'Name',
                  'ZoneName',
                  'IndustryType',
                  'ContactNumber',
                ]) &&
                (query.industry == null ||
                    row['IndustryType'] == query.industry) &&
                (query.area == null || row['ZoneName'] == query.area))
              _companyJson(row, people[row['Id']] ?? const []),
        ];
        final customers = filtered.where((row) => row['IsClient'] == true);
        final rows = query.customersOnly ? customers.toList() : filtered;
        return PageResult.fromJson(
          fakePage(
            rows,
            page: query.page,
            extra: {
              'Counts': {'All': filtered.length, 'Customers': customers.length},
            },
          ),
          Company.fromJson,
        );
      }, module: AppModule.company);

  @override
  Future<Company> company(int id) => _backend.run(
    'Company detail',
    () => Company.fromJson(
      _companyJson(_companies.byId(id), _peopleByCompany()[id] ?? const []),
    ),
    module: AppModule.company,
  );

  @override
  Future<CompanyLookups> companyLookups() => _backend.run(
    'Company lookups',
    () => CompanyLookups.fromJson(companyLookupsFixture()),
    module: AppModule.company,
  );

  Map<String, dynamic> _validCompany(CompanyInput input) {
    final body = input.toJson();
    fakeRequire(body, ['Name']);
    final phone = body['ContactNumber'] as String?;
    if (phone != null) {
      final valid = BdPhone.any(phone);
      if (valid == null) {
        throw const ApiFailure(
          400,
          'Enter a valid phone number',
          fieldErrors: {'ContactNumber': 'Enter a valid phone number'},
        );
      }
      body['ContactNumber'] = valid;
    }
    return body;
  }

  List<DuplicateMatch> _companyMatches(
    String name,
    String? phone,
    int? excludeId,
  ) {
    final key = name.trim().toLowerCase();
    final phoneKey = phone == null ? null : BdPhone.key(phone);
    return [
      for (final row in _companies.rows)
        if (row['Id'] != excludeId &&
            ('${row['Name']}'.trim().toLowerCase() == key ||
                (phoneKey != null &&
                    row['ContactNumber'] != null &&
                    BdPhone.key('${row['ContactNumber']}') == phoneKey)))
          DuplicateMatch(
            id: row['Id'] as int,
            name: row['Name'] as String,
            subtitle: [
              row['IndustryType'],
              row['ZoneName'],
            ].whereType<String>().join(' · '),
            phone: row['ContactNumber'] as String?,
            isCompany: true,
          ),
    ];
  }

  @override
  Future<Company> createCompany(
    CompanyInput input, {
    bool allowDuplicate = false,
  }) => _backend.run(
    'Company create',
    () {
      final body = _validCompany(input);
      if (!allowDuplicate &&
          _companyMatches(
            body['Name'] as String,
            body['ContactNumber'] as String?,
            null,
          ).isNotEmpty) {
        throw const ApiFailure(409, 'This company is already saved');
      }
      final id = _companies.nextId();
      final row = _companies.insert({
        ...body,
        'Id': id,
        'Code': 'PR-${id.toString().padLeft(4, '0')}',
        'CreatedOn': jsonUtc(DateTime.now()),
        'AssignedTo': _me,
      });
      return Company.fromJson(_companyJson(row, const []));
    },
    module: AppModule.company,
    right: ModuleRight.add,
    quota: QuotaKind.records,
  );

  @override
  Future<Company> editCompany(
    int id,
    CompanyInput input, {
    bool allowDuplicate = false,
  }) => _backend.run(
    'Company edit',
    () {
      final body = _validCompany(input);
      if (!allowDuplicate &&
          _companyMatches(
            body['Name'] as String,
            body['ContactNumber'] as String?,
            id,
          ).isNotEmpty) {
        throw const ApiFailure(409, 'This company is already saved');
      }
      final row = _companies.byId(id)
        ..removeWhere((key, _) => _companyEditable.contains(key))
        ..addAll(body);
      _ledgers.remove(id);
      return Company.fromJson(
        _companyJson(row, _peopleByCompany()[id] ?? const []),
      );
    },
    module: AppModule.company,
    right: ModuleRight.edit,
  );

  @override
  Future<void> deleteCompany(int id) => _backend.run(
    'Company delete',
    () {
      final row = _companies.byId(id);
      if (!_owns(row, 'AssignedTo')) {
        throw const ApiFailure(403, 'Only the owner can delete this company');
      }
      if (_graph.leads.any((lead) => lead.companyId == id)) {
        throw const ApiFailure(
          409,
          'This company has leads. Close or move them first.',
        );
      }
      for (final person in _contacts.rows.toList()) {
        if (jsonInt(person['ProspectId']) == id) {
          _contacts.byId(person['Id'] as int)
            ..remove('ProspectId')
            ..['IsPrimary'] = false;
        }
      }
      _companies.delete(id);
    },
    module: AppModule.company,
    right: ModuleRight.delete,
  );

  @override
  Future<List<DuplicateMatch>> companyDuplicates({
    required String name,
    String? phone,
    int? excludeId,
  }) => _backend.run(
    'Company duplicates',
    () => _companyMatches(name, phone, excludeId),
    module: AppModule.company,
  );

  @override
  Future<List<Contact>> companyContacts(int companyId) =>
      _backend.run('Company contacts', () {
        _companies.byId(companyId);
        return [
          for (final row in _contacts.rows)
            if (jsonInt(row['ProspectId']) == companyId)
              Contact.fromJson(_contactJson(row)),
        ]..sort((a, b) {
          if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }, module: AppModule.company);

  @override
  Future<List<LinkedLead>> companyLeads(int companyId) => _backend.run(
    'Company leads',
    () {
      _companies.byId(companyId);
      return _leads(_graph.leads.where((lead) => lead.companyId == companyId));
    },
    module: AppModule.company,
  );

  @override
  Future<void> setPrimaryContact(int companyId, int contactId) => _backend.run(
    'Company primary contact',
    () {
      final chosen = _contacts.byId(contactId);
      if (jsonInt(chosen['ProspectId']) != companyId) {
        throw const ApiFailure(400, 'This person is not at this company');
      }
      for (final row in _contacts.rows) {
        if (jsonInt(row['ProspectId']) == companyId) {
          _contacts.update(row['Id'] as int, {
            'IsPrimary': row['Id'] == contactId,
          });
        }
      }
    },
    module: AppModule.company,
    right: ModuleRight.edit,
  );

  @override
  Future<void> detachContact(int contactId) => _backend.run(
    'Company remove contact',
    () {
      final row = _contacts.byId(contactId);
      final companyId = jsonInt(row['ProspectId']);
      row
        ..remove('ProspectId')
        ..['IsPrimary'] = false;
      if (companyId != null) _promoteNextPrimary(companyId);
    },
    module: AppModule.company,
    right: ModuleRight.edit,
  );
}
