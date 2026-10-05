import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

/// The pay lines a payslip can carry, with the server keys each is read
/// from.
enum PayslipLineCode {
  basic(['basic'], deduction: false),
  houseRent(['houseRent'], deduction: false),
  medical(['medical'], deduction: false),
  conveyance(['conveyance'], deduction: false),
  commission(['commission'], deduction: false),
  bonus(['bonus'], deduction: false),
  arrears(['arrears'], deduction: false),
  reimbursement(['reimbursement', 'expenses'], deduction: false),
  unpaidLeave(['unpaidLeave', 'leaveDeduction'], deduction: true),
  late(['late', 'lateDeduction'], deduction: true),
  advanceRecovery(['advanceRecovery', 'advance'], deduction: true),
  providentFund(['pf', 'providentFund'], deduction: true),
  tax(['tax', 'taxMonthly'], deduction: true),
  otherDeduction(['otherDeduction'], deduction: true);

  const PayslipLineCode(this.keys, {required this.deduction});

  final List<String> keys;
  final bool deduction;

  static PayslipLineCode? fromWire(String? value) {
    for (final code in values) {
      if (code.keys.contains(value)) return code;
    }
    return null;
  }
}

/// One earning or deduction. [count] is the days or claims behind it.
class PayslipLine {
  const PayslipLine({required this.code, required this.amount, this.count});

  final PayslipLineCode code;
  final double amount;
  final int? count;

  static PayslipLine? fromJson(Map<String, dynamic> json) {
    final code = PayslipLineCode.fromWire(json['code'] as String?);
    if (code == null) return null;
    return PayslipLine(
      code: code,
      amount: jsonDouble(json['amount']) ?? 0,
      count: jsonInt(json['count']),
    );
  }

  /// The lines of a slip that sends each amount as its own key.
  static List<PayslipLine> fromKeys(Map<String, dynamic> json) => [
    for (final code in PayslipLineCode.values)
      if (code.keys.map((k) => jsonDouble(json[k])).nonNulls.firstOrNull
          case final amount? when amount != 0)
        PayslipLine(code: code, amount: amount),
  ];
}

/// The month a payslip or payroll run covers: `period` (`2026-09`), or
/// `year` and `month`.
DateTime? payPeriod(Map<String, dynamic> json) {
  final period = json['period'];
  if (period is String && period.length >= 7) {
    final year = int.tryParse(period.substring(0, 4));
    final month = int.tryParse(period.substring(5, 7));
    if (year != null && month != null) return DateTime(year, month);
  }
  final year = jsonInt(json['year']);
  final month = jsonInt(json['month']);
  return year == null || month == null ? null : DateTime(year, month);
}

/// An issued payslip on the month list.
class PayslipRef {
  const PayslipRef({required this.id, required this.period});

  final String id;
  final DateTime period;

  static PayslipRef? fromJson(Map<String, dynamic> json) {
    final id = jsonId(json['id']);
    final period = payPeriod(json);
    return id == null || period == null
        ? null
        : PayslipRef(id: id, period: period);
  }
}

/// One month's pay for one employee.
class Payslip {
  const Payslip({
    required this.employeeName,
    required this.period,
    required this.lines,
    required this.netPay,
    this.designation,
    this.presentDays,
    this.workingDays,
    this.payoutMethod,
    this.payoutAccount,
    this.paidOn,
  });

  final String employeeName;
  final String? designation;
  final DateTime period;
  final List<PayslipLine> lines;

  /// What the server paid.
  final double netPay;
  final int? presentDays;
  final int? workingDays;
  final String? payoutMethod;
  final String? payoutAccount;
  final DateTime? paidOn;

  List<PayslipLine> get earnings =>
      lines.where((l) => !l.code.deduction).toList();

  List<PayslipLine> get deductions =>
      lines.where((l) => l.code.deduction).toList();

  double get totalEarnings => earnings.fold(0, (sum, l) => sum + l.amount);

  double get totalDeductions => deductions.fold(0, (sum, l) => sum + l.amount);

  /// A slip, flat or wrapped in `slip`.
  factory Payslip.fromJson(Map<String, dynamic> json, {DateTime? period}) {
    final slip = json['slip'] is Map ? jsonMap(json['slip']) : json;
    final lines = [
      for (final row in jsonList(slip['lines'], (row) => row))
        ?PayslipLine.fromJson(row),
    ];
    return Payslip(
      employeeName: slip['name'] as String? ?? '',
      designation: slip['designation'] as String?,
      period: payPeriod(slip) ?? period ?? DateTime(2000),
      lines: lines.isEmpty ? PayslipLine.fromKeys(slip) : lines,
      netPay: jsonDouble(slip['net'] ?? slip['netPay']) ?? 0,
      presentDays: jsonInt(slip['presentDays']),
      workingDays: jsonInt(slip['workingDays']),
      payoutMethod: slip['paymentMethod'] as String?,
      payoutAccount: slip['paymentAccount'] as String?,
      paidOn: jsonDate(slip['paidAt']),
    );
  }
}

/// A salary structure as `hr/salary` keeps it.
class SalaryStructure {
  const SalaryStructure({
    this.basic = 0,
    this.houseRent = 0,
    this.medical = 0,
    this.conveyance = 0,
    this.commissionRate,
    this.pfPct = 0,
    this.paymentMethod,
    this.paymentAccount,
    this.designation,
    this.joinedOn,
    this.raw = const {},
  });

  final double basic;
  final double houseRent;
  final double medical;
  final double conveyance;

  /// Percent of won deal value.
  final double? commissionRate;
  final double pfPct;
  final String? paymentMethod;
  final String? paymentAccount;
  final String? designation;
  final DateTime? joinedOn;

  /// The record as sent, so a save keeps the fields the sheet doesn't edit.
  final Map<String, dynamic> raw;

  static SalaryStructure? fromJson(dynamic value) {
    final json = jsonMap(value);
    if (json.isEmpty) return null;
    final commission = json['commission'];
    return SalaryStructure(
      basic: jsonDouble(json['basic']) ?? 0,
      houseRent: jsonDouble(json['houseRent']) ?? 0,
      medical: jsonDouble(json['medical']) ?? 0,
      conveyance: jsonDouble(json['conveyance']) ?? 0,
      commissionRate:
          jsonDouble(commission) ?? jsonDouble(jsonMap(commission)['pct']),
      pfPct: jsonDouble(json['pfPct']) ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentAccount: json['paymentAccount'] as String?,
      designation: json['designation'] as String?,
      joinedOn: jsonDay(json['joinedOn']),
      raw: json,
    );
  }
}

/// The job and payroll details on an employee's card. Only the owner, a
/// payroll manager and the employee can read it.
class EmployeeCard {
  const EmployeeCard({
    required this.employeeId,
    required this.name,
    this.designation,
    this.joinedOn,
    this.reportsTo,
    this.salary,
    this.canEdit = false,
  });

  /// The membership id.
  final String employeeId;
  final String name;
  final String? designation;
  final DateTime? joinedOn;
  final String? reportsTo;

  /// Null until payroll sets one up.
  final SalaryStructure? salary;
  final bool canEdit;
}

/// The amounts the edit sheet saves.
class SalaryInput {
  const SalaryInput({
    required this.basic,
    required this.houseRent,
    required this.medical,
    required this.conveyance,
    required this.pfPct,
  });

  final double basic;
  final double houseRent;
  final double medical;
  final double conveyance;
  final double pfPct;

  /// The SalaryUpsert body: [current]'s other fields with these amounts,
  /// effective [from].
  Map<String, dynamic> toJson(SalaryStructure current, DateTime from) => {
    for (final key in _kept) key: current.raw[key],
    'effectiveFrom': AppDateUtils.toApiDateOnly(from),
    'basic': basic,
    'houseRent': houseRent,
    'medical': medical,
    'conveyance': conveyance,
    'pfPct': pfPct,
  }..removeWhere((_, value) => value == null);

  static const _kept = [
    'otherAllowances',
    'taxMonthly',
    'commission',
    'paymentMethod',
    'paymentAccount',
    'bankName',
    'bankBranch',
    'bankRouting',
    'designation',
    'joinedOn',
    'note',
  ];
}
