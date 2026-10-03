import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/fake_report_repository.dart';
import 'package:salesroot/features/settings/data/report_repository.dart';
import 'package:salesroot/features/settings/models/report_models.dart';

part 'report_providers.g.dart';

@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) =>
    FakeReportRepository(ref.watch(fakeBackendProvider));

/// Whether the user may switch to team-wide numbers.
@riverpod
bool canSeeTeamReports(Ref ref) =>
    ref.watch(currentRoleProvider) != WorkspaceRole.member;

/// The period and scope both report screens share.
@riverpod
class ReportQueryNotifier extends _$ReportQueryNotifier {
  @override
  ReportQuery build() => ReportQuery.preset(
    ReportRange.thisMonth,
    now: DateTime.now(),
    scope: ref.watch(canSeeTeamReportsProvider)
        ? ReportScope.team
        : ReportScope.mine,
  );

  void setRange(ReportRange range) => state = ReportQuery.preset(
    range,
    now: DateTime.now(),
    scope: state.scope,
  );

  void setCustom(DateTime from, DateTime to) => state = state.copyWith(
    range: ReportRange.custom,
    from: DateTime(from.year, from.month, from.day),
    to: DateTime(to.year, to.month, to.day),
  );

  void setScope(ReportScope scope) => state = state.copyWith(scope: scope);
}

@riverpod
Future<ReportOverview> reportOverview(Ref ref) => ref
    .watch(reportRepositoryProvider)
    .overview(ref.watch(reportQueryProvider));

@riverpod
Future<SalesReport> salesReport(Ref ref) =>
    ref.watch(reportRepositoryProvider).sales(ref.watch(reportQueryProvider));
