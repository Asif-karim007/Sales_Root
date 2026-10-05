import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/view/lead_activity_screen.dart';
import 'package:salesroot/features/leads/view/lead_board_screen.dart';
import 'package:salesroot/features/leads/view/lead_detail_screen.dart';
import 'package:salesroot/features/leads/view/lead_form_screen.dart';
import 'package:salesroot/features/leads/view/lead_links_screen.dart';
import 'package:salesroot/features/leads/view/lead_quick_screen.dart';
import 'package:salesroot/features/leads/view/lead_voice_screen.dart';
import 'package:salesroot/features/leads/view/leads_screen.dart';

final leadsBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.leads,
      redirect: requireAccess(AppModule.lead),
      builder: (context, state) => LeadsScreen(
        pick: LeadActivityKind.fromQuery(state.uri.queryParameters['pick']),
      ),
    ),
  ],
);

final List<RouteBase> leadsRoutes = [
  GoRoute(
    path: Routes.leadBoard,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) => const LeadBoardScreen(),
  ),
  GoRoute(
    path: Routes.leadNew,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) => LeadFormScreen(
      prefill: LeadPrefill.fromQuery(state.uri.queryParameters),
    ),
  ),
  GoRoute(
    path: Routes.leadQuick,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) => LeadQuickScreen(
      companyId: state.uri.queryParameters['companyId'],
      contactId: state.uri.queryParameters['contactId'],
    ),
  ),
  GoRoute(
    path: Routes.leadVoice,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) => const LeadVoiceScreen(),
  ),
  GoRoute(
    path: Routes.lead,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) => LeadDetailScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.leadEdit,
    redirect: requireAccess(AppModule.lead, ModuleRight.edit),
    builder: (context, state) => LeadFormScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.leadLinks,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) => LeadLinksScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.leadActivity,
    redirect: requireAccess(AppModule.lead, ModuleRight.edit),
    builder: (context, state) => LeadActivityScreen(
      id: idParam(state),
      kind: LeadActivityKind.fromQuery(state.uri.queryParameters['type']),
    ),
  ),
];
