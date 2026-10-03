import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final teamBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.team,
      redirect: requireAccess(AppModule.team),
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> teamRoutes = [
  GoRoute(
    path: Routes.teamInvite,
    redirect: requireAccess(AppModule.team, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.teamInviteSent,
    redirect: requireAccess(AppModule.team, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.member,
    redirect: requireAccess(AppModule.team),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.memberRemove,
    redirect: requireAccess(AppModule.team, ModuleRight.delete),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.organogram,
    redirect: requireAccess(AppModule.team),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.chats,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.chatNew,
    redirect: requireAccess(AppModule.chat, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.chatOversight,
    redirect: requireAccess(AppModule.chatOversight),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.chat,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.chatInfo,
    redirect: requireAccess(AppModule.chat),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.files,
    redirect: requireAccess(AppModule.files),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.fileUpload,
    redirect: requireAccess(AppModule.files, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.file,
    redirect: requireAccess(AppModule.files),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
