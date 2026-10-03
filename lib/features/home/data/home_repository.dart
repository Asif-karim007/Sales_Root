import 'package:salesroot/features/home/models/home_summary.dart';

abstract interface class HomeRepository {
  /// Today's numbers, agenda, pipeline, team and money for the current
  /// workspace, scoped to the caller's role.
  Future<HomeSummary> summary();
}
