import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/contacts/data/customer_repository.dart';
import 'package:salesroot/features/contacts/data/fake_customer_repository.dart';
import 'package:salesroot/features/contacts/models/customer.dart';

part 'customer_providers.g.dart';

@Riverpod(keepAlive: true)
CustomerRepository customerRepository(Ref ref) =>
    FakeCustomerRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<CustomerSummary> customerSummary(Ref ref, int companyId) =>
    ref.watch(customerRepositoryProvider).summary(companyId);

@riverpod
Future<List<CustomerDocument>> customerDocuments(Ref ref, int companyId) =>
    ref.watch(customerRepositoryProvider).documents(companyId);

enum DocumentChange { uploaded, deleted }

/// Uploads and deletes a customer's documents; the screen listens for the
/// [DocumentChange] to confirm.
@riverpod
class DocumentMutationNotifier extends _$DocumentMutationNotifier {
  @override
  FutureOr<DocumentChange?> build(int companyId) => null;

  Future<void> upload(DocumentUpload upload) => _run(
    DocumentChange.uploaded,
    (repository) => repository.upload(companyId, upload),
  );

  Future<void> delete(int documentId) => _run(
    DocumentChange.deleted,
    (repository) => repository.deleteDocument(documentId),
  );

  Future<void> _run(
    DocumentChange change,
    Future<Object?> Function(CustomerRepository repository) action,
  ) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard<DocumentChange?>(() async {
      await action(ref.read(customerRepositoryProvider));
      return change;
    });
    if (!ref.mounted) return;
    if (next.hasValue) ref.invalidate(customerDocumentsProvider(companyId));
    state = next;
  }
}
