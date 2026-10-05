import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';

abstract interface class HomeRepository {
  /// Today's counts and plan for the current workspace, with what the
  /// [layout] home shows on top, scoped by the server to the caller's role.
  Future<HomeSummary> summary(HomeVariant layout);
}
