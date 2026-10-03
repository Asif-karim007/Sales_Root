import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/view/about_screen.dart';
import 'package:salesroot/features/support/view/academy_screen.dart';
import 'package:salesroot/features/support/view/ai_guide_screen.dart';
import 'package:salesroot/features/support/view/career_path_screen.dart';
import 'package:salesroot/features/support/view/data_safety_screen.dart';
import 'package:salesroot/features/support/view/enquiry_screen.dart';
import 'package:salesroot/features/support/view/feedback_screen.dart';
import 'package:salesroot/features/support/view/help_article_screen.dart';
import 'package:salesroot/features/support/view/help_screen.dart';
import 'package:salesroot/features/support/view/lesson_screen.dart';
import 'package:salesroot/features/support/view/support_form_screen.dart';
import 'package:salesroot/features/support/view/support_ticket_screen.dart';

final List<RouteBase> supportRoutes = [
  GoRoute(
    path: Routes.feedback,
    builder: (context, state) => const FeedbackScreen(),
  ),
  GoRoute(
    path: Routes.help,
    builder: (context, state) =>
        HelpScreen(initialQuery: state.uri.queryParameters['q']),
  ),
  GoRoute(
    path: Routes.helpArticle,
    builder: (context, state) => HelpArticleScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.supportNew,
    redirect: requireAccess(AppModule.support, ModuleRight.add),
    builder: (context, state) {
      final query = state.uri.queryParameters;
      final category = query['category'];
      return SupportFormScreen(
        category: category == null ? null : TicketCategory.fromWire(category),
        from: query['from'],
      );
    },
  ),
  GoRoute(
    path: Routes.supportTicket,
    redirect: requireAccess(AppModule.support),
    builder: (context, state) => SupportTicketScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.aiGuide,
    builder: (context, state) =>
        AiGuideScreen(initialQuestion: state.uri.queryParameters['q']),
  ),
  GoRoute(
    path: Routes.dataSafety,
    builder: (context, state) => const DataSafetyScreen(),
  ),
  GoRoute(
    path: Routes.academy,
    builder: (context, state) => const AcademyScreen(),
  ),
  GoRoute(
    path: Routes.lesson,
    builder: (context, state) => LessonScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.career,
    builder: (context, state) => const CareerPathScreen(),
  ),
  GoRoute(path: Routes.about, builder: (context, state) => const AboutScreen()),
  GoRoute(
    path: Routes.enquiry,
    builder: (context, state) => EnquiryScreen(
      kind: EnquiryKind.fromWire(state.uri.queryParameters['kind']),
    ),
  ),
];
