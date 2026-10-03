import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/workspace/workspace.dart';

abstract interface class WorkspaceRepository {
  Future<List<Workspace>> list();

  Future<Workspace> create(String name);
}

class FakeWorkspaceRepository implements WorkspaceRepository {
  FakeWorkspaceRepository(this._network, this._store);

  final FakeNetwork _network;
  final FakeStore _store;

  FakeTable get _table =>
      _store.table('global/workspaces', () => _seed, always: true);

  @override
  Future<List<Workspace>> list() => _network(
    'Workspace list',
    () => [for (final row in _table.rows) Workspace.fromJson(row)],
  );

  @override
  Future<Workspace> create(String name) => _network('Workspace create', () {
    fakeRequire({'Name': name}, ['Name']);
    final row = _table.insert({
      'Id': _table.nextId() * 100,
      'Name': name.trim(),
      'Kind': 'Team',
      'Role': WorkspaceRole.owner.wire,
      'MemberCount': 1,
      'LeadCount': 0,
    }, first: false);
    return Workspace.fromJson(row);
  });

  static const _seed = [
    {
      'Id': 100,
      'Name': 'My workspace',
      'Kind': 'Personal',
      'Role': 'Owner',
      'MemberCount': 1,
      'LeadCount': 124,
    },
    {
      'Id': 200,
      'Name': 'Dhaka Sales',
      'Kind': 'Team',
      'Role': 'Member',
      'MemberCount': 21,
      'LeadCount': 230,
      'OwnerName': 'Mohammad Kamal',
    },
    {
      'Id': 300,
      'Name': 'Nexzen Partners',
      'Kind': 'Team',
      'Role': 'TeamLead',
      'MemberCount': 6,
      'LeadCount': 60,
      'OwnerName': 'Mohammad Kamal',
    },
  ];
}
