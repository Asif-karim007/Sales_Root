import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

enum ApprovalKind {
  leave('leave'),
  expense('expense'),
  collection('collection'),
  other('');

  const ApprovalKind(this.wire);

  final String wire;

  static ApprovalKind fromWire(String? value) => switch (value) {
    'leave' => leave,
    'expense' => expense,
    'collection' || 'payment' => collection,
    _ => other,
  };
}

enum ApprovalState {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const ApprovalState(this.wire);

  final String wire;

  static ApprovalState fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

/// The approval chips: everything waiting, one kind, or already decided.
enum ApprovalFilter {
  pending('pending'),
  leave('leave'),
  expense('expense'),
  collection('collection'),
  done('done');

  const ApprovalFilter(this.wire);

  final String wire;

  ApprovalKind? get kind => switch (this) {
    leave => ApprovalKind.leave,
    expense => ApprovalKind.expense,
    collection => ApprovalKind.collection,
    _ => null,
  };
}

/// One request in the approvals queue.
class ApprovalItem {
  const ApprovalItem({
    required this.kind,
    required this.id,
    required this.employeeName,
    required this.state,
    this.summary = '',
    this.amount,
    this.reason,
    this.submittedAt,
    this.decisionNote,
    this.approverName,
  });

  final ApprovalKind kind;
  final String id;
  final String employeeName;
  final ApprovalState state;

  /// What is asked for, as the server words it.
  final String summary;
  final double? amount;
  final String? reason;
  final DateTime? submittedAt;
  final String? decisionNote;
  final String? approverName;

  bool get isPending => state == ApprovalState.pending;

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    final name = json['requestedByName'] as String? ?? '';
    final summary = json['summary'] as String? ?? '';
    return ApprovalItem(
      kind: ApprovalKind.fromWire(json['type'] as String?),
      id: jsonId(json['id']) ?? '',
      employeeName: name,
      state: ApprovalState.fromWire(json['status'] as String?),
      summary: name.isNotEmpty && summary.startsWith('$name: ')
          ? summary.substring(name.length + 2)
          : summary,
      amount: jsonDouble(json['amount']),
      reason: json['reason'] as String?,
      submittedAt: jsonDate(json['createdAt']),
      decisionNote: json['decisionNote'] as String?,
      approverName: json['approverName'] as String?,
    );
  }
}

/// An approve or reject. A rejection needs a [reason].
class ApprovalDecision {
  const ApprovalDecision({
    required this.id,
    required this.approve,
    this.reason,
  });

  final String id;
  final bool approve;
  final String? reason;

  String get action => approve ? 'approve' : 'reject';

  Map<String, dynamic> toJson() => {'note': ?trimmedOrNull(reason)};
}
