import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

enum PayslipLineCode {
  basic('Basic', deduction: false),
  houseRent('HouseRent', deduction: false),
  conveyance('Conveyance', deduction: false),
  commission('Commission', deduction: false),
  reimbursement('Reimbursement', deduction: false),
  unpaidLeave('UnpaidLeave', deduction: true),
  late('Late', deduction: true),
  advanceRecovery('AdvanceRecovery', deduction: true),
  providentFund('ProvidentFund', deduction: true);

  const PayslipLineCode(this.wire, {required this.deduction});

  final String wire;
  final bool deduction;

  static PayslipLineCode? fromWire(String? value) {
    for (final code in values) {
      if (code.wire == value) return code;
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
    final code = PayslipLineCode.fromWire(json['Code'] as String?);
    if (code == null) return null;
    return PayslipLine(
      code: code,
      amount: jsonDouble(json['Amount']) ?? 0,
      count: jsonInt(json['Count']),
    );
  }
}

/// One month's pay for one employee.
class Payslip {
  const Payslip({
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
    required this.lines,
    required this.netPay,
    this.designation,
    this.presentDays = 0,
    this.workingDays = 0,
    this.payoutMethod,
    this.payoutAccount,
    this.paidOn,
  });

  final int employeeId;
  final LocalizedName employeeName;
  final String? designation;
  final int year;
  final int month;
  final List<PayslipLine> lines;

  /// What the server paid; always [totalEarnings] minus [totalDeductions].
  final double netPay;
  final int presentDays;
  final int workingDays;
  final String? payoutMethod;

  /// Masked, e.g. `01811••••33`.
  final String? payoutAccount;
  final DateTime? paidOn;

  List<PayslipLine> get earnings =>
      lines.where((l) => !l.code.deduction).toList();

  List<PayslipLine> get deductions =>
      lines.where((l) => l.code.deduction).toList();

  double get totalEarnings => earnings.fold(0, (sum, l) => sum + l.amount);

  double get totalDeductions => deductions.fold(0, (sum, l) => sum + l.amount);

  DateTime get period => DateTime(year, month);

  factory Payslip.fromJson(Map<String, dynamic> json) => Payslip(
    employeeId: jsonInt(json['EmployeeId']) ?? 0,
    employeeName: jsonLocalizedOrEmpty(
      json['EmployeeName'],
      json['EmployeeNameBn'],
    ),
    designation: json['Designation'] as String?,
    year: jsonInt(json['Year']) ?? 0,
    month: jsonInt(json['Month']) ?? 1,
    lines: [
      for (final row in jsonList(json['Lines'], (row) => row))
        ?PayslipLine.fromJson(row),
    ],
    netPay: jsonDouble(json['NetPay']) ?? 0,
    presentDays: jsonInt(json['PresentDays']) ?? 0,
    workingDays: jsonInt(json['WorkingDays']) ?? 0,
    payoutMethod: json['PayoutMethod'] as String?,
    payoutAccount: json['PayoutAccount'] as String?,
    paidOn: jsonDate(json['PaidOn']),
  );
}

/// The payroll details on an employee's card. Only the owner, a payroll
/// manager and the employee can read it.
class EmployeeCard {
  const EmployeeCard({
    required this.employeeId,
    required this.name,
    required this.employeeCode,
    this.designation,
    this.joinedOn,
    this.dutyStart,
    this.dutyEnd,
    this.weeklyOff = DateTime.friday,
    this.reportsTo,
    this.basic = 0,
    this.houseRent = 0,
    this.conveyance = 0,
    this.commissionRate = 0,
    this.providentFund = 0,
    this.payoutMethod,
    this.payoutAccount,
    this.advanceOutstanding = 0,
    this.advanceInstallments = 0,
    this.canEdit = false,
  });

  final int employeeId;
  final LocalizedName name;
  final String employeeCode;
  final String? designation;
  final DateTime? joinedOn;

  /// `09:00`
  final String? dutyStart;
  final String? dutyEnd;

  /// The weekday off, as [DateTime.weekday].
  final int weeklyOff;
  final LocalizedName? reportsTo;
  final double basic;
  final double houseRent;
  final double conveyance;

  /// Percent of won deal value.
  final double commissionRate;
  final double providentFund;
  final String? payoutMethod;
  final String? payoutAccount;
  final double advanceOutstanding;
  final int advanceInstallments;
  final bool canEdit;

  factory EmployeeCard.fromJson(Map<String, dynamic> json) => EmployeeCard(
    employeeId: jsonInt(json['EmployeeId']) ?? 0,
    name: jsonLocalizedOrEmpty(json['Name'], json['NameBn']),
    employeeCode: json['EmployeeCode'] as String? ?? '',
    designation: json['Designation'] as String?,
    joinedOn: jsonDate(json['JoinedOn']),
    dutyStart: json['DutyStart'] as String?,
    dutyEnd: json['DutyEnd'] as String?,
    weeklyOff: jsonInt(json['WeeklyOff']) ?? DateTime.friday,
    reportsTo: jsonLocalized(json['ReportsTo'], json['ReportsToBn']),
    basic: jsonDouble(json['Basic']) ?? 0,
    houseRent: jsonDouble(json['HouseRent']) ?? 0,
    conveyance: jsonDouble(json['Conveyance']) ?? 0,
    commissionRate: jsonDouble(json['CommissionRate']) ?? 0,
    providentFund: jsonDouble(json['ProvidentFund']) ?? 0,
    payoutMethod: json['PayoutMethod'] as String?,
    payoutAccount: json['PayoutAccount'] as String?,
    advanceOutstanding: jsonDouble(json['AdvanceOutstanding']) ?? 0,
    advanceInstallments: jsonInt(json['AdvanceInstallments']) ?? 0,
    canEdit: jsonBool(json['CanEdit']),
  );
}

/// The salary structure the edit sheet saves.
class SalaryInput {
  const SalaryInput({
    required this.basic,
    required this.houseRent,
    required this.conveyance,
    required this.commissionRate,
    required this.providentFund,
  });

  final double? basic;
  final double? houseRent;
  final double? conveyance;
  final double? commissionRate;
  final double? providentFund;

  Map<String, dynamic> toJson() => {
    'Basic': basic,
    'HouseRent': houseRent,
    'Conveyance': conveyance,
    'CommissionRate': commissionRate,
    'ProvidentFund': providentFund,
  }..removeWhere((_, value) => value == null);
}
