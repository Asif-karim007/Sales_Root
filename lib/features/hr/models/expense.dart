import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

/// Where a claim is in its workflow, in the order the status chips show.
enum ExpenseStage {
  pending('pending'),
  approved('approved'),
  paid('paid'),
  rejected('rejected');

  const ExpenseStage(this.wire);

  final String wire;

  /// An approved claim that has been reimbursed reads as paid.
  static ExpenseStage fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    if (status == approved.wire && json['paidAt'] != null) return paid;
    return values.firstWhere((s) => s.wire == status, orElse: () => pending);
  }
}

/// How many days back a claim may be dated.
const int expenseEntryDays = 30;

/// An expense category, with the amount above which a receipt is required.
class ExpenseType {
  const ExpenseType({
    required this.id,
    required this.code,
    required this.name,
    this.receiptRequiredAbove,
  });

  final String id;

  /// A stable key (`travel`, `food`…) the app picks an icon by.
  final String code;
  final LocalizedName name;

  /// Null when a receipt is never required.
  final double? receiptRequiredAbove;

  bool needsReceipt(double amount) {
    final above = receiptRequiredAbove;
    return above != null && amount > above;
  }

  factory ExpenseType.fromJson(Map<String, dynamic> json) => ExpenseType(
    id: jsonId(json['id']) ?? '',
    code: json['key'] as String? ?? '',
    name: LocalizedName.pair(json),
    receiptRequiredAbove: jsonDouble(json['receiptRequiredAbove']),
  );
}

/// A recent visit a claim can be linked to.
class ExpenseVisit {
  const ExpenseVisit({
    required this.id,
    this.companyId,
    this.companyName,
    this.visitedAt,
  });

  final String id;
  final String? companyId;
  final String? companyName;
  final DateTime? visitedAt;

  factory ExpenseVisit.fromJson(Map<String, dynamic> json) => ExpenseVisit(
    id: jsonId(json['id']) ?? '',
    companyId: jsonId(json['companyId']),
    companyName: json['companyName'] as String?,
    visitedAt: jsonDate(json['startedAt']),
  );
}

/// Every option the claim form needs.
class ExpenseLookups {
  const ExpenseLookups({
    this.types = const [],
    this.visits = const [],
    this.approverName,
  });

  final List<ExpenseType> types;
  final List<ExpenseVisit> visits;

  /// Null when nobody is above the employee.
  final String? approverName;
}

/// One expense claim.
class ExpenseClaim {
  const ExpenseClaim({
    required this.id,
    required this.cost,
    required this.stage,
    required this.typeId,
    required this.typeCode,
    required this.typeName,
    required this.claimedBy,
    required this.claimedByName,
    this.expenseDate,
    this.companyName,
    this.visitId,
    this.description,
    this.distanceKm,
    this.note,
    this.hasReceipt = false,
    this.createdOn,
  });

  final String id;
  final double cost;
  final ExpenseStage stage;
  final String typeId;
  final String typeCode;
  final LocalizedName typeName;

  /// The membership id of who claimed.
  final String claimedBy;
  final String claimedByName;
  final DateTime? expenseDate;
  final String? companyName;
  final String? visitId;
  final String? description;
  final double? distanceKm;

  /// The approver's note on the decision.
  final String? note;
  final bool hasReceipt;
  final DateTime? createdOn;

  bool get isPending => stage == ExpenseStage.pending;
  bool get canWithdraw => isPending;

  factory ExpenseClaim.fromJson(Map<String, dynamic> json) => ExpenseClaim(
    id: jsonId(json['id']) ?? '',
    cost: jsonDouble(json['amount']) ?? 0,
    stage: ExpenseStage.fromJson(json),
    typeId: jsonId(json['categoryId']) ?? '',
    typeCode: json['categoryKey'] as String? ?? '',
    typeName: LocalizedName.pair(json, 'category'),
    claimedBy: jsonId(json['membershipId']) ?? '',
    claimedByName: json['name'] as String? ?? '',
    expenseDate: jsonDay(json['spentOn']),
    companyName: json['companyName'] as String?,
    visitId: jsonId(json['visitId']),
    description: json['note'] as String?,
    distanceKm: jsonDouble(json['distanceKm']),
    note: json['decisionNote'] as String?,
    hasReceipt: json['receiptKey'] != null,
    createdOn: jsonDate(json['createdAt']),
  );
}

/// What the claim form sends. Write bodies omit null keys.
class ExpenseInput {
  const ExpenseInput({
    required this.categoryId,
    required this.spentOn,
    required this.amount,
    this.visit,
    this.note,
    this.receiptPath,
  });

  final String? categoryId;
  final DateTime? spentOn;
  final double? amount;
  final ExpenseVisit? visit;
  final String? note;

  /// A local photo, uploaded before the claim is sent.
  final String? receiptPath;

  Map<String, dynamic> toJson({String? receiptKey}) {
    final day = spentOn;
    return {
      'categoryId': categoryId,
      'amount': amount,
      'spentOn': day == null ? null : AppDateUtils.toApiDateOnly(day),
      'note': trimmedOrNull(note),
      'receiptKey': receiptKey,
      'visitId': visit?.id,
      'companyId': visit?.companyId,
    }..removeWhere((_, value) => value == null);
  }
}

/// Paging and the status chip for the claim list.
class ExpenseQuery {
  const ExpenseQuery({this.page = 1, this.stage});

  final int page;
  final ExpenseStage? stage;

  ExpenseQuery next(int page) => ExpenseQuery(page: page, stage: stage);

  Map<String, dynamic> toQuery() => {
    'status': ?stage?.wire,
    ...pageQuery(page),
  };
}

enum ExpenseField { type, amount, date, futureDate, receipt }

/// The claim form while it is being filled in.
class ExpenseDraft {
  const ExpenseDraft({
    this.typeId,
    this.amount,
    this.date,
    this.visit,
    this.receipt,
    this.note = '',
  });

  final String? typeId;
  final double? amount;
  final DateTime? date;
  final ExpenseVisit? visit;

  /// The local path of the receipt photo.
  final String? receipt;
  final String note;

  /// A claim is never dated after [today], compared on the local calendar
  /// date so a claim made just after midnight is still today's.
  Set<ExpenseField> errors(List<ExpenseType> types, DateTime today) {
    final type = types.where((t) => t.id == typeId).firstOrNull;
    final amount = this.amount ?? 0;
    final date = this.date;
    return {
      if (type == null) ExpenseField.type,
      if (amount <= 0) ExpenseField.amount,
      if (date == null) ExpenseField.date,
      if (date != null &&
          AppDateUtils.dateOnly(date).isAfter(AppDateUtils.dateOnly(today)))
        ExpenseField.futureDate,
      if (type != null && receipt == null && type.needsReceipt(amount))
        ExpenseField.receipt,
    };
  }

  ExpenseInput toInput() => ExpenseInput(
    categoryId: typeId,
    spentOn: date,
    amount: amount,
    visit: visit,
    note: note,
    receiptPath: receipt,
  );

  ExpenseDraft copyWith({
    String? typeId,
    double? Function()? amount,
    DateTime? date,
    ExpenseVisit? Function()? visit,
    String? Function()? receipt,
    String? note,
  }) => ExpenseDraft(
    typeId: typeId ?? this.typeId,
    amount: amount != null ? amount() : this.amount,
    date: date ?? this.date,
    visit: visit != null ? visit() : this.visit,
    receipt: receipt != null ? receipt() : this.receipt,
    note: note ?? this.note,
  );
}
