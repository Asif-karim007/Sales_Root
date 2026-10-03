import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';

enum MoreGroup { customers, sales, team, growth, hr, plan, help, app }

/// One link on the More menu. [module] gates it; [branch] targets a shell
/// tab, so it is opened with `go` instead of `push`.
enum MoreEntry {
  contacts(MoreGroup.customers, Routes.contacts, module: AppModule.contact),
  companies(MoreGroup.customers, Routes.companies, module: AppModule.company),
  calendar(MoreGroup.customers, Routes.calendar, module: AppModule.calendar),
  visits(MoreGroup.customers, Routes.visits, module: AppModule.visit),
  attendance(
    MoreGroup.customers,
    Routes.attendance,
    module: AppModule.attendance,
  ),
  liveTracking(
    MoreGroup.customers,
    Routes.trackingLive,
    module: AppModule.liveTracking,
  ),
  quotations(MoreGroup.sales, Routes.quotations, module: AppModule.quotation),
  products(MoreGroup.sales, Routes.products, module: AppModule.product),
  collection(MoreGroup.sales, Routes.collection, module: AppModule.collection),
  reports(MoreGroup.sales, Routes.reports, module: AppModule.reports),
  team(MoreGroup.team, Routes.team, module: AppModule.team, branch: true),
  chat(MoreGroup.team, Routes.chats, module: AppModule.chat),
  files(MoreGroup.team, Routes.files, module: AppModule.files),
  notices(MoreGroup.team, Routes.notices, module: AppModule.notice),
  newLeads(MoreGroup.growth, Routes.newLeads, module: AppModule.inbox),
  messages(MoreGroup.growth, Routes.messages, module: AppModule.inbox),
  campaigns(MoreGroup.growth, Routes.campaigns, module: AppModule.campaign),
  leadSources(
    MoreGroup.growth,
    Routes.growthChannels,
    module: AppModule.leadSources,
  ),
  leave(MoreGroup.hr, Routes.leave, module: AppModule.leave),
  expenses(MoreGroup.hr, Routes.expenses, module: AppModule.expense),
  approvals(MoreGroup.hr, Routes.approvals, module: AppModule.approvals),
  payslip(MoreGroup.hr, Routes.payslip, module: AppModule.payroll),
  employeeCard(MoreGroup.hr, Routes.employeeCard, module: AppModule.payroll),
  billing(MoreGroup.plan, Routes.planUsage, module: AppModule.billing),
  refer(MoreGroup.plan, Routes.refer, module: AppModule.referral),
  help(MoreGroup.help, Routes.help),
  feedback(MoreGroup.help, Routes.feedback),
  academy(MoreGroup.help, Routes.academy),
  aiGuide(MoreGroup.help, Routes.aiGuide),
  dataSafety(MoreGroup.help, Routes.dataSafety),
  about(MoreGroup.help, Routes.about),
  settings(MoreGroup.app, Routes.settings),
  sync(MoreGroup.app, Routes.sync);

  const MoreEntry(this.group, this.route, {this.module, this.branch = false});

  final MoreGroup group;
  final String route;
  final AppModule? module;
  final bool branch;
}

/// A visible entry; [locked] ones need a plan add-on and open plan usage.
class MoreItem {
  const MoreItem(this.entry, {this.locked = false});

  final MoreEntry entry;
  final bool locked;

  String get target => locked ? Routes.planUsage : entry.route;
}

class MoreSection {
  const MoreSection(this.group, this.items);

  final MoreGroup group;
  final List<MoreItem> items;
}
