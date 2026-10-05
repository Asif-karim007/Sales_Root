import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/utils/json_fields.dart';

class Plan {
  const Plan({
    required this.code,
    required this.name,
    required this.users,
    required this.usersUsed,
    required this.records,
    required this.recordsUsed,
    required this.storageGb,
    required this.storageUsedGb,
    required this.cardScans,
    required this.cardScansUsed,
    required this.smsCredits,
    required this.addOns,
    required this.pricePerMonth,
    this.renewsAt,
  });

  final String code;
  final String name;
  final int users;
  final int usersUsed;
  final int records;
  final int recordsUsed;
  final double storageGb;
  final double storageUsedGb;
  final int cardScans;
  final int cardScansUsed;
  final int smsCredits;
  final Set<AddOn> addOns;
  final int pricePerMonth;
  final DateTime? renewsAt;

  bool has(AddOn addOn) => addOns.contains(addOn);

  bool get hasFreeSeat => usersUsed < users;

  /// `GET /billing`: `{workspace: {plan, usersPurchased, …}, usage: {…}}`.
  factory Plan.fromBilling(Map<String, dynamic> json) {
    final workspace = jsonMap(json['workspace']);
    final usage = jsonMap(json['usage']);
    final code = workspace['plan'] as String? ?? 'free';
    final layers = jsonStrings(workspace['layers']);
    return Plan(
      code: code,
      name: code.isEmpty ? code : code[0].toUpperCase() + code.substring(1),
      users: jsonInt(workspace['usersPurchased']) ?? 1,
      usersUsed: jsonInt(usage['users']) ?? 1,
      records: jsonInt(workspace['recordLimit']) ?? 0,
      recordsUsed: jsonInt(usage['records']) ?? 0,
      storageGb:
          ((jsonDouble(workspace['storageLimitMb']) ?? 0) +
              (jsonDouble(workspace['extraStorageMb']) ?? 0)) /
          1024,
      storageUsedGb: (jsonDouble(usage['storageMb']) ?? 0) / 1024,
      cardScans:
          (jsonInt(workspace['scanLimit']) ?? 0) +
          (jsonInt(workspace['extraScans']) ?? 0),
      cardScansUsed: jsonInt(usage['scans']) ?? 0,
      smsCredits: jsonInt(workspace['smsCredits']) ?? 0,
      addOns: {
        if (layers.contains('fieldforce')) AddOn.fieldForce,
        if (layers.contains('growth')) AddOn.growth,
      },
      pricePerMonth: jsonInt(workspace['pricePerMonth']) ?? 0,
      renewsAt: jsonDate(workspace['billingDate']),
    );
  }

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    code: json['Code'] as String? ?? 'Free',
    name: json['Name'] as String? ?? '',
    users: jsonInt(json['Users']) ?? 1,
    usersUsed: jsonInt(json['UsersUsed']) ?? 1,
    records: jsonInt(json['Records']) ?? 0,
    recordsUsed: jsonInt(json['RecordsUsed']) ?? 0,
    storageGb: jsonDouble(json['StorageGb']) ?? 0,
    storageUsedGb: jsonDouble(json['StorageUsedGb']) ?? 0,
    cardScans: jsonInt(json['CardScans']) ?? 0,
    cardScansUsed: jsonInt(json['CardScansUsed']) ?? 0,
    smsCredits: jsonInt(json['SmsCredits']) ?? 0,
    addOns: {
      for (final wire in jsonStrings(json['AddOns'])) ?AddOn.fromWire(wire),
    },
    pricePerMonth: jsonInt(json['PricePerMonth']) ?? 0,
    renewsAt: jsonDate(json['RenewsAt']),
  );

  Map<String, dynamic> toJson() => {
    'Code': code,
    'Name': name,
    'Users': users,
    'UsersUsed': usersUsed,
    'Records': records,
    'RecordsUsed': recordsUsed,
    'StorageGb': storageGb,
    'StorageUsedGb': storageUsedGb,
    'CardScans': cardScans,
    'CardScansUsed': cardScansUsed,
    'SmsCredits': smsCredits,
    'AddOns': [for (final addOn in addOns) addOn.wire],
    'PricePerMonth': pricePerMonth,
    'RenewsAt': jsonUtc(renewsAt),
  }..removeWhere((_, value) => value == null);
}
