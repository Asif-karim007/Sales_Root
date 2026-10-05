import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/billing/data/api_billing_repository.dart';
import 'package:salesroot/features/billing/data/api_referral_repository.dart';
import 'package:salesroot/features/billing/data/billing_api.dart';
import 'package:salesroot/features/billing/data/billing_repository.dart';
import 'package:salesroot/features/billing/data/referral_repository.dart';

part 'billing_repositories.g.dart';

@Riverpod(keepAlive: true)
BillingApi billingApi(Ref ref) => BillingApi(ref.watch(dioProvider));

/// The API, rebuilding each repository on a workspace switch.
BillingApi _api(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(billingApiProvider);
}

@Riverpod(keepAlive: true)
BillingRepository billingRepository(Ref ref) => ApiBillingRepository(_api(ref));

@Riverpod(keepAlive: true)
ReferralRepository referralRepository(Ref ref) =>
    ApiReferralRepository(_api(ref), today: DateTime.now);
