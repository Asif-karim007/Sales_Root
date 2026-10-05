import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/support/data/api_guide_repository.dart';
import 'package:salesroot/features/support/data/api_support_repository.dart';
import 'package:salesroot/features/support/data/guide_repository.dart';
import 'package:salesroot/features/support/data/support_api.dart';
import 'package:salesroot/features/support/data/support_repository.dart';

part 'support_repositories.g.dart';

@Riverpod(keepAlive: true)
SupportApi supportApi(Ref ref) => SupportApi(ref.watch(dioProvider));

/// The API, rebuilding each repository on a workspace switch.
SupportApi _api(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(supportApiProvider);
}

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) => ApiSupportRepository(_api(ref));

@Riverpod(keepAlive: true)
GuideRepository guideRepository(Ref ref) => ApiGuideRepository(_api(ref));
