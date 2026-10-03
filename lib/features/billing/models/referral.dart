import 'package:salesroot/core/utils/json_fields.dart';

enum ReferralStatus {
  pending('Pending'),
  registered('Registered'),
  bought('Bought'),
  notEligible('NotEligible'),
  expired('Expired'),
  reversed('Reversed');

  const ReferralStatus(this.wire);

  final String wire;

  bool get joined => this == registered || this == bought || this == reversed;

  static ReferralStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

class Referral {
  const Referral({
    required this.id,
    required this.name,
    required this.phoneMasked,
    required this.status,
    required this.invitedAt,
    this.registeredAt,
    this.boughtAt,
    this.planName,
    this.reward = 0,
    this.holdHours = 0,
    this.daysLeft = 0,
  });

  final int id;
  final LocalizedName name;
  final String phoneMasked;
  final ReferralStatus status;
  final DateTime invitedAt;
  final DateTime? registeredAt;
  final DateTime? boughtAt;
  final String? planName;

  /// Credit earned from this friend so far.
  final int reward;

  /// Hours until the registration credit can be used.
  final int holdHours;

  /// Days left for a pending invite to register.
  final int daysLeft;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    phoneMasked: json['PhoneMasked'] as String? ?? '',
    status: ReferralStatus.fromWire(json['Status'] as String?),
    invitedAt: jsonDate(json['InvitedAt']) ?? DateTime(2000),
    registeredAt: jsonDate(json['RegisteredAt']),
    boughtAt: jsonDate(json['BoughtAt']),
    planName: json['PlanName'] as String?,
    reward: jsonInt(json['Reward']) ?? 0,
    holdHours: jsonInt(json['HoldHours']) ?? 0,
    daysLeft: jsonInt(json['DaysLeft']) ?? 0,
  );
}

class ReferralQuery {
  const ReferralQuery({this.status, this.page = 1});

  final ReferralStatus? status;
  final int page;
}

/// A reward step: [paid] friends who bought a plan earn [reward] taka or
/// [freeMonths] free months.
class Milestone {
  const Milestone({required this.paid, this.reward = 0, this.freeMonths = 0});

  final int paid;
  final int reward;
  final int freeMonths;

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    paid: jsonInt(json['Paid']) ?? 0,
    reward: jsonInt(json['Reward']) ?? 0,
    freeMonths: jsonInt(json['FreeMonths']) ?? 0,
  );
}

/// The referral code, the program rules and the wallet, in one call.
class ReferralOverview {
  const ReferralOverview({
    required this.code,
    required this.link,
    required this.registerReward,
    required this.conversionPercent,
    required this.conversionCap,
    required this.trialDays,
    required this.milestones,
    required this.balance,
    required this.onHold,
    required this.holdCount,
    required this.earned,
    required this.used,
    required this.invited,
    required this.joined,
    required this.paid,
    this.expiringAmount = 0,
    this.expiringAt,
    this.recent = const [],
  });

  final String code;
  final String link;
  final int registerReward;
  final int conversionPercent;
  final int conversionCap;
  final int trialDays;
  final List<Milestone> milestones;

  /// Credit usable now.
  final int balance;
  final int onHold;
  final int holdCount;
  final int earned;
  final int used;
  final int invited;
  final int joined;
  final int paid;
  final int expiringAmount;
  final DateTime? expiringAt;
  final List<Referral> recent;

  /// The next cash milestone, or null when all are reached.
  Milestone? get nextMilestone {
    for (final milestone in milestones) {
      if (milestone.paid > paid && milestone.reward > 0) return milestone;
    }
    for (final milestone in milestones) {
      if (milestone.paid > paid) return milestone;
    }
    return null;
  }

  factory ReferralOverview.fromJson(Map<String, dynamic> json) =>
      ReferralOverview(
        code: json['Code'] as String? ?? '',
        link: json['Link'] as String? ?? '',
        registerReward: jsonInt(json['RegisterReward']) ?? 0,
        conversionPercent: jsonInt(json['ConversionPercent']) ?? 0,
        conversionCap: jsonInt(json['ConversionCap']) ?? 0,
        trialDays: jsonInt(json['TrialDays']) ?? 0,
        milestones: jsonList(json['Milestones'], Milestone.fromJson),
        balance: jsonInt(json['Balance']) ?? 0,
        onHold: jsonInt(json['OnHold']) ?? 0,
        holdCount: jsonInt(json['HoldCount']) ?? 0,
        earned: jsonInt(json['Earned']) ?? 0,
        used: jsonInt(json['Used']) ?? 0,
        invited: jsonInt(json['Invited']) ?? 0,
        joined: jsonInt(json['Joined']) ?? 0,
        paid: jsonInt(json['Paid']) ?? 0,
        expiringAmount: jsonInt(json['ExpiringAmount']) ?? 0,
        expiringAt: jsonDate(json['ExpiringAt']),
        recent: jsonList(json['Recent'], Referral.fromJson),
      );
}

enum WalletEntryKind {
  welcome('Welcome'),
  registration('Registration'),
  conversion('Conversion'),
  milestone('Milestone'),
  redeemed('Redeemed'),
  reversed('Reversed');

  const WalletEntryKind(this.wire);

  final String wire;

  static WalletEntryKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => welcome);
}

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.at,
    required this.name,
    this.availableAt,
    this.held = false,
    this.invoiceNumber,
    this.planName,
    this.milestone = 0,
  });

  final int id;
  final WalletEntryKind kind;
  final int amount;
  final DateTime at;

  /// The friend, or who referred the user for a welcome credit.
  final LocalizedName name;
  final DateTime? availableAt;
  final bool held;
  final String? invoiceNumber;
  final String? planName;
  final int milestone;

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
    id: jsonInt(json['Id']) ?? 0,
    kind: WalletEntryKind.fromWire(json['Kind'] as String?),
    amount: jsonInt(json['Amount']) ?? 0,
    at: jsonDate(json['At']) ?? DateTime(2000),
    name: LocalizedName.fromJson(json),
    availableAt: jsonDate(json['AvailableAt']),
    held: jsonBool(json['Held']),
    invoiceNumber: json['InvoiceNumber'] as String?,
    planName: json['PlanName'] as String?,
    milestone: jsonInt(json['Milestone']) ?? 0,
  );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.memberId,
    required this.name,
    required this.paid,
    required this.isMe,
  });

  final int memberId;
  final LocalizedName name;
  final int paid;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        memberId: jsonInt(json['MemberId']) ?? 0,
        name: LocalizedName.fromJson(json),
        paid: jsonInt(json['Paid']) ?? 0,
        isMe: jsonBool(json['IsMe']),
      );
}

/// A credit worth celebrating once (#190).
class RewardMoment {
  const RewardMoment({
    required this.id,
    required this.name,
    required this.amount,
    required this.holdHours,
    required this.overview,
  });

  final int id;
  final LocalizedName name;
  final int amount;
  final int holdHours;

  /// The wallet after the reward.
  final ReferralOverview overview;

  factory RewardMoment.fromJson(Map<String, dynamic> json) => RewardMoment(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    amount: jsonInt(json['Amount']) ?? 0,
    holdHours: jsonInt(json['HoldHours']) ?? 0,
    overview: ReferralOverview.fromJson(
      json['Overview'] as Map<String, dynamic>? ?? const {},
    ),
  );
}

enum InviteEligibility {
  eligible('Eligible'),
  alreadyUser('AlreadyUser'),
  referredByOther('ReferredByOther'),
  alreadyInvited('AlreadyInvited'),
  invalid('Invalid');

  const InviteEligibility(this.wire);

  final String wire;

  static InviteEligibility fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => invalid);
}

class InviteCheck {
  const InviteCheck({
    required this.eligibility,
    this.daysLeft = 0,
    this.reward = 0,
  });

  final InviteEligibility eligibility;

  /// For an earlier invite still waiting.
  final int daysLeft;
  final int reward;

  factory InviteCheck.fromJson(Map<String, dynamic> json) => InviteCheck(
    eligibility: InviteEligibility.fromWire(json['Eligibility'] as String?),
    daysLeft: jsonInt(json['DaysLeft']) ?? 0,
    reward: jsonInt(json['Reward']) ?? 0,
  );
}

/// A CRM contact with a phone, offered when inviting.
class InviteContact {
  const InviteContact({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
  });

  final int id;
  final String name;
  final String phone;
  final String? company;

  factory InviteContact.fromJson(Map<String, dynamic> json) => InviteContact(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    phone: json['Phone'] as String? ?? '',
    company: json['CompanyName'] as String?,
  );
}
