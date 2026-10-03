import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';
import 'package:salesroot/features/hr/models/leave.dart';

enum ApprovalKind {
  leave('Leave'),
  expense('Expense'),
  collection('Collection');

  const ApprovalKind(this.wire);

  final String wire;

  static ApprovalKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => leave);
}

enum ApprovalState {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const ApprovalState(this.wire);

  final String wire;

  static ApprovalState fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

/// The approval chips: everything waiting, one kind, or already decided.
enum ApprovalFilter {
  pending('Pending'),
  leave('Leave'),
  expense('Expense'),
  collection('Collection'),
  done('Done');

  const ApprovalFilter(this.wire);

  final String wire;
}

/// Cash a rep collected that has to be confirmed before it counts.
class CollectionApproval {
  const CollectionApproval({
    required this.amount,
    required this.method,
    required this.companyName,
    this.companyId,
    this.hasSlip = false,
    this.collectedAt,
  });

  final double amount;

  /// `Cash`, `bKash`, `Cheque` or `Bank`.
  final String method;
  final int? companyId;
  final String companyName;
  final bool hasSlip;
  final DateTime? collectedAt;

  factory CollectionApproval.fromJson(Map<String, dynamic> json) =>
      CollectionApproval(
        amount: jsonDouble(json['Amount']) ?? 0,
        method: json['Method'] as String? ?? '',
        companyId: jsonInt(json['CompanyId']),
        companyName: json['CompanyName'] as String? ?? '',
        hasSlip: jsonBool(json['HasSlip']),
        collectedAt: jsonDate(json['CollectedAt']),
      );
}

/// One request in the approvals queue. Exactly one of [leave], [expense]
/// and [collection] is set, by [kind].
class ApprovalItem {
  const ApprovalItem({
    required this.kind,
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.state,
    this.submittedAt,
    this.decisionNote,
    this.decidedByName,
    this.leave,
    this.expense,
    this.collection,
  });

  final ApprovalKind kind;

  /// The id of the leave request, claim or collection.
  final int id;
  final int employeeId;
  final LocalizedName employeeName;
  final ApprovalState state;
  final DateTime? submittedAt;
  final String? decisionNote;
  final LocalizedName? decidedByName;
  final LeaveRequest? leave;
  final ExpenseClaim? expense;
  final CollectionApproval? collection;

  String get key => '${kind.wire}-$id';

  factory ApprovalItem.fromJson(Map<String, dynamic> json) => ApprovalItem(
    kind: ApprovalKind.fromWire(json['Kind'] as String?),
    id: jsonInt(json['Id']) ?? 0,
    employeeId: jsonInt(json['EmployeeId']) ?? 0,
    employeeName: jsonLocalizedOrEmpty(
      json['EmployeeName'],
      json['EmployeeNameBn'],
    ),
    state: ApprovalState.fromWire(json['State'] as String?),
    submittedAt: jsonDate(json['SubmittedAt']),
    decisionNote: json['DecisionNote'] as String?,
    decidedByName: jsonLocalized(
      json['DecidedByName'],
      json['DecidedByNameBn'],
    ),
    leave: jsonObject(json['Leave'], LeaveRequest.fromJson),
    expense: jsonObject(json['Expense'], ExpenseClaim.fromJson),
    collection: jsonObject(json['Collection'], CollectionApproval.fromJson),
  );
}

/// An approve or reject. A rejection needs a [reason].
class ApprovalDecision {
  const ApprovalDecision({
    required this.kind,
    required this.id,
    required this.approve,
    this.reason,
  });

  final ApprovalKind kind;
  final int id;
  final bool approve;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'Kind': kind.wire,
    'Id': id,
    'Decision': approve ? 'Approve' : 'Reject',
    'Reason': trimmedOrNull(reason),
  }..removeWhere((_, value) => value == null);
}

class ApprovalQuery {
  const ApprovalQuery({this.page = 1, this.filter = ApprovalFilter.pending});

  final int page;
  final ApprovalFilter filter;

  ApprovalQuery next(int page) => ApprovalQuery(page: page, filter: filter);
}
