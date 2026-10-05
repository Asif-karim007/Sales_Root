import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

part 'fake_providers.g.dart';

@Riverpod(keepAlive: true)
FakeNetwork fakeNetwork(Ref ref) => FakeNetwork(ref.watch(devSettingsProvider));

/// Rebuilt — and so reseeded — when the dev menu reseeds or empties the data.
@Riverpod(keepAlive: true)
FakeStore fakeStore(Ref ref) {
  final empty = ref.watch(devSettingsProvider.select((s) => s.emptyWorkspace));
  ref.watch(devSettingsProvider.select((s) => s.seed));
  return FakeStore(empty: empty);
}

@Riverpod(keepAlive: true)
SeedGraph seedGraph(Ref ref) {
  final workspace = ref.watch(currentWorkspaceProvider);
  ref.watch(devSettingsProvider.select((s) => s.seed));
  return SeedGraph.build(
    workspaceId: (workspace?.id ?? '').hashCode & 0xffff,
    kind: workspace?.kind ?? WorkspaceKind.personal,
    memberCount: 25,
    leadCount: 230,
  );
}

/// The fake server for the current workspace. Every fake repository is built
/// from this, so dev-menu changes reload every screen.
@Riverpod(keepAlive: true)
FakeBackend fakeBackend(Ref ref) => FakeBackend(
  network: ref.watch(fakeNetworkProvider),
  store: ref.watch(fakeStoreProvider),
  graph: ref.watch(seedGraphProvider),
  role: ref.watch(currentRoleProvider),
  settings: ref.watch(devSettingsProvider),
);
