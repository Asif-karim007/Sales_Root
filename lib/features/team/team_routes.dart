import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/team/view/chat_info_screen.dart';
import 'package:salesroot/features/team/view/chat_list_screen.dart';
import 'package:salesroot/features/team/view/chat_oversight_screen.dart';
import 'package:salesroot/features/team/view/chat_screen.dart';
import 'package:salesroot/features/team/view/file_detail_screen.dart';
import 'package:salesroot/features/team/view/files_screen.dart';
import 'package:salesroot/features/team/view/invite_form_screen.dart';
import 'package:salesroot/features/team/view/invite_sent_screen.dart';
import 'package:salesroot/features/team/view/member_detail_screen.dart';
import 'package:salesroot/features/team/view/new_chat_screen.dart';
import 'package:salesroot/features/team/view/organogram_screen.dart';
import 'package:salesroot/features/team/view/remove_member_screen.dart';
import 'package:salesroot/features/team/view/team_screen.dart';
import 'package:salesroot/features/team/view/upload_screen.dart';

final teamBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.team,
      redirect: requireAccess(AppModule.team),
      builder: (context, state) => const TeamScreen(),
    ),
  ],
);

final List<RouteBase> teamRoutes = [
  GoRoute(
    path: Routes.teamInvite,
    redirect: requireAccess(AppModule.team, ModuleRight.add),
    builder: (context, state) => const InviteFormScreen(),
  ),
  GoRoute(
    path: Routes.teamInviteSent,
    redirect: requireAccess(AppModule.team, ModuleRight.add),
    builder: (context, state) =>
        InviteSentScreen(inviteId: _query(state, 'id') ?? ''),
  ),
  GoRoute(
    path: Routes.member,
    redirect: requireAccess(AppModule.team),
    builder: (context, state) => MemberDetailScreen(memberId: idParam(state)),
  ),
  GoRoute(
    path: Routes.memberRemove,
    redirect: requireAccess(AppModule.team, ModuleRight.delete),
    builder: (context, state) => RemoveMemberScreen(memberId: idParam(state)),
  ),
  GoRoute(
    path: Routes.organogram,
    redirect: requireAccess(AppModule.team),
    builder: (context, state) => const OrganogramScreen(),
  ),
  GoRoute(
    path: Routes.chats,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) =>
        ChatListScreen(leadId: _query(state, 'leadId')),
  ),
  GoRoute(
    path: Routes.chatNew,
    redirect: requireAccess(AppModule.chat, ModuleRight.add),
    builder: (context, state) => const NewChatScreen(),
  ),
  GoRoute(
    path: Routes.chatOversight,
    redirect: requireAccess(AppModule.chatOversight),
    builder: (context, state) => const ChatOversightScreen(),
  ),
  GoRoute(
    path: Routes.chat,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) => ChatScreen(threadId: idParam(state)),
  ),
  GoRoute(
    path: Routes.chatInfo,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) => ChatInfoScreen(threadId: idParam(state)),
  ),
  GoRoute(
    path: Routes.files,
    redirect: requireAccess(AppModule.files),
    builder: (context, state) => const FilesScreen(),
  ),
  GoRoute(
    path: Routes.fileUpload,
    redirect: requireAccess(AppModule.files, ModuleRight.add),
    builder: (context, state) => UploadScreen(
      folderId: _query(state, 'folderId'),
      replaceFileId: _query(state, 'fileId'),
      leadId: _query(state, 'leadId'),
    ),
  ),
  GoRoute(
    path: Routes.file,
    redirect: requireAccess(AppModule.files),
    builder: (context, state) => FileDetailScreen(fileId: idParam(state)),
  ),
];

String? _query(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key];
  return value == null || value.isEmpty ? null : value;
}
