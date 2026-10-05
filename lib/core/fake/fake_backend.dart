import 'dart:async';
import 'dart:math';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/role_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// The round trip every fake call makes: latency, then the failures the dev
/// menu asks for.
class FakeNetwork {
  FakeNetwork(this.settings);

  final DevSettings settings;
  final Random _random = Random();

  Future<T> call<T>(String label, FutureOr<T> Function() body) async {
    if (settings.latency) {
      await Future<void>.delayed(
        Duration(milliseconds: 300 + _random.nextInt(400)),
      );
    }
    if (settings.offline) {
      throw const ApiFailure(0, 'No internet connection');
    }
    if (settings.injectErrors && _random.nextInt(4) == 0) {
      throw const ApiFailure(500, 'Something went wrong. Please try again.');
    }
    logDebug('Fake $label');
    return body();
  }
}

/// The fake server for one workspace. Fake repositories call [run] for every
/// method and keep their rows in [table].
class FakeBackend {
  FakeBackend({
    required this.network,
    required this.store,
    required this.graph,
    required this.role,
    required this.settings,
  });

  final FakeNetwork network;
  final FakeStore store;
  final SeedGraph graph;
  final WorkspaceRole role;
  final DevSettings settings;

  int get meId => SeedGraph.meId;

  /// Runs [body] as the server would: after latency, the dev-menu failures,
  /// the role check for [module]/[right] and the plan limit for [quota].
  Future<T> run<T>(
    String label,
    FutureOr<T> Function() body, {
    AppModule? module,
    ModuleRight right = ModuleRight.view,
    QuotaKind? quota,
  }) => network(label, () {
    if (module != null && !roleGrant(role, module).toAccess().allows(right)) {
      throw const ApiFailure(403, 'You do not have permission to do that.');
    }
    if (quota != null && settings.quotaReached) {
      throw ApiFailure(402, 'Plan limit reached', quota: quota);
    }
    return body();
  });

  /// The workspace's table [name], seeded from [seed] on first use.
  FakeTable table(String name, FixtureBuilder seed) =>
      store.table('${graph.workspaceId}/$name', () => seed(graph));
}

extension on ModulePermission {
  ModuleAccess toAccess() => ModuleAccess.fromPermission(this);
}
