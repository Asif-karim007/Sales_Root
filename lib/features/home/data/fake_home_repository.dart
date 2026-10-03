import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/features/home/data/fake_home_summary.dart';
import 'package:salesroot/features/home/data/home_fixtures.dart';
import 'package:salesroot/features/home/data/home_repository.dart';
import 'package:salesroot/features/home/models/home_summary.dart';

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<HomeSummary> summary() => _backend.run('Home summary', () {
    if (_backend.store.empty) {
      return HomeSummary.fromJson(const {'IsNewWorkspace': true});
    }
    final json = FakeHomeSummary(
      graph: _backend.graph,
      role: _backend.role,
      tasks: _backend.table('home_tasks', homeTaskFixtures).rows,
      approvals: _backend.table('home_approvals', homeApprovalFixtures).rows,
    ).build();
    return HomeSummary.fromJson(json);
  });
}
