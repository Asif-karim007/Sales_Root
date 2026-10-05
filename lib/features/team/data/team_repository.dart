import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

abstract interface class TeamRepository {
  /// The members a filter shows, with `counts` per filter as a facet.
  Future<PageResult<Member>> members(MemberQuery query);

  /// Every member who has joined, for pickers and the organogram.
  Future<List<Member>> directory();

  Future<Member> member(String id);

  Future<Member> updateMember(String id, MemberUpdate update);

  /// Removes the member and hands their work to [successorId].
  Future<void> removeMember(String id, {required String successorId});

  Future<List<Invite>> invites();

  Future<Invite> invite(String id);

  Future<Invite> sendInvite(InviteInput input);

  Future<void> revokeInvite(String id);

  Future<List<SeatPack>> seatPacks(String planKey);
}
