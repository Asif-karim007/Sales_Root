import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/data/report_repository.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/models/report_models.dart';

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._api, {required this.memberId, required this.today});

  final SettingsApi _api;

  /// The user's membership in the current workspace, for "mine".
  final String? Function() memberId;
  final DateTime Function() today;

  static const _trendWeeks = 8;
  static const _trendMonths = 6;

  @override
  Future<ReportOverview> overview(ReportQuery query) async {
    final end = _end(query);
    final [period, weeks] = await Future.wait([
      _report('conversion', _query(query)),
      _report('conversion', {
        ..._query(query),
        ...ReportQuery.period(
          end.subtract(const Duration(days: _trendWeeks * 7 - 1)),
          end,
        ),
        'group': 'week',
      }),
    ]);
    return ReportOverview.fromJson(period, weeks: weeks);
  }

  @override
  Future<SalesReport> sales(ReportQuery query) async {
    final end = _end(query);
    final days = query.to.difference(query.from).inDays + 1;
    final before = query.from.subtract(const Duration(days: 1));
    final [sales, previous, months, targets, conversion] = await Future.wait([
      _report('sales', _query(query)),
      _report('sales', {
        ..._query(query),
        ...ReportQuery.period(
          before.subtract(Duration(days: days - 1)),
          before,
        ),
      }),
      _report('sales', {
        ..._query(query),
        ...ReportQuery.period(
          DateTime(end.year, end.month - _trendMonths + 1),
          end,
        ),
        'group': 'month',
      }),
      _report('targets', _query(query)..remove('ownerId')),
      _report('conversion', _query(query)),
    ]);
    return SalesReport.fromJson(
      sales: sales,
      previous: previous,
      months: months,
      targets: targets,
      conversion: conversion,
      memberId: query.scope == ReportScope.mine ? memberId() : null,
    );
  }

  Map<String, dynamic> _query(ReportQuery query) =>
      query.toQuery(memberId: memberId());

  /// The period's last day, or today while the period is still running.
  DateTime _end(ReportQuery query) {
    final now = today();
    final day = DateTime(now.year, now.month, now.day);
    return query.to.isAfter(day) ? day : query.to;
  }

  Future<Map<String, dynamic>> _report(
    String name,
    Map<String, dynamic> query,
  ) async =>
      jsonMap(await apiRequest('Report $name', () => _api.report(name, query)));
}
