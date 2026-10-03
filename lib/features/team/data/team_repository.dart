import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

abstract interface class TeamRepository {
  /// One page of members, with `Counts` facets for the filter chips.
  Future<PageResult<Member>> members(MemberQuery query);

  /// Every member, for pickers and the organogram.
  Future<List<Member>> directory();

  Future<Member> member(int id);

  Future<Member> updateMember(int id, MemberUpdate update);

  /// Hands the member's work to someone else, then removes them.
  Future<void> removeMember(int id, RemovalInput input);

  Future<List<Invite>> invites();

  Future<Invite> invite(int id);

  Future<Invite> sendInvite(InviteInput input);

  Future<Invite> resendInvite(int id);

  Future<void> revokeInvite(int id);

  Future<List<SeatPack>> seatPacks();
}
