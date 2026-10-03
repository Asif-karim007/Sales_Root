import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';

/// Where a claim is in its workflow, in the order the status chips show.
enum ExpenseStage {
  pending('pending'),
  returned('returned'),
  approved('approved'),
  paid('paid'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const ExpenseStage(this.wire);

  final String wire;

  /// `WorkflowStatus` plus `SettlementStatus`: an approved claim that has
  /// been settled reads as paid.
  static ExpenseStage fromWire(String? workflow, String? settlement) {
    if (workflow == 'approved' && settlement == 'paid') return paid;
    return values.firstWhere((s) => s.wire == workflow, orElse: () => pending);
  }
}

/// An expense category, with the amount above which a receipt is required.
class ExpenseType {
  const ExpenseType({
    required this.id,
    required this.code,
    required this.name,
    this.receiptRequiredAbove,
  });

  final int id;

  /// A stable key (`Travel`, `Meals`…) the app picks an icon by.
  final String code;
  final LocalizedName name;

  /// Null when a receipt is never required.
  final double? receiptRequiredAbove;

  bool needsReceipt(double amount) {
    final above = receiptRequiredAbove;
    return above != null && amount > above;
  }

  factory ExpenseType.fromJson(Map<String, dynamic> json) => ExpenseType(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String? ?? '',
    name: LocalizedName.fromJson(json),
    receiptRequiredAbove: jsonDouble(json['ReceiptRequiredAbove']),
  );
}

/// A recent visit a claim can be linked to; its locations prefill the route.
class ExpenseVisit {
  const ExpenseVisit({
    required this.id,
    required this.prospectId,
    required this.prospectName,
    this.visitedAt,
    this.startLocation,
    this.endLocation,
  });

  final int id;
  final int prospectId;
  final String prospectName;
  final DateTime? visitedAt;
  final String? startLocation;
  final String? endLocation;

  factory ExpenseVisit.fromJson(Map<String, dynamic> json) => ExpenseVisit(
    id: jsonInt(json['Id']) ?? 0,
    prospectId: jsonInt(json['ProspectId']) ?? 0,
    prospectName: json['ProspectName'] as String? ?? '',
    visitedAt: jsonDate(json['VisitedAt']),
    startLocation: json['StartLocation'] as String?,
    endLocation: json['EndLocation'] as String?,
  );
}

/// Every option the claim form needs.
class ExpenseLookups {
  const ExpenseLookups({
    this.types = const [],
    this.visits = const [],
    this.approverName,
    this.managerName,
    this.managerApprovalAbove,
    this.entryDaysLimit = 30,
  });

  final List<ExpenseType> types;
  final List<ExpenseVisit> visits;
  final LocalizedName? approverName;

  /// Who approves a second time above [managerApprovalAbove].
  final LocalizedName? managerName;
  final double? managerApprovalAbove;

  /// How many days back a claim may be dated.
  final int entryDaysLimit;

  factory ExpenseLookups.fromJson(Map<String, dynamic> json) {
    final policy = json['Policy'] as Map<String, dynamic>? ?? const {};
    return ExpenseLookups(
      types: jsonList(json['Types'], ExpenseType.fromJson),
      visits: jsonList(json['Visits'], ExpenseVisit.fromJson),
      approverName: jsonLocalized(json['ApproverName'], json['ApproverNameBn']),
      managerName: jsonLocalized(json['ManagerName'], json['ManagerNameBn']),
      managerApprovalAbove: jsonDouble(policy['ManagerApprovalAbove']),
      entryDaysLimit: jsonInt(policy['EntryDaysLimit']) ?? 30,
    );
  }
}

/// One receipt against a claim.
class ExpenseAttachment {
  const ExpenseAttachment({required this.name, this.url});

  final String name;

  /// A local file path until the real upload exists.
  final String? url;

  factory ExpenseAttachment.fromJson(Map<String, dynamic> json) =>
      ExpenseAttachment(
        name: json['Name'] as String? ?? '',
        url: json['Url'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'Name': name, 'Url': url}..removeWhere((_, value) => value == null);
}

/// One expense claim.
class ExpenseClaim {
  const ExpenseClaim({
    required this.id,
    required this.title,
    required this.cost,
    required this.stage,
    required this.typeId,
    required this.typeCode,
    required this.typeName,
    required this.claimedBy,
    required this.claimedByName,
    this.code,
    this.personCount = 1,
    this.expenseDate,
    this.prospectId,
    this.prospectName,
    this.visitId,
    this.description,
    this.startLocation,
    this.endLocation,
    this.note,
    this.approvedByName,
    this.approvalStep = 1,
    this.attachments = const [],
    this.createdOn,
    this.canWithdraw = false,
  });

  final int id;
  final String? code;
  final String title;
  final double cost;
  final ExpenseStage stage;
  final int typeId;
  final String typeCode;
  final LocalizedName typeName;
  final int claimedBy;
  final LocalizedName claimedByName;
  final int personCount;
  final DateTime? expenseDate;
  final int? prospectId;
  final String? prospectName;
  final int? visitId;
  final String? description;
  final String? startLocation;
  final String? endLocation;

  /// The return or rejection note.
  final String? note;
  final LocalizedName? approvedByName;

  /// 2 once the first approver has passed a claim that needs the manager too.
  final int approvalStep;
  final List<ExpenseAttachment> attachments;
  final DateTime? createdOn;
  final bool canWithdraw;

  bool get isPending => stage == ExpenseStage.pending;

  bool get hasRoute =>
      (startLocation ?? '').isNotEmpty || (endLocation ?? '').isNotEmpty;

  factory ExpenseClaim.fromJson(Map<String, dynamic> json) => ExpenseClaim(
    id: jsonInt(json['ID'] ?? json['Id']) ?? 0,
    code: json['Code'] as String?,
    title: json['Title'] as String? ?? '',
    cost: jsonDouble(json['ClaimedTotal']) ?? 0,
    stage: ExpenseStage.fromWire(
      json['WorkflowStatus'] as String?,
      json['SettlementStatus'] as String?,
    ),
    typeId: jsonInt(json['PrimaryTypeId']) ?? 0,
    typeCode: json['PrimaryTypeCode'] as String? ?? '',
    typeName: jsonLocalizedOrEmpty(json['PrimaryType'], json['PrimaryTypeBn']),
    claimedBy: jsonInt(json['ClaimedBy']) ?? 0,
    claimedByName: jsonLocalizedOrEmpty(
      json['ClaimedByName'],
      json['ClaimedByNameBn'],
    ),
    personCount: jsonInt(json['PersonCount']) ?? 1,
    expenseDate: expenseDay(json['IncurredFrom']),
    prospectId: jsonInt(json['ProspectId']),
    prospectName: json['ProspectName'] as String?,
    visitId: jsonInt(json['VisitId']),
    description: json['Description'] as String?,
    startLocation: json['StartLocation'] as String?,
    endLocation: json['EndLocation'] as String?,
    note: json['LastReturnNote'] as String?,
    approvedByName: jsonLocalized(
      json['ApprovedByName'],
      json['ApprovedByNameBn'],
    ),
    approvalStep: jsonInt(json['ApprovalStep']) ?? 1,
    attachments: jsonList(json['Attachments'], ExpenseAttachment.fromJson),
    createdOn: jsonDate(json['CreatedOn']),
    canWithdraw: jsonBool(json['CanWithdraw']),
  );
}

/// A date-only server field (`2026-10-04`) as a local calendar day.
DateTime? expenseDay(dynamic value) {
  if (value is! String || value.length < 10) return null;
  final date = DateTime.tryParse(value.substring(0, 10));
  return date == null ? null : DateTime(date.year, date.month, date.day);
}

/// What the claim form sends. Write bodies omit null keys.
class ExpenseInput {
  const ExpenseInput({
    required this.title,
    required this.expenseTypeId,
    required this.incurredOn,
    required this.claimedAmount,
    this.personCount = 1,
    this.startLocation,
    this.endLocation,
    this.prospectId,
    this.visitId,
    this.description,
    this.attachments = const [],
  });

  final String? title;
  final int? expenseTypeId;
  final DateTime? incurredOn;
  final double? claimedAmount;
  final int personCount;
  final String? startLocation;
  final String? endLocation;
  final int? prospectId;
  final int? visitId;
  final String? description;
  final List<ExpenseAttachment> attachments;

  Map<String, dynamic> toJson() {
    final day = incurredOn;
    return {
      'Title': trimmedOrNull(title),
      'ExpenseTypeId': expenseTypeId,
      'IncurredOn': day == null ? null : AppDateUtils.toApiDateOnly(day),
      'ClaimedAmount': claimedAmount,
      'PersonCount': personCount,
      'StartLocation': trimmedOrNull(startLocation),
      'EndLocation': trimmedOrNull(endLocation),
      'ProspectId': prospectId,
      'VisitId': visitId,
      'Description': trimmedOrNull(description),
      'Attachments': attachments.isEmpty
          ? null
          : [for (final file in attachments) file.toJson()],
    }..removeWhere((_, value) => value == null);
  }
}

/// Paging and the status chip for the claim list.
class ExpenseQuery {
  const ExpenseQuery({this.page = 1, this.stage});

  final int page;
  final ExpenseStage? stage;

  ExpenseQuery next(int page) => ExpenseQuery(page: page, stage: stage);
}

enum ExpenseField { type, amount, date, futureDate, receipt }

/// The claim form while it is being filled in.
class ExpenseDraft {
  const ExpenseDraft({
    this.typeId,
    this.amount,
    this.date,
    this.visit,
    this.from = '',
    this.to = '',
    this.personCount = 1,
    this.receipts = const [],
    this.note = '',
  });

  final int? typeId;
  final double? amount;
  final DateTime? date;
  final ExpenseVisit? visit;
  final String from;
  final String to;
  final int personCount;

  /// Local paths of the receipt photos.
  final List<String> receipts;
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
      if (type != null && receipts.isEmpty && type.needsReceipt(amount))
        ExpenseField.receipt,
    };
  }

  /// The claim title is the category's name, as the web form does.
  ExpenseInput toInput(List<ExpenseType> types) {
    final type = types.where((t) => t.id == typeId).firstOrNull;
    final visit = this.visit;
    return ExpenseInput(
      title: type?.name.en,
      expenseTypeId: typeId,
      incurredOn: date,
      claimedAmount: amount,
      personCount: personCount,
      startLocation: from,
      endLocation: to,
      prospectId: visit?.prospectId,
      visitId: visit?.id,
      description: note,
      attachments: [
        for (final path in receipts)
          ExpenseAttachment(name: path.split('/').last, url: path),
      ],
    );
  }

  ExpenseDraft copyWith({
    int? typeId,
    double? Function()? amount,
    DateTime? date,
    ExpenseVisit? Function()? visit,
    String? from,
    String? to,
    int? personCount,
    List<String>? receipts,
    String? note,
  }) => ExpenseDraft(
    typeId: typeId ?? this.typeId,
    amount: amount != null ? amount() : this.amount,
    date: date ?? this.date,
    visit: visit != null ? visit() : this.visit,
    from: from ?? this.from,
    to: to ?? this.to,
    personCount: personCount ?? this.personCount,
    receipts: receipts ?? this.receipts,
    note: note ?? this.note,
  );
}
