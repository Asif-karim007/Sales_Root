// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customerRepository)
final customerRepositoryProvider = CustomerRepositoryProvider._();

final class CustomerRepositoryProvider
    extends
        $FunctionalProvider<
          CustomerRepository,
          CustomerRepository,
          CustomerRepository
        >
    with $Provider<CustomerRepository> {
  CustomerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomerRepository create(Ref ref) {
    return customerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerRepository>(value),
    );
  }
}

String _$customerRepositoryHash() =>
    r'2a2ac895de6825cece1af092eba8b0dd10985f2e';

@ProviderFor(customerSummary)
final customerSummaryProvider = CustomerSummaryFamily._();

final class CustomerSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerSummary>,
          CustomerSummary,
          FutureOr<CustomerSummary>
        >
    with $FutureModifier<CustomerSummary>, $FutureProvider<CustomerSummary> {
  CustomerSummaryProvider._({
    required CustomerSummaryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'customerSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerSummaryHash();

  @override
  String toString() {
    return r'customerSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CustomerSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerSummary> create(Ref ref) {
    final argument = this.argument as int;
    return customerSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerSummaryHash() => r'bbbb1e08ec1a774127a8dae335ff5849ff67f074';

final class CustomerSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CustomerSummary>, int> {
  CustomerSummaryFamily._()
    : super(
        retry: null,
        name: r'customerSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerSummaryProvider call(int companyId) =>
      CustomerSummaryProvider._(argument: companyId, from: this);

  @override
  String toString() => r'customerSummaryProvider';
}

@ProviderFor(customerDocuments)
final customerDocumentsProvider = CustomerDocumentsFamily._();

final class CustomerDocumentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerDocument>>,
          List<CustomerDocument>,
          FutureOr<List<CustomerDocument>>
        >
    with
        $FutureModifier<List<CustomerDocument>>,
        $FutureProvider<List<CustomerDocument>> {
  CustomerDocumentsProvider._({
    required CustomerDocumentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'customerDocumentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerDocumentsHash();

  @override
  String toString() {
    return r'customerDocumentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CustomerDocument>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerDocument>> create(Ref ref) {
    final argument = this.argument as int;
    return customerDocuments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerDocumentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerDocumentsHash() => r'4abc7df1cbc387dc8193962665c5d8ad41e71c73';

final class CustomerDocumentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CustomerDocument>>, int> {
  CustomerDocumentsFamily._()
    : super(
        retry: null,
        name: r'customerDocumentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerDocumentsProvider call(int companyId) =>
      CustomerDocumentsProvider._(argument: companyId, from: this);

  @override
  String toString() => r'customerDocumentsProvider';
}

/// Uploads and deletes a customer's documents; the screen listens for the
/// [DocumentChange] to confirm.

@ProviderFor(DocumentMutationNotifier)
final documentMutationProvider = DocumentMutationNotifierFamily._();

/// Uploads and deletes a customer's documents; the screen listens for the
/// [DocumentChange] to confirm.
final class DocumentMutationNotifierProvider
    extends $AsyncNotifierProvider<DocumentMutationNotifier, DocumentChange?> {
  /// Uploads and deletes a customer's documents; the screen listens for the
  /// [DocumentChange] to confirm.
  DocumentMutationNotifierProvider._({
    required DocumentMutationNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'documentMutationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentMutationNotifierHash();

  @override
  String toString() {
    return r'documentMutationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentMutationNotifier create() => DocumentMutationNotifier();

  @override
  bool operator ==(Object other) {
    return other is DocumentMutationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentMutationNotifierHash() =>
    r'847dbd35625566a5f3a310fa62116e4b81f53593';

/// Uploads and deletes a customer's documents; the screen listens for the
/// [DocumentChange] to confirm.

final class DocumentMutationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentMutationNotifier,
          AsyncValue<DocumentChange?>,
          DocumentChange?,
          FutureOr<DocumentChange?>,
          int
        > {
  DocumentMutationNotifierFamily._()
    : super(
        retry: null,
        name: r'documentMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Uploads and deletes a customer's documents; the screen listens for the
  /// [DocumentChange] to confirm.

  DocumentMutationNotifierProvider call(int companyId) =>
      DocumentMutationNotifierProvider._(argument: companyId, from: this);

  @override
  String toString() => r'documentMutationProvider';
}

/// Uploads and deletes a customer's documents; the screen listens for the
/// [DocumentChange] to confirm.

abstract class _$DocumentMutationNotifier
    extends $AsyncNotifier<DocumentChange?> {
  late final _$args = ref.$arg as int;
  int get companyId => _$args;

  FutureOr<DocumentChange?> build(int companyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DocumentChange?>, DocumentChange?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DocumentChange?>, DocumentChange?>,
              AsyncValue<DocumentChange?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
