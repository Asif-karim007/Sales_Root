import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum ModuleRight { view, add, edit, delete, approve, export }

/// One permission row from the server.
class ModulePermission {
  const ModulePermission({
    required this.module,
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canExport = false,
  });

  final AppModule module;
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;
  final bool canExport;

  static ModulePermission? fromJson(Map<String, dynamic> json) {
    final module = AppModule.fromWire(json['Module'] as String?);
    if (module == null) return null;
    return ModulePermission(
      module: module,
      canView: jsonBool(json['CanView']),
      canAdd: jsonBool(json['CanAdd']),
      canEdit: jsonBool(json['CanEdit']),
      canDelete: jsonBool(json['CanDelete']),
      canApprove: jsonBool(json['CanApprove']),
      canExport: jsonBool(json['CanExport']),
    );
  }

  Map<String, dynamic> toJson() => {
    'Module': module.wire,
    'CanView': canView,
    'CanAdd': canAdd,
    'CanEdit': canEdit,
    'CanDelete': canDelete,
    'CanApprove': canApprove,
    'CanExport': canExport,
  };
}

/// What the user may do in one module, after role, plan and experience level.
class ModuleAccess {
  const ModuleAccess({
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canExport = false,
    this.lockedByPlan = false,
    this.hiddenByLevel = false,
  });

  static const none = ModuleAccess();

  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canApprove;
  final bool canExport;

  /// The role allows it but the plan lacks the add-on: show an upsell.
  final bool lockedByPlan;

  /// Allowed, but the experience level keeps it out of menus.
  final bool hiddenByLevel;

  /// Whether menus, tabs and add actions should offer it.
  bool get visible => canView && !hiddenByLevel;

  factory ModuleAccess.fromPermission(ModulePermission? row) => row == null
      ? none
      : ModuleAccess(
          canView: row.canView,
          canAdd: row.canAdd,
          canEdit: row.canEdit,
          canDelete: row.canDelete,
          canApprove: row.canApprove,
          canExport: row.canExport,
        );

  ModuleAccess restrict({required bool planOk, required bool levelOk}) {
    if (!planOk) return ModuleAccess(lockedByPlan: canView);
    return ModuleAccess(
      canView: canView,
      canAdd: canAdd,
      canEdit: canEdit,
      canDelete: canDelete,
      canApprove: canApprove,
      canExport: canExport,
      hiddenByLevel: !levelOk,
    );
  }

  bool allows(ModuleRight right) => switch (right) {
    ModuleRight.view => canView,
    ModuleRight.add => canAdd,
    ModuleRight.edit => canEdit,
    ModuleRight.delete => canDelete,
    ModuleRight.approve => canApprove,
    ModuleRight.export => canExport,
  };
}
