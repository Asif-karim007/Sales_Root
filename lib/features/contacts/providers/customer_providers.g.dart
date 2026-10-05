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
    r'e300dd2f32b5dde6a96c1c08b37b0ab3e40429a8';

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$customerSummaryHash() => r'3c605968e9f9866e4413ac91289f751d65f5ca10';

final class CustomerSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CustomerSummary>, String> {
  CustomerSummaryFamily._()
    : super(
        retry: null,
        name: r'customerSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerSummaryProvider call(String companyId) =>
      CustomerSummaryProvider._(argument: companyId, from: this);

  @override
  String toString() => r'customerSummaryProvider';
}

/// Newest first.

@ProviderFor(customerDocuments)
final customerDocumentsProvider = CustomerDocumentsFamily._();

/// Newest first.

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
  /// Newest first.
  CustomerDocumentsProvider._({
    required CustomerDocumentsFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$customerDocumentsHash() => r'61d031a4f6af9c024aaf4395c3e8bf70ca387429';

/// Newest first.

final class CustomerDocumentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CustomerDocument>>, String> {
  CustomerDocumentsFamily._()
    : super(
        retry: null,
        name: r'customerDocumentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Newest first.

  CustomerDocumentsProvider call(String companyId) =>
      CustomerDocumentsProvider._(argument: companyId, from: this);

  @override
  String toString() => r'customerDocumentsProvider';
}

/// Uploads a file to the customer; true once it is saved.

@ProviderFor(DocumentUploadNotifier)
final documentUploadProvider = DocumentUploadNotifierFamily._();

/// Uploads a file to the customer; true once it is saved.
final class DocumentUploadNotifierProvider
    extends $AsyncNotifierProvider<DocumentUploadNotifier, bool> {
  /// Uploads a file to the customer; true once it is saved.
  DocumentUploadNotifierProvider._({
    required DocumentUploadNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentUploadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentUploadNotifierHash();

  @override
  String toString() {
    return r'documentUploadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentUploadNotifier create() => DocumentUploadNotifier();

  @override
  bool operator ==(Object other) {
    return other is DocumentUploadNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentUploadNotifierHash() =>
    r'e571a713965f34659fca6e5d7d3a6003307bde9f';

/// Uploads a file to the customer; true once it is saved.

final class DocumentUploadNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentUploadNotifier,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  DocumentUploadNotifierFamily._()
    : super(
        retry: null,
        name: r'documentUploadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Uploads a file to the customer; true once it is saved.

  DocumentUploadNotifierProvider call(String companyId) =>
      DocumentUploadNotifierProvider._(argument: companyId, from: this);

  @override
  String toString() => r'documentUploadProvider';
}

/// Uploads a file to the customer; true once it is saved.

abstract class _$DocumentUploadNotifier extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get companyId => _$args;

  FutureOr<bool> build(String companyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
