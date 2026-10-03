// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companies_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompaniesFilterNotifier)
final companiesFilterProvider = CompaniesFilterNotifierProvider._();

final class CompaniesFilterNotifierProvider
    extends $NotifierProvider<CompaniesFilterNotifier, CompaniesFilter> {
  CompaniesFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companiesFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companiesFilterNotifierHash();

  @$internal
  @override
  CompaniesFilterNotifier create() => CompaniesFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompaniesFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompaniesFilter>(value),
    );
  }
}

String _$companiesFilterNotifierHash() =>
    r'da5290e433de91e56a50c5b31e599f384a31924e';

abstract class _$CompaniesFilterNotifier extends $Notifier<CompaniesFilter> {
  CompaniesFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CompaniesFilter, CompaniesFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompaniesFilter, CompaniesFilter>,
              CompaniesFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CompaniesListNotifier)
final companiesListProvider = CompaniesListNotifierProvider._();

final class CompaniesListNotifierProvider
    extends $AsyncNotifierProvider<CompaniesListNotifier, Paged<Company>> {
  CompaniesListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companiesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companiesListNotifierHash();

  @$internal
  @override
  CompaniesListNotifier create() => CompaniesListNotifier();
}

String _$companiesListNotifierHash() =>
    r'd0802bdc90f4ba4a6d11f616b423dbdaa52ca54a';

abstract class _$CompaniesListNotifier extends $AsyncNotifier<Paged<Company>> {
  FutureOr<Paged<Company>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Company>>, Paged<Company>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Company>>, Paged<Company>>,
              AsyncValue<Paged<Company>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(company)
final companyProvider = CompanyFamily._();

final class CompanyProvider
    extends $FunctionalProvider<AsyncValue<Company>, Company, FutureOr<Company>>
    with $FutureModifier<Company>, $FutureProvider<Company> {
  CompanyProvider._({
    required CompanyFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyHash();

  @override
  String toString() {
    return r'companyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Company> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Company> create(Ref ref) {
    final argument = this.argument as int;
    return company(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyHash() => r'4de76b44e67a815691b1930917f2b913b21fbe22';

final class CompanyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Company>, int> {
  CompanyFamily._()
    : super(
        retry: null,
        name: r'companyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyProvider call(int id) => CompanyProvider._(argument: id, from: this);

  @override
  String toString() => r'companyProvider';
}

@ProviderFor(companyContacts)
final companyContactsProvider = CompanyContactsFamily._();

final class CompanyContactsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Contact>>,
          List<Contact>,
          FutureOr<List<Contact>>
        >
    with $FutureModifier<List<Contact>>, $FutureProvider<List<Contact>> {
  CompanyContactsProvider._({
    required CompanyContactsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companyContactsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyContactsHash();

  @override
  String toString() {
    return r'companyContactsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Contact>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Contact>> create(Ref ref) {
    final argument = this.argument as int;
    return companyContacts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyContactsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyContactsHash() => r'bdec9888e1bf0fb572eaa02fc0fab06f6fb96acd';

final class CompanyContactsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Contact>>, int> {
  CompanyContactsFamily._()
    : super(
        retry: null,
        name: r'companyContactsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyContactsProvider call(int id) =>
      CompanyContactsProvider._(argument: id, from: this);

  @override
  String toString() => r'companyContactsProvider';
}

@ProviderFor(companyLeads)
final companyLeadsProvider = CompanyLeadsFamily._();

final class CompanyLeadsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LinkedLead>>,
          List<LinkedLead>,
          FutureOr<List<LinkedLead>>
        >
    with $FutureModifier<List<LinkedLead>>, $FutureProvider<List<LinkedLead>> {
  CompanyLeadsProvider._({
    required CompanyLeadsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companyLeadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyLeadsHash();

  @override
  String toString() {
    return r'companyLeadsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LinkedLead>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LinkedLead>> create(Ref ref) {
    final argument = this.argument as int;
    return companyLeads(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyLeadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyLeadsHash() => r'bfdb63f091e2c35684d5a82a55acadb2e007a3a4';

final class CompanyLeadsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LinkedLead>>, int> {
  CompanyLeadsFamily._()
    : super(
        retry: null,
        name: r'companyLeadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyLeadsProvider call(int id) =>
      CompanyLeadsProvider._(argument: id, from: this);

  @override
  String toString() => r'companyLeadsProvider';
}

@ProviderFor(companyLookups)
final companyLookupsProvider = CompanyLookupsProvider._();

final class CompanyLookupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompanyLookups>,
          CompanyLookups,
          FutureOr<CompanyLookups>
        >
    with $FutureModifier<CompanyLookups>, $FutureProvider<CompanyLookups> {
  CompanyLookupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companyLookupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companyLookupsHash();

  @$internal
  @override
  $FutureProviderElement<CompanyLookups> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompanyLookups> create(Ref ref) {
    return companyLookups(ref);
  }
}

String _$companyLookupsHash() => r'be1eaca37a3e6b7d166d25482ab2a39b85fe6def';

/// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].

@ProviderFor(CompanySaveNotifier)
final companySaveProvider = CompanySaveNotifierFamily._();

/// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].
final class CompanySaveNotifierProvider
    extends $AsyncNotifierProvider<CompanySaveNotifier, SaveOutcome<Company>?> {
  /// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].
  CompanySaveNotifierProvider._({
    required CompanySaveNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companySaveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companySaveNotifierHash();

  @override
  String toString() {
    return r'companySaveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompanySaveNotifier create() => CompanySaveNotifier();

  @override
  bool operator ==(Object other) {
    return other is CompanySaveNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companySaveNotifierHash() =>
    r'73460153a5f1ae19abca41ea6ee891c216755a8e';

/// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].

final class CompanySaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CompanySaveNotifier,
          AsyncValue<SaveOutcome<Company>?>,
          SaveOutcome<Company>?,
          FutureOr<SaveOutcome<Company>?>,
          int
        > {
  CompanySaveNotifierFamily._()
    : super(
        retry: null,
        name: r'companySaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].

  CompanySaveNotifierProvider call(int id) =>
      CompanySaveNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'companySaveProvider';
}

/// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].

abstract class _$CompanySaveNotifier
    extends $AsyncNotifier<SaveOutcome<Company>?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<SaveOutcome<Company>?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SaveOutcome<Company>?>, SaveOutcome<Company>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SaveOutcome<Company>?>,
                SaveOutcome<Company>?
              >,
              AsyncValue<SaveOutcome<Company>?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Deletes a company or changes its concern persons; screens listen for the
/// [RecordChange] to react.

@ProviderFor(CompanyMutationNotifier)
final companyMutationProvider = CompanyMutationNotifierFamily._();

/// Deletes a company or changes its concern persons; screens listen for the
/// [RecordChange] to react.
final class CompanyMutationNotifierProvider
    extends $AsyncNotifierProvider<CompanyMutationNotifier, RecordChange?> {
  /// Deletes a company or changes its concern persons; screens listen for the
  /// [RecordChange] to react.
  CompanyMutationNotifierProvider._({
    required CompanyMutationNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'companyMutationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyMutationNotifierHash();

  @override
  String toString() {
    return r'companyMutationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompanyMutationNotifier create() => CompanyMutationNotifier();

  @override
  bool operator ==(Object other) {
    return other is CompanyMutationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyMutationNotifierHash() =>
    r'8aa819827a0d48a8a291311cd6276ae66809706c';

/// Deletes a company or changes its concern persons; screens listen for the
/// [RecordChange] to react.

final class CompanyMutationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CompanyMutationNotifier,
          AsyncValue<RecordChange?>,
          RecordChange?,
          FutureOr<RecordChange?>,
          int
        > {
  CompanyMutationNotifierFamily._()
    : super(
        retry: null,
        name: r'companyMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a company or changes its concern persons; screens listen for the
  /// [RecordChange] to react.

  CompanyMutationNotifierProvider call(int id) =>
      CompanyMutationNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'companyMutationProvider';
}

/// Deletes a company or changes its concern persons; screens listen for the
/// [RecordChange] to react.

abstract class _$CompanyMutationNotifier extends $AsyncNotifier<RecordChange?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<RecordChange?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RecordChange?>, RecordChange?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RecordChange?>, RecordChange?>,
              AsyncValue<RecordChange?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
