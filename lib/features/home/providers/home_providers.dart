import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/data/api_home_repository.dart';
import 'package:salesroot/features/home/data/home_api.dart';
import 'package:salesroot/features/home/data/home_repository.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';

part 'home_providers.g.dart';

@Riverpod(keepAlive: true)
HomeApi homeApi(Ref ref) => HomeApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiHomeRepository(ref.watch(homeApiProvider));
}

/// The home the role and level call for once the workspace has data.
@riverpod
HomeVariant homeLayout(Ref ref) => homeLayoutFor(
  role: ref.watch(currentRoleProvider),
  level: ref.watch(experienceLevelProvider),
  ownerDashboard: ref.watch(
    moduleAccessProvider(AppModule.ownerDashboard).select((a) => a.canView),
  ),
);

@riverpod
Future<HomeSummary> homeSummary(Ref ref) =>
    ref.watch(homeRepositoryProvider).summary(ref.watch(homeLayoutProvider));

/// The home to show once the summary has said whether the workspace is new.
@riverpod
HomeVariant? homeVariant(Ref ref) {
  final isNew = ref.watch(homeSummaryProvider.select((s) => s.value?.isNew));
  if (isNew == null) return null;
  return isNew ? HomeVariant.newUser : ref.watch(homeLayoutProvider);
}
