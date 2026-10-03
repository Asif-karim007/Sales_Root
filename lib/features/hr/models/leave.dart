import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

/// The three fixed statuses a leave request moves through.
abstract final class LeaveStatusRef {
  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;
}

/// One leave type and the days it allows in total. An unpaid type has no
/// limit and is deducted from the payslip instead.
class LeaveType {
  const LeaveType({
    required this.id,
    required this.name,
    this.entitlement = 0,
    this.isPaid = true,
  });

  final int id;
  final LocalizedName name;
  final double entitlement;
  final bool isPaid;

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    entitlement: jsonDouble(json['Entitlement']) ?? 0,
    isPaid: json['IsPaid'] != false,
  );
}

/// What is left per leave type, against every approved and pending request.
class LeaveBalance {
  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveType,
    this.entitlement = 0,
    this.taken = 0,
    this.pending = 0,
    this.remaining = 0,
    this.remainingAfterPending = 0,
  });

  final int leaveTypeId;
  final LocalizedName leaveType;

  /// The days this leave type allows in total.
  final double entitlement;

  /// Days already used by approved requests.
  final double taken;

  /// Days tied up in requests still awaiting a decision.
  final double pending;

  /// Entitlement minus taken.
  final double remaining;

  /// Remaining minus pending: what is actually free to request right now.
  final double remainingAfterPending;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
    leaveTypeId: jsonInt(json['LeaveTypeId']) ?? 0,
    leaveType: jsonLocalizedOrEmpty(json['LeaveType'], json['LeaveTypeBn']),
    entitlement: jsonDouble(json['Entitlement']) ?? 0,
    taken: jsonDouble(json['Taken']) ?? 0,
    pending: jsonDouble(json['Pending']) ?? 0,
    remaining: jsonDouble(json['Remaining']) ?? 0,
    remainingAfterPending: jsonDouble(json['RemainingAfterPending']) ?? 0,
  );
}

/// Every option the leave form needs: the types, who approves, and who
/// covers the employee's visits while away.
class LeaveLookups {
  const LeaveLookups({
    this.leaveTypes = const [],
    this.approverName,
    this.coverName,
  });

  final List<LeaveType> leaveTypes;

  /// Null when nobody is above the employee; the request is then approved
  /// at once.
  final LocalizedName? approverName;
  final LocalizedName? coverName;

  factory LeaveLookups.fromJson(Map<String, dynamic> json) => LeaveLookups(
    leaveTypes: jsonList(json['LeaveTypes'], LeaveType.fromJson),
    approverName: jsonLocalized(json['ApproverName'], json['ApproverNameBn']),
    coverName: jsonLocalized(json['CoverName'], json['CoverNameBn']),
  );
}

/// The single supporting file a leave request may carry.
class LeaveAttachment {
  const LeaveAttachment({this.fileName, this.url});

  final String? fileName;
  final String? url;

  factory LeaveAttachment.fromJson(Map<String, dynamic> json) =>
      LeaveAttachment(
        fileName: json['FileName'] as String?,
        url: json['Url'] as String?,
      );
}

/// One leave request. The list rows and the detail carry the same fields.
class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveTypeId,
    required this.leaveType,
    this.designation,
    this.startDate,
    this.endDate,
    this.noOfDays = 0,
    this.reason,
    this.remarks,
    this.statusId = LeaveStatusRef.pending,
    this.statusUpdatedAt,
    this.appliedAt,
    this.approverName,
    this.coverName,
    this.attachment,
    this.canWithdraw = false,
  });

  final int id;
  final int employeeId;
  final LocalizedName employeeName;
  final String? designation;
  final int leaveTypeId;
  final LocalizedName leaveType;
  final DateTime? startDate;
  final DateTime? endDate;

  /// A plain decimal; `0.5` is how a half day is expressed.
  final double noOfDays;

  final String? reason;

  /// The approver's note on the decision.
  final String? remarks;
  final int statusId;
  final DateTime? statusUpdatedAt;
  final DateTime? appliedAt;
  final LocalizedName? approverName;
  final LocalizedName? coverName;
  final LeaveAttachment? attachment;
  final bool canWithdraw;

  bool get isPending => statusId == LeaveStatusRef.pending;
  bool get isApproved => statusId == LeaveStatusRef.approved;
  bool get isRejected => statusId == LeaveStatusRef.rejected;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    id: jsonInt(json['Id']) ?? 0,
    employeeId: jsonInt(json['EmployeeId']) ?? 0,
    employeeName: jsonLocalizedOrEmpty(
      json['EmployeeName'],
      json['EmployeeNameBn'],
    ),
    designation: json['Designation'] as String?,
    leaveTypeId: jsonInt(json['LeaveTypeId']) ?? 0,
    leaveType: jsonLocalizedOrEmpty(
      json['LeaveTypeName'],
      json['LeaveTypeNameBn'],
    ),
    startDate: jsonDate(json['StartDate']),
    endDate: jsonDate(json['EndDate']),
    noOfDays: jsonDouble(json['NoOfDays']) ?? 0,
    reason: json['Reason'] as String?,
    remarks: json['Remarks'] as String?,
    statusId: jsonInt(json['StatusId']) ?? LeaveStatusRef.pending,
    statusUpdatedAt: jsonDate(json['StatusUpdatedAt']),
    appliedAt: jsonDate(json['AppliedAt']),
    approverName: jsonLocalized(json['ApproverName'], json['ApproverNameBn']),
    coverName: jsonLocalized(json['CoverName'], json['CoverNameBn']),
    attachment: jsonObject(json['Attachment'], LeaveAttachment.fromJson),
    canWithdraw: jsonBool(json['CanWithdraw']),
  );
}

/// What the apply form sends.
class LeaveInput {
  const LeaveInput({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.noOfDays,
    this.reason,
    this.attachmentName,
  });

  final int? leaveTypeId;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Not computed by the server: the form sends what it worked out, half
  /// days included.
  final double noOfDays;
  final String? reason;
  final String? attachmentName;

  Map<String, dynamic> toJson() => {
    'LeaveTypeId': leaveTypeId,
    'StartDate': jsonUtc(startDate),
    'EndDate': jsonUtc(endDate),
    'NoOfDays': noOfDays,
    'Reason': trimmedOrNull(reason),
    'Attachment': attachmentName == null ? null : {'FileName': attachmentName},
  }..removeWhere((_, value) => value == null);
}

/// Paging and filters for the leave list. [employeeId] reads someone else's
/// requests; it is ignored for a member reading only their own.
class LeaveQuery {
  const LeaveQuery({this.page = 1, this.statusId, this.employeeId});

  final int page;
  final int? statusId;
  final int? employeeId;

  LeaveQuery next(int page) =>
      LeaveQuery(page: page, statusId: statusId, employeeId: employeeId);
}

/// The working days between [start] and [end], both included, skipping the
/// weekly Friday off; [halfDay] takes half of the last day.
double leaveDays(DateTime? start, DateTime? end, {bool halfDay = false}) {
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
    if (day.weekday != DateTime.friday) days++;
  }
  if (days == 0) return 0;
  return halfDay ? days - 0.5 : days.toDouble();
}

enum LeaveField { type, dates, balance }

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

  final int? leaveTypeId;
  final DateTime? start;
  final DateTime? end;
  final bool halfDay;
  final String reason;
  final String? attachmentPath;

  double get noOfDays => leaveDays(start, end, halfDay: halfDay);

  /// The fields that block submitting, checked against [balances].
  Set<LeaveField> errors(List<LeaveType> types, List<LeaveBalance> balances) {
    final type = types.where((t) => t.id == leaveTypeId).firstOrNull;
    final balance = balances
        .where((b) => b.leaveTypeId == leaveTypeId)
        .firstOrNull;
    return {
      if (type == null) LeaveField.type,
      if (noOfDays <= 0) LeaveField.dates,
      if (type != null &&
          type.isPaid &&
          balance != null &&
          noOfDays > balance.remainingAfterPending)
        LeaveField.balance,
    };
  }

  LeaveInput toInput() => LeaveInput(
    leaveTypeId: leaveTypeId,
    startDate: start,
    endDate: end,
    noOfDays: noOfDays,
    reason: reason,
    attachmentName: attachmentPath?.split('/').last,
  );

  LeaveDraft copyWith({
    int? leaveTypeId,
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
