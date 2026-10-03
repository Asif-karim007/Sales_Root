import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/models/payroll.dart';

/// Working days in a month that pay one day's basic.
const int payrollDayDivisor = 22;

/// Every third late arrival costs a day's basic.
const int latesPerDeductedDay = 3;

/// The payroll profile the server keeps for [member], before any edit.
Map<String, dynamic> payrollProfileRow(SeedGraph graph, SeedMember member) {
  final anchor = graph.anchor;
  final isMe = member.id == SeedGraph.meId;
  final basic = switch (member.role) {
    WorkspaceRole.owner => 90000,
    WorkspaceRole.teamLead => 48000,
    WorkspaceRole.member => isMe ? 25000 : 22000 + (member.id * 1500) % 7000,
  };
  final hasAdvance = isMe || member.id % 5 == 0;
  final digits = member.phone.replaceAll(RegExp(r'\D'), '');
  final local = digits.length > 11
      ? digits.substring(digits.length - 11)
      : digits;
  final isLead = member.role != WorkspaceRole.member;
  return {
    'EmployeeId': member.id,
    ...personFields('Name', member),
    'EmployeeCode': 'SR-${member.id.toString().padLeft(3, '0')}',
    'Designation': member.designation,
    'JoinedOn': jsonUtc(
      isMe
          ? DateTime(anchor.year, anchor.month - 7)
          : DateTime(
              anchor.year,
              anchor.month - 9 - (member.id * 5) % 30,
              1 + member.id % 20,
            ),
    ),
    'DutyStart': '09:00',
    'DutyEnd': '18:00',
    'WeeklyOff': DateTime.friday,
    ...personFields('ReportsTo', memberOrNull(graph, member.managerId)),
    'Basic': basic,
    'HouseRent': basic * 0.3,
    'Conveyance': member.role == WorkspaceRole.owner
        ? 0
        : (isLead ? 3000 : 2000),
    'CommissionRate': switch (member.role) {
      WorkspaceRole.owner => 0,
      WorkspaceRole.teamLead => 0.5,
      WorkspaceRole.member => 1,
    },
    'ProvidentFund': isLead ? 500 : 150,
    'PayoutMethod': isLead ? 'Bank' : 'bKash',
    'PayoutAccount': isLead
        ? 'DBBL ••••${digits.substring(digits.length - 4)}'
        : '${local.substring(0, 5)}••••${local.substring(local.length - 2)}',
    'AdvanceOutstanding': hasAdvance ? (isMe ? 6000 : 9000) : 0,
    'AdvanceInstallments': hasAdvance ? (isMe ? 2 : 3) : 0,
  };
}

/// The months with an issued payslip for a profile, newest first. The
/// current month is paid at its end, so it is never in the list.
List<DateTime> issuedPayslipMonths(
  SeedGraph graph,
  Map<String, dynamic> profile,
) {
  final joined = jsonDate(profile['JoinedOn']) ?? graph.anchor;
  final months = <DateTime>[];
  var month = DateTime(graph.anchor.year, graph.anchor.month - 1);
  final first = DateTime(joined.year, joined.month);
  while (!month.isBefore(first) && months.length < 24) {
    months.add(month);
    month = DateTime(month.year, month.month - 1);
  }
  return months;
}

/// When a won lead closed, spread over the months before the anchor.
DateTime wonOn(SeedGraph graph, SeedLead lead) =>
    graph.daysAgo(lead.createdDaysAgo ~/ 2 + lead.lastTouchDaysAgo);

/// One month's payslip for a profile, from the won deals, approved claims
/// and approved leave of that month.
Map<String, dynamic> payslipRow({
  required SeedGraph graph,
  required Map<String, dynamic> profile,
  required List<Map<String, dynamic>> leaveRows,
  required List<Map<String, dynamic>> expenseRows,
  required DateTime month,
}) {
  final employeeId = profile['EmployeeId'] as int;
  bool inMonth(DateTime? day) =>
      day != null && day.year == month.year && day.month == month.month;

  final basic = jsonDouble(profile['Basic']) ?? 0;
  final dailyRate = (basic / payrollDayDivisor).roundToDouble();

  final won = graph.leads
      .where((l) => l.ownerId == employeeId && l.stageId == 5)
      .where((l) => inMonth(wonOn(graph, l)))
      .toList();
  final rate = jsonDouble(profile['CommissionRate']) ?? 0;
  final commission =
      (won.fold<double>(0, (sum, l) => sum + l.value) * rate / 100)
          .roundToDouble();

  final claims = expenseRows.where((row) {
    final stage = ExpenseStage.fromWire(
      row['WorkflowStatus'] as String?,
      row['SettlementStatus'] as String?,
    );
    return row['ClaimedBy'] == employeeId &&
        (stage == ExpenseStage.approved || stage == ExpenseStage.paid) &&
        inMonth(expenseDay(row['IncurredFrom']));
  }).toList();
  final reimbursed = claims.fold<double>(
    0,
    (sum, row) => sum + (jsonDouble(row['ClaimedTotal']) ?? 0),
  );

  final leaves = leaveRows
      .where(
        (row) =>
            row['EmployeeId'] == employeeId &&
            row['StatusId'] == LeaveStatusRef.approved &&
            inMonth(jsonDate(row['StartDate'])),
      )
      .toList();
  double days(Iterable<Map<String, dynamic>> rows) =>
      rows.fold(0, (sum, row) => sum + (jsonDouble(row['NoOfDays']) ?? 0));
  final unpaidDays = days(
    leaves.where((row) => row['LeaveTypeId'] == unpaidLeaveId),
  );

  final random = graph.random(
    'payslip-$employeeId-${month.year}-${month.month}',
  );
  final lateDays = random.nextInt(5);
  final absent = random.nextInt(2);

  final outstanding = jsonDouble(profile['AdvanceOutstanding']) ?? 0;
  final installments = jsonInt(profile['AdvanceInstallments']) ?? 0;
  final recent = issuedPayslipMonths(graph, profile).take(2);
  final recovery = outstanding > 0 && installments > 0 && recent.contains(month)
      ? outstanding / installments
      : 0.0;

  final workingDays = _workingDays(month);
  final lines = <Map<String, dynamic>>[
    _line(PayslipLineCode.basic, basic),
    _line(PayslipLineCode.houseRent, jsonDouble(profile['HouseRent']) ?? 0),
    _line(PayslipLineCode.conveyance, jsonDouble(profile['Conveyance']) ?? 0),
    _line(PayslipLineCode.commission, commission, count: won.length),
    _line(PayslipLineCode.reimbursement, reimbursed, count: claims.length),
    _line(
      PayslipLineCode.unpaidLeave,
      (unpaidDays * dailyRate).roundToDouble(),
      count: unpaidDays.ceil(),
    ),
    _line(
      PayslipLineCode.late,
      (lateDays ~/ latesPerDeductedDay) * dailyRate,
      count: lateDays,
    ),
    _line(PayslipLineCode.advanceRecovery, recovery),
    _line(
      PayslipLineCode.providentFund,
      jsonDouble(profile['ProvidentFund']) ?? 0,
    ),
  ].where((line) => line['Amount'] != 0 || (line['Count'] ?? 0) != 0).toList();

  double total(bool deduction) => lines
      .where(
        (line) =>
            PayslipLineCode.fromWire(line['Code'] as String?)?.deduction ==
            deduction,
      )
      .fold(0, (sum, line) => sum + (jsonDouble(line['Amount']) ?? 0));

  return {
    'EmployeeId': employeeId,
    'EmployeeName': profile['Name'],
    'EmployeeNameBn': profile['NameBn'],
    'Designation': profile['Designation'],
    'Year': month.year,
    'Month': month.month,
    'Lines': lines,
    'NetPay': total(false) - total(true),
    'WorkingDays': workingDays,
    'PresentDays': workingDays - days(leaves).ceil() - absent,
    'PayoutMethod': profile['PayoutMethod'],
    'PayoutAccount': profile['PayoutAccount'],
    'PaidOn': jsonUtc(DateTime(month.year, month.month + 1, 0, 17)),
  };
}

Map<String, dynamic> _line(PayslipLineCode code, double amount, {int? count}) =>
    {'Code': code.wire, 'Amount': amount, 'Count': ?count};

int _workingDays(DateTime month) {
  final last = DateTime(month.year, month.month + 1, 0).day;
  var days = 0;
  for (var d = 1; d <= last; d++) {
    if (DateTime(month.year, month.month, d).weekday != DateTime.friday) days++;
  }
  return days;
}
