import 'package:salesroot/core/utils/json_fields.dart';

enum ReferralStatus {
  pending('pending'),
  registered('registered'),
  bought('converted'),
  notEligible('already_registered'),
  expired('expired'),
  reversed('reversed');

  const ReferralStatus(this.wire);

  final String wire;

  static ReferralStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

/// A friend invited with the user's code, from `GET referrals`.
class Referral {
  const Referral({
    required this.id,
    required this.contact,
    required this.status,
    this.name,
    this.invitedAt,
    this.registeredAt,
    this.boughtAt,
    this.reward = 0,
  });

  final String id;

  /// The friend's masked phone or email, e.g. `se***@example.com`.
  final String contact;
  final ReferralStatus status;

  /// The name the friend signed up with.
  final String? name;
  final DateTime? invitedAt;
  final DateTime? registeredAt;
  final DateTime? boughtAt;

  /// Credit earned from this friend so far.
  final int reward;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    id: jsonId(json['id']) ?? '',
    contact:
        json['phoneMasked'] as String? ?? json['emailMasked'] as String? ?? '',
    status: ReferralStatus.fromWire(json['status'] as String?),
    name: json['registeredName'] as String?,
    invitedAt: jsonDate(json['createdAt']),
    registeredAt: jsonDate(json['registeredAt']),
    boughtAt: jsonDate(json['convertedAt']),
    reward:
        ((jsonDouble(json['signupReward']) ?? 0) +
                (jsonDouble(json['conversionReward']) ?? 0))
            .round(),
  );
}

/// The next reward the credits can buy: [credits] in all, [missing] still
/// to earn, about [referralsNeeded] paying friends away.
class NextPrize {
  const NextPrize({
    required this.name,
    required this.credits,
    required this.missing,
    required this.referralsNeeded,
  });

  final LocalizedName name;
  final int credits;
  final int missing;
  final int referralsNeeded;

  double get progress =>
      credits <= 0 ? 0 : ((credits - missing) / credits).clamp(0, 1);

  factory NextPrize.fromJson(Map<String, dynamic> json) => NextPrize(
    name: LocalizedName.of(json),
    credits: jsonDouble(json['credits'])?.round() ?? 0,
    missing: jsonDouble(json['missing'])?.round() ?? 0,
    referralsNeeded: jsonInt(json['referralsNeeded']) ?? 0,
  );
}

/// The referral code, the campaign's rules, the wallet and the latest
/// invites: `GET referrals`.
class ReferralOverview {
  const ReferralOverview({
    required this.code,
    required this.link,
    required this.registerReward,
    required this.conversionPercent,
    required this.conversionCap,
    required this.trialDays,
    required this.friendCredits,
    required this.holdDays,
    required this.balance,
    required this.onHold,
    required this.earned,
    required this.invited,
    required this.joined,
    required this.paid,
    this.expiringAmount = 0,
    this.nextPrize,
    this.recent = const [],
    this.shareText = const LocalizedName('', ''),
  });

  final String code;
  final String link;
  final int registerReward;
  final int conversionPercent;
  final int conversionCap;

  /// The extra trial days a friend gets.
  final int trialDays;

  /// The credits a friend gets on sign-up.
  final int friendCredits;

  /// Days a new credit is held before it can be used.
  final int holdDays;

  /// Credit usable now.
  final int balance;
  final int onHold;
  final int earned;
  final int invited;
  final int joined;
  final int paid;

  /// Credit that expires within 30 days.
  final int expiringAmount;
  final NextPrize? nextPrize;
  final List<Referral> recent;

  /// The server's invite message with the link, in both languages.
  final LocalizedName shareText;

  factory ReferralOverview.fromJson(Map<String, dynamic> json) {
    final campaign = jsonMap(json['campaign']);
    final wallet = jsonMap(json['wallet']);
    final stats = jsonMap(json['stats']);
    int amount(Map<String, dynamic> from, String key) =>
        jsonDouble(from[key])?.round() ?? 0;
    return ReferralOverview(
      code: json['code'] as String? ?? '',
      link: json['link'] as String? ?? '',
      registerReward: amount(campaign, 'signup_credits'),
      conversionPercent: amount(campaign, 'conversion_pct'),
      conversionCap: amount(campaign, 'conversion_cap'),
      trialDays: jsonInt(campaign['referee_trial_days']) ?? 0,
      friendCredits: amount(campaign, 'referee_credits'),
      holdDays: jsonInt(campaign['hold_days']) ?? 0,
      balance: amount(wallet, 'spendable'),
      onHold: amount(wallet, 'held'),
      expiringAmount: amount(wallet, 'expiring30d'),
      earned: amount(stats, 'earned'),
      invited: jsonInt(stats['total']) ?? 0,
      joined: jsonInt(stats['registered']) ?? 0,
      paid: jsonInt(stats['converted']) ?? 0,
      nextPrize: jsonObject(json['nextPrize'], NextPrize.fromJson),
      recent: jsonList(jsonMap(json['history'])['items'], Referral.fromJson),
      shareText: LocalizedName.of(jsonMap(json['share'])['whatsapp']),
    );
  }
}

/// One credit or debit in the referral wallet, from `GET wallet/transactions`.
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.amount,
    this.reason,
    this.at,
    this.availableAt,
    this.held = false,
  });

  final String id;

  /// Negative when credits were spent.
  final int amount;

  /// The server's reason, e.g. `signup` or `redeem`.
  final String? reason;
  final DateTime? at;
  final DateTime? availableAt;
  final bool held;

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
    id: jsonId(json['id']) ?? '',
    amount: jsonDouble(json['amount'] ?? json['credits'])?.round() ?? 0,
    reason: (json['reason'] ?? json['kind'] ?? json['type']) as String?,
    at: jsonDate(json['createdAt']),
    availableAt: jsonDate(json['availableAt']),
    held: json['status'] == 'held',
  );
}

/// Whether a phone or email can still be referred: `GET referrals/check`.
enum InviteEligibility {
  eligible('eligible'),
  alreadyUser('already_registered'),
  alreadyInvited('pending'),
  invalid('invalid');

  const InviteEligibility(this.wire);

  final String wire;

  static InviteEligibility fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => invalid);
}

/// What `POST referrals` answers: the referral when one was recorded, and
/// the server's words for the outcome.
class InviteResult {
  const InviteResult({required this.message, this.id});

  final LocalizedName message;

  /// Null when nothing was recorded, e.g. the contact already uses SalesRoot.
  final String? id;

  factory InviteResult.fromJson(Map<String, dynamic> json) => InviteResult(
    message: LocalizedName.of(json['message']),
    id: jsonId(json['id']),
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

  final String id;
  final String name;
  final String phone;
  final String? company;

  factory InviteContact.fromJson(Map<String, dynamic> json) => InviteContact(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    company: json['companyName'] as String?,
  );
}
