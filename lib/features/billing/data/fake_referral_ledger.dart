import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/data/referral_fixtures.dart';
import 'package:salesroot/features/billing/models/referral.dart';

/// The fake server's referral book: invites, the credit wallet and the rules
/// that turn them into balances. Billing redeems credits through it.
class FakeReferralLedger {
  FakeReferralLedger(this._backend);

  final FakeBackend _backend;

  static const int _creditDays = 365;
  static const int _expiringWindowDays = 30;

  FakeTable get referrals => _backend.table('referrals', referralFixtures);

  FakeTable get wallet => _backend.table('referral_wallet', walletFixtures);

  DateTime get now => _backend.graph.anchor;

  int get _inviteDays => referralProgramJson['InviteDays'] as int;

  bool _held(Map<String, dynamic> row) =>
      jsonDate(row['AvailableAt'])?.isAfter(now) ?? false;

  int _amount(Map<String, dynamic> row) => jsonInt(row['Amount']) ?? 0;

  int get onHold =>
      wallet.rows.where(_held).fold(0, (sum, row) => sum + _amount(row));

  /// Credit usable now.
  int get balance {
    final total = wallet.rows.fold(0, (sum, row) => sum + _amount(row));
    final usable = total - onHold;
    return usable < 0 ? 0 : usable;
  }

  Map<String, dynamic> overviewJson() {
    final rows = wallet.rows;
    final friends = referrals.rows;
    final statuses = [
      for (final row in friends)
        ReferralStatus.fromWire(row['Status'] as String?),
    ];
    final expiring = _expiring();
    final recent = [...friends]
      ..sort((a, b) => _lastActivity(b).compareTo(_lastActivity(a)));
    return {
      ...referralProgramJson,
      'Balance': balance,
      'OnHold': onHold,
      'HoldCount': rows.where(_held).length,
      'Earned': rows
          .where((row) => _amount(row) > 0)
          .fold(0, (sum, row) => sum + _amount(row)),
      'Used': -rows
          .where((row) => row['Kind'] == WalletEntryKind.redeemed.wire)
          .fold(0, (sum, row) => sum + _amount(row)),
      'Invited': friends.length,
      'Joined': statuses.where((s) => s.joined).length,
      'Paid': statuses.where((s) => s == ReferralStatus.bought).length,
      'ExpiringAmount': expiring.$1,
      'ExpiringAt': expiring.$2,
      'Recent': [for (final row in recent.take(2)) referralJson(row)],
    }..removeWhere((_, value) => value == null);
  }

  (int, String?) _expiring() {
    final until = now.add(const Duration(days: _expiringWindowDays));
    var amount = 0;
    DateTime? first;
    for (final row in wallet.rows) {
      final at = jsonDate(row['At']);
      if (at == null || _amount(row) <= 0) continue;
      final expires = at.add(const Duration(days: _creditDays));
      if (expires.isBefore(now) || expires.isAfter(until)) continue;
      amount += _amount(row);
      if (first == null || expires.isBefore(first)) first = expires;
    }
    final capped = amount > balance ? balance : amount;
    return (
      capped,
      first == null || capped == 0 ? null : AppDateUtils.toApiUtc(first),
    );
  }

  DateTime _lastActivity(Map<String, dynamic> row) =>
      jsonDate(row['BoughtAt']) ??
      jsonDate(row['RegisteredAt']) ??
      jsonDate(row['InvitedAt']) ??
      DateTime(2000);

  /// A referral row as the API returns it: masked contact, reward so far,
  /// hold and invite countdowns.
  Map<String, dynamic> referralJson(Map<String, dynamic> row) {
    final id = row['Id'];
    final credits = wallet.rows.where((w) => w['ReferralId'] == id);
    final reward = credits.fold(0, (sum, w) => sum + _amount(w));
    final heldUntil = credits
        .where(_held)
        .map((w) => jsonDate(w['AvailableAt']))
        .nonNulls
        .firstOrNull;
    final invitedAt = jsonDate(row['InvitedAt']) ?? now;
    final expires = invitedAt.add(Duration(days: _inviteDays));
    final pending = row['Status'] == ReferralStatus.pending.wire;
    return {
      'Id': id,
      'Name': row['Name'],
      'NameBn': row['NameBn'],
      'PhoneMasked': mask(row['Phone'] as String? ?? ''),
      'Status': row['Status'],
      'InvitedAt': row['InvitedAt'],
      'RegisteredAt': row['RegisteredAt'],
      'BoughtAt': row['BoughtAt'],
      'PlanName': row['PlanName'],
      'Reward': reward < 0 ? 0 : reward,
      'HoldHours': heldUntil == null
          ? null
          : (heldUntil.difference(now).inMinutes / 60).ceil(),
      'DaysLeft': pending ? _daysBetween(now, expires) : null,
    }..removeWhere((_, value) => value == null);
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final days = AppDateUtils.dateOnly(
      to,
    ).difference(AppDateUtils.dateOnly(from)).inHours;
    return (days / 24).round().clamp(0, 999);
  }

  Map<String, dynamic> entryJson(Map<String, dynamic> row) => {
    ...row,
    'Held': _held(row),
  };

  void redeem(int amount, String invoiceNumber, String planName) =>
      wallet.insert({
        'Kind': WalletEntryKind.redeemed.wire,
        'Amount': -amount,
        'At': AppDateUtils.toApiUtc(now),
        'InvoiceNumber': invoiceNumber,
        'PlanName': planName,
      });

  /// Who may be invited: a valid BD mobile or email, not on SalesRoot, not
  /// claimed by another referrer and not already waiting on this user.
  Map<String, dynamic> checkJson(String input) {
    final contact = normalize(input);
    if (contact == null) return {'Eligibility': InviteEligibility.invalid.wire};
    for (final row in referrals.rows) {
      if (row['Phone'] != contact) continue;
      final status = ReferralStatus.fromWire(row['Status'] as String?);
      if (status == ReferralStatus.pending) {
        return {
          'Eligibility': InviteEligibility.alreadyInvited.wire,
          'DaysLeft': referralJson(row)['DaysLeft'],
        };
      }
      if (status != ReferralStatus.expired) {
        return {'Eligibility': InviteEligibility.alreadyUser.wire};
      }
    }
    final graph = _backend.graph;
    if (graph.members.any((m) => normalize(m.phone) == contact)) {
      return {'Eligibility': InviteEligibility.alreadyUser.wire};
    }
    for (final person in graph.contacts) {
      if (normalize(person.phone) != contact &&
          person.email?.toLowerCase() != contact) {
        continue;
      }
      if (person.id % 4 == 0) {
        return {'Eligibility': InviteEligibility.referredByOther.wire};
      }
      if (person.id % 4 == 1) {
        return {'Eligibility': InviteEligibility.alreadyUser.wire};
      }
    }
    return {
      'Eligibility': InviteEligibility.eligible.wire,
      'Reward': referralProgramJson['RegisterReward'],
    };
  }

  /// A Bangladeshi mobile as 01XXXXXXXXX, or a lower-case email; null when
  /// it is neither.
  static String? normalize(String input) {
    final value = input.trim();
    if (value.contains('@')) {
      final email = value.toLowerCase();
      return RegExp(r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$').hasMatch(email)
          ? email
          : null;
    }
    var digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('880')) digits = digits.substring(2);
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits) ? digits : null;
  }

  static String mask(String contact) {
    if (contact.contains('@')) {
      final at = contact.indexOf('@');
      final head = contact.substring(0, at < 2 ? at : 2);
      return '$head•••${contact.substring(at)}';
    }
    if (contact.length < 7) return contact;
    return '${contact.substring(0, 5)}•••'
        '${contact.substring(contact.length - 2)}';
  }
}
