import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/widgets/widgets.dart';

class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.member,
    this.onTap,
    this.leading,
    this.trailing,
    this.chevron = true,
  });

  final Member member;

  /// Defaults to opening the member.
  final VoidCallback? onTap;

  /// Sits before the avatar, like a selection tick.
  final Widget? leading;

  /// Replaces the status tag.
  final Widget? trailing;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final name = context.name(member.name);
    return SrListRow(
      title: name,
      subtitle: context.memberSubtitle(member),
      leading: _leading(context, name),
      trailing: trailing ?? context.memberStatusTag(member),
      chevron: chevron,
      onTap: onTap ?? () => context.push(Routes.memberFor(member.id)),
    );
  }

  Widget _leading(BuildContext context, String name) {
    final avatar = SrAvatar(
      name: context.avatarName(name),
      imageUrl: member.imageUrl,
    );
    final leading = this.leading;
    if (leading == null) return avatar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [leading, const SizedBox(width: 12), avatar],
    );
  }
}
