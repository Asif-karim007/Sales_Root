import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/models/referral.dart';

abstract interface class ReferralRepository {
  Future<ReferralOverview> overview();

  Future<PageResult<Referral>> list(ReferralQuery query);

  Future<PageResult<WalletEntry>> wallet(int page);

  /// This month's paid referrals per team member.
  Future<List<LeaderboardEntry>> leaderboard();

  Future<InviteCheck> check(String contact);

  /// Records an invite; with [sendSms] the server also texts the link.
  Future<Referral> invite(String contact, {required bool sendSms});

  /// CRM contacts with a phone, to invite from.
  Future<List<InviteContact>> contacts(String term, int page);

  /// A credit the app has not celebrated yet (#190).
  Future<RewardMoment?> pendingReward();

  Future<void> markRewardSeen(int id);
}
