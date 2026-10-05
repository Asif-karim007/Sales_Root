import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

enum LeaveStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const LeaveStatus(this.wire);

  final String wire;

  static LeaveStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

/// One leave type and the days it allows in a year. An unpaid type has no
/// limit and is deducted from the payslip instead.
class LeaveType {
  const LeaveType({
    required this.id,
    required this.name,
    this.entitlement = 0,
    this.isPaid = true,
    this.docRequiredFromDays,
  });

  final String id;
  final LocalizedName name;
  final double entitlement;
  final bool isPaid;

  /// A request of this many days or more needs a supporting document.
  final double? docRequiredFromDays;

  bool needsDocument(double days) {
    final from = docRequiredFromDays;
    return from != null && days >= from;
  }

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
    id: jsonId(json['id']) ?? '',
    name: LocalizedName.pair(json),
    entitlement: jsonDouble(json['daysPerYear']) ?? 0,
    isPaid: json['isPaid'] != false,
    docRequiredFromDays: jsonDouble(json['docRequiredFromDays']),
  );
}

/// What is left of one leave type this year.
class LeaveBalance {
  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveType,
    this.isPaid = true,
    this.entitlement = 0,
    this.taken = 0,
    this.pending = 0,
  });

  final String leaveTypeId;
  final LocalizedName leaveType;
  final bool isPaid;

  /// The days this leave type allows this year.
  final double entitlement;

  /// Days already used by approved requests.
  final double taken;

  /// Days tied up in requests still awaiting a decision.
  final double pending;

  /// What is actually free to request right now.
  double get remainingAfterPending => entitlement - taken - pending;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
    leaveTypeId: jsonId(json['leaveTypeId']) ?? '',
    leaveType: LocalizedName.pair(json),
    isPaid: json['isPaid'] != false,
    entitlement: jsonDouble(json['entitlement']) ?? 0,
    taken: jsonDouble(json['taken']) ?? 0,
    pending: jsonDouble(json['pending']) ?? 0,
  );
}

/// Every option the leave form needs: the types, the holidays the days skip
/// and who approves.
class LeaveLookups {
  const LeaveLookups({
    this.leaveTypes = const [],
    this.holidays = const {},
    this.approverName,
  });

  final List<LeaveType> leaveTypes;
  final Set<DateTime> holidays;

  /// Null when nobody is above the employee.
  final String? approverName;
}

/// One leave request.
class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveTypeId,
    required this.leaveType,
    this.startDate,
    this.endDate,
    this.noOfDays = 0,
    this.halfDay = false,
    this.reason,
    this.remarks,
    this.status = LeaveStatus.pending,
    this.appliedAt,
    this.decidedByName,
    this.hasDocument = false,
  });

  final String id;

  /// The membership id of who asked.
  final String employeeId;
  final String employeeName;
  final String leaveTypeId;
  final LocalizedName leaveType;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Worked out by the server; `0.5` is a half day.
  final double noOfDays;
  final bool halfDay;
  final String? reason;

  /// The approver's note on the decision.
  final String? remarks;
  final LeaveStatus status;
  final DateTime? appliedAt;
  final String? decidedByName;
  final bool hasDocument;

  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;
  bool get canWithdraw => isPending;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    id: jsonId(json['id']) ?? '',
    employeeId: jsonId(json['membershipId']) ?? '',
    employeeName: json['name'] as String? ?? '',
    leaveTypeId: jsonId(json['leaveTypeId']) ?? '',
    leaveType: LocalizedName.pair(json, 'type'),
    startDate: jsonDay(json['fromDate']),
    endDate: jsonDay(json['toDate']),
    noOfDays: jsonDouble(json['days']) ?? 0,
    halfDay: json['halfDay'] != null,
    reason: json['reason'] as String?,
    remarks: json['decisionNote'] as String?,
    status: LeaveStatus.fromWire(json['status'] as String?),
    appliedAt: jsonDate(json['createdAt']),
    decidedByName: json['decidedByName'] as String?,
    hasDocument: json['docKey'] != null,
  );
}

/// What the apply form sends.
class LeaveInput {
  const LeaveInput({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.halfDay = false,
    this.reason,
    this.documentPath,
  });

  final String? leaveTypeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool halfDay;
  final String? reason;

  /// A local photo, uploaded before the request is sent.
  final String? documentPath;

  Map<String, dynamic> toJson({String? docKey}) {
    final start = startDate;
    final end = endDate;
    return {
      'leaveTypeId': leaveTypeId,
      'fromDate': start == null ? null : AppDateUtils.toApiDateOnly(start),
      'toDate': end == null ? null : AppDateUtils.toApiDateOnly(end),
      'halfDay': halfDay ? halfDayWire : null,
      'reason': trimmedOrNull(reason),
      'docKey': docKey,
    }..removeWhere((_, value) => value == null);
  }

  /// The half of the last day that is taken off.
  static const halfDayWire = 'second';
}

/// Paging and the status chip for the leave list.
class LeaveQuery {
  const LeaveQuery({this.page = 1, this.status});

  final int page;
  final LeaveStatus? status;

  LeaveQuery next(int page) => LeaveQuery(page: page, status: status);

  Map<String, dynamic> toQuery() => {
    'status': ?status?.wire,
    ...pageQuery(page),
  };
}

/// The working days between [start] and [end], both included, skipping the
/// weekly Friday off and [holidays]; [halfDay] takes half of the last day.
double leaveDays(
  DateTime? start,
  DateTime? end, {
  bool halfDay = false,
  Set<DateTime> holidays = const {},
}) {
  if (start == null || end == null) return 0;
  final from = AppDateUtils.dateOnly(start);
  final to = AppDateUtils.dateOnly(end);
  if (to.isBefore(from)) return 0;
  var days = 0;
  for (
    var day = from;
    !day.isAfter(to);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    if (day.weekday != DateTime.friday && !holidays.contains(day)) days++;
  }
  if (days == 0) return 0;
  return halfDay ? days - 0.5 : days.toDouble();
}

enum LeaveField { type, dates, balance, document }

/// The leave form while it is being filled in.
class LeaveDraft {
  const LeaveDraft({
    this.leaveTypeId,
    this.start,
    this.end,
    this.halfDay = false,
    this.reason = '',
    this.attachmentPath,
  });

  final String? leaveTypeId;
  final DateTime? start;
  final DateTime? end;
  final bool halfDay;
  final String reason;
  final String? attachmentPath;

  double days(Set<DateTime> holidays) =>
      leaveDays(start, end, halfDay: halfDay, holidays: holidays);

  /// The fields that block submitting, checked against [balances].
  Set<LeaveField> errors(LeaveLookups lookups, List<LeaveBalance> balances) {
    final type = lookups.leaveTypes
        .where((t) => t.id == leaveTypeId)
        .firstOrNull;
    final balance = balances
        .where((b) => b.leaveTypeId == leaveTypeId)
        .firstOrNull;
    final noOfDays = days(lookups.holidays);
    return {
      if (type == null) LeaveField.type,
      if (noOfDays <= 0) LeaveField.dates,
      if (type != null &&
          type.isPaid &&
          balance != null &&
          noOfDays > balance.remainingAfterPending)
        LeaveField.balance,
      if (type != null &&
          attachmentPath == null &&
          type.needsDocument(noOfDays))
        LeaveField.document,
    };
  }

  LeaveInput toInput() => LeaveInput(
    leaveTypeId: leaveTypeId,
    startDate: start,
    endDate: end,
    halfDay: halfDay,
    reason: reason,
    documentPath: attachmentPath,
  );

  LeaveDraft copyWith({
    String? leaveTypeId,
    DateTime? start,
    DateTime? end,
    bool? halfDay,
    String? reason,
    String? Function()? attachmentPath,
  }) => LeaveDraft(
    leaveTypeId: leaveTypeId ?? this.leaveTypeId,
    start: start ?? this.start,
    end: end ?? this.end,
    halfDay: halfDay ?? this.halfDay,
    reason: reason ?? this.reason,
    attachmentPath: attachmentPath != null
        ? attachmentPath()
        : this.attachmentPath,
  );
}
