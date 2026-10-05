import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/contacts/data/api_customer_repository.dart';
import 'package:salesroot/features/contacts/data/customer_repository.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';

part 'customer_providers.g.dart';

@Riverpod(keepAlive: true)
CustomerRepository customerRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiCustomerRepository(ref.watch(contactsApiProvider));
}

@riverpod
Future<CustomerSummary> customerSummary(Ref ref, String companyId) =>
    ref.watch(customerRepositoryProvider).summary(companyId);

/// Newest first.
@riverpod
Future<List<CustomerDocument>> customerDocuments(
  Ref ref,
  String companyId,
) async {
  final detail = await ref.watch(companyDetailProvider(companyId).future);
  return [...detail.documents]
    ..sort((a, b) => b.uploadedOn.compareTo(a.uploadedOn));
}

/// Uploads a file to the customer; true once it is saved.
@riverpod
class DocumentUploadNotifier extends _$DocumentUploadNotifier {
  @override
  FutureOr<bool> build(String companyId) => false;

  Future<void> upload(DocumentUpload upload) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() async {
      await ref.read(customerRepositoryProvider).upload(companyId, upload);
      return true;
    });
    if (!ref.mounted) return;
    if (next.hasValue) {
      ref
        ..invalidate(companyDetailProvider(companyId))
        ..invalidate(customerSummaryProvider(companyId));
    }
    state = next;
  }
}
