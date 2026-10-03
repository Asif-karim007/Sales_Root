import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// The default role matrix the fake server grants.
ModulePermission fakeGrant(WorkspaceRole role, AppModule module) =>
    switch (role) {
      WorkspaceRole.owner => _all(module),
      WorkspaceRole.teamLead => _teamLead(module),
      WorkspaceRole.member => _member(module),
    };

ModulePermission _all(AppModule module) => ModulePermission(
  module: module,
  canView: true,
  canAdd: true,
  canEdit: true,
  canDelete: true,
  canApprove: true,
  canExport: true,
);

ModulePermission _viewOnly(AppModule module) =>
    ModulePermission(module: module, canView: true);

ModulePermission _work(AppModule module, {bool delete = false}) =>
    ModulePermission(
      module: module,
      canView: true,
      canAdd: true,
      canEdit: true,
      canDelete: delete,
    );

ModulePermission _teamLead(AppModule module) => switch (module) {
  AppModule.billing ||
  AppModule.pipelines ||
  AppModule.formFields ||
  AppModule.dataImport ||
  AppModule.payroll => _viewOnly(module),
  AppModule.chatOversight ||
  AppModule.ownerDashboard => ModulePermission(module: module),
  _ => ModulePermission(
    module: module,
    canView: true,
    canAdd: true,
    canEdit: true,
    canDelete: true,
    canApprove: true,
    canExport: true,
  ),
};

ModulePermission _member(AppModule module) => switch (module) {
  AppModule.lead ||
  AppModule.contact ||
  AppModule.company ||
  AppModule.quotation ||
  AppModule.collection ||
  AppModule.visit ||
  AppModule.attendance ||
  AppModule.leave ||
  AppModule.expense ||
  AppModule.cardScan ||
  AppModule.support ||
  AppModule.referral => _work(module),
  AppModule.task ||
  AppModule.calendar ||
  AppModule.chat ||
  AppModule.files => _work(module, delete: true),
  AppModule.product ||
  AppModule.order ||
  AppModule.invoice ||
  AppModule.team ||
  AppModule.reports ||
  AppModule.notice ||
  AppModule.inbox ||
  AppModule.payroll => _viewOnly(module),
  _ => ModulePermission(module: module),
};
