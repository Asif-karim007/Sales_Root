import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/fake_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/fake/fake_backend.dart';

abstract interface class AccessRepository {
  Future<List<ModulePermission>> permissions();

  Future<Plan> plan();
}

class FakeAccessRepository implements AccessRepository {
  FakeAccessRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<ModulePermission>> permissions() => _backend.run(
    'Permissions',
    () => [
      for (final module in AppModule.values) fakeGrant(_backend.role, module),
    ],
  );

  @override
  Future<Plan> plan() => _backend.run('Plan', () {
    final json = switch (_backend.graph.workspaceId) {
      200 => _team,
      300 => _business,
      _ => _free,
    };
    final plan = Plan.fromJson({
      ...json,
      'RenewsAt': _backend.graph.daysAhead(3).toUtc().toIso8601String(),
    });
    final override = _backend.settings.addOns;
    return override == null
        ? plan
        : Plan.fromJson({
            ...plan.toJson(),
            'AddOns': [for (final addOn in override) addOn.wire],
          });
  });

  static const _free = {
    'Code': 'Free',
    'Name': 'Free',
    'Users': 1,
    'UsersUsed': 1,
    'Records': 500,
    'RecordsUsed': 124,
    'StorageGb': 1.0,
    'StorageUsedGb': 0.2,
    'CardScans': 10,
    'CardScansUsed': 3,
    'SmsCredits': 0,
    'AddOns': <String>[],
    'PricePerMonth': 0,
  };

  static const _team = {
    'Code': 'Team',
    'Name': 'Team',
    'Users': 25,
    'UsersUsed': 18,
    'Records': 25000,
    'RecordsUsed': 4210,
    'StorageGb': 10.0,
    'StorageUsedGb': 3.2,
    'CardScans': 50,
    'CardScansUsed': 44,
    'SmsCredits': 1240,
    'AddOns': ['FieldForce'],
    'PricePerMonth': 9975,
  };

  static const _business = {
    'Code': 'Business',
    'Name': 'Business',
    'Users': 10,
    'UsersUsed': 6,
    'Records': 100000,
    'RecordsUsed': 1880,
    'StorageGb': 50.0,
    'StorageUsedGb': 6.4,
    'CardScans': 500,
    'CardScansUsed': 61,
    'SmsCredits': 5200,
    'AddOns': ['FieldForce', 'Growth'],
    'PricePerMonth': 5990,
  };
}
