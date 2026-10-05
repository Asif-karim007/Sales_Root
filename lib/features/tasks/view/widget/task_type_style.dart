import 'package:flutter/material.dart';

import 'package:salesroot/features/tasks/models/task.dart';
import 'package:salesroot/translations/translations.dart';

extension TaskTypeStyle on TaskType {
  IconData get icon => switch (this) {
    TaskType.call => Icons.call_outlined,
    TaskType.visit => Icons.place_outlined,
    TaskType.meeting => Icons.groups_outlined,
    TaskType.collection => Icons.payments_outlined,
    TaskType.delivery => Icons.local_shipping_outlined,
    TaskType.own => Icons.person_outline_rounded,
  };

  String label(AppLocalizations l10n) => switch (this) {
    TaskType.call => l10n.tasksTypeCall,
    TaskType.visit => l10n.tasksTypeVisit,
    TaskType.meeting => l10n.tasksTypeMeeting,
    TaskType.collection => l10n.tasksTypeCollection,
    TaskType.delivery => l10n.tasksTypeDelivery,
    TaskType.own => l10n.tasksTypeOwn,
  };

  /// The title the form suggests for a task of this type about [name].
  String? suggestedTitle(AppLocalizations l10n, String name) => switch (this) {
    TaskType.call => l10n.tasksAutoCall(name),
    TaskType.visit => l10n.tasksAutoVisit(name),
    TaskType.meeting => l10n.tasksAutoMeeting(name),
    TaskType.collection => l10n.tasksAutoCollection(name),
    TaskType.delivery => l10n.tasksAutoDelivery(name),
    TaskType.own => null,
  };
}
