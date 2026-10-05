import 'package:salesroot/features/field_force/models/visit.dart';

/// What Field Force reads from `GET workspaces/current`.
class FieldWorkspace {
  const FieldWorkspace({this.weekend = const {}, this.outcomes = const []});

  /// Rest days as `DateTime.weekday` values.
  final Set<int> weekend;
  final List<VisitOutcomeOption> outcomes;

  /// `weekendDays` counts from Sunday = 0, as .NET's `DayOfWeek` does.
  factory FieldWorkspace.fromJson(Map<String, dynamic> json) {
    final days = json['weekendDays'];
    return FieldWorkspace(
      weekend: {
        if (days is List)
          for (final day in days)
            if (day is num && day >= 0 && day <= 6)
              day == 0 ? DateTime.sunday : day.toInt(),
      },
      outcomes: VisitOutcomeOption.ofWorkspace(json),
    );
  }
}
