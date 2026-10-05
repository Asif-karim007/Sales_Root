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
    r'e53ccf691ff27156573b93f0869dc0539a8f30b4';

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
    r'd4322b0e4256c193eb50339348915914ea554828';

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

@ProviderFor(companyCounts)
final companyCountsProvider = CompanyCountsProvider._();

final class CompanyCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompanyCounts>,
          CompanyCounts,
          FutureOr<CompanyCounts>
        >
    with $FutureModifier<CompanyCounts>, $FutureProvider<CompanyCounts> {
  CompanyCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companyCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companyCountsHash();

  @$internal
  @override
  $FutureProviderElement<CompanyCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompanyCounts> create(Ref ref) {
    return companyCounts(ref);
  }
}

String _$companyCountsHash() => r'275ac95fe18af14f1f4b1d74e971a669f4e60d8e';

@ProviderFor(companyDetail)
final companyDetailProvider = CompanyDetailFamily._();

final class CompanyDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompanyDetail>,
          CompanyDetail,
          FutureOr<CompanyDetail>
        >
    with $FutureModifier<CompanyDetail>, $FutureProvider<CompanyDetail> {
  CompanyDetailProvider._({
    required CompanyDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'companyDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$companyDetailHash();

  @override
  String toString() {
    return r'companyDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompanyDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompanyDetail> create(Ref ref) {
    final argument = this.argument as String;
    return companyDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$companyDetailHash() => r'3f67b8516fbe0a26fa9ded8cae803c02f2a13b84';

final class CompanyDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompanyDetail>, String> {
  CompanyDetailFamily._()
    : super(
        retry: null,
        name: r'companyDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyDetailProvider call(String id) =>
      CompanyDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'companyDetailProvider';
}

@ProviderFor(company)
final companyProvider = CompanyFamily._();

final class CompanyProvider
    extends $FunctionalProvider<AsyncValue<Company>, Company, FutureOr<Company>>
    with $FutureModifier<Company>, $FutureProvider<Company> {
  CompanyProvider._({
    required CompanyFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$companyHash() => r'c9c3fbbc8d77601d3083b4f9e72760cd5c13cb34';

final class CompanyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Company>, String> {
  CompanyFamily._()
    : super(
        retry: null,
        name: r'companyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyProvider call(String id) =>
      CompanyProvider._(argument: id, from: this);

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$companyContactsHash() => r'de8b000c0849e640bd63f43fd3ea15ac5974a1db';

final class CompanyContactsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Contact>>, String> {
  CompanyContactsFamily._()
    : super(
        retry: null,
        name: r'companyContactsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyContactsProvider call(String id) =>
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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$companyLeadsHash() => r'b50f95c7f2c3fa7ae8cdcd4e442b216c0936d650';

final class CompanyLeadsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LinkedLead>>, String> {
  CompanyLeadsFamily._()
    : super(
        retry: null,
        name: r'companyLeadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompanyLeadsProvider call(String id) =>
      CompanyLeadsProvider._(argument: id, from: this);

  @override
  String toString() => r'companyLeadsProvider';
}

@ProviderFor(contactsPack)
final contactsPackProvider = ContactsPackProvider._();

final class ContactsPackProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContactsPack>,
          ContactsPack,
          FutureOr<ContactsPack>
        >
    with $FutureModifier<ContactsPack>, $FutureProvider<ContactsPack> {
  ContactsPackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsPackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsPackHash();

  @$internal
  @override
  $FutureProviderElement<ContactsPack> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContactsPack> create(Ref ref) {
    return contactsPack(ref);
  }
}

String _$contactsPackHash() => r'3cfb0cdc654ad9583d51b993ae110e78812c92d6';

/// Saves the company form; an empty [id] creates. A 409 comes back as
/// [Duplicates].

@ProviderFor(CompanySaveNotifier)
final companySaveProvider = CompanySaveNotifierFamily._();

/// Saves the company form; an empty [id] creates. A 409 comes back as
/// [Duplicates].
final class CompanySaveNotifierProvider
    extends $AsyncNotifierProvider<CompanySaveNotifier, SaveOutcome<Company>?> {
  /// Saves the company form; an empty [id] creates. A 409 comes back as
  /// [Duplicates].
  CompanySaveNotifierProvider._({
    required CompanySaveNotifierFamily super.from,
    required String super.argument,
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
    r'fe66725ef2ddac81fc907db4c42097230b8d4710';

/// Saves the company form; an empty [id] creates. A 409 comes back as
/// [Duplicates].

final class CompanySaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CompanySaveNotifier,
          AsyncValue<SaveOutcome<Company>?>,
          SaveOutcome<Company>?,
          FutureOr<SaveOutcome<Company>?>,
          String
        > {
  CompanySaveNotifierFamily._()
    : super(
        retry: null,
        name: r'companySaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves the company form; an empty [id] creates. A 409 comes back as
  /// [Duplicates].

  CompanySaveNotifierProvider call(String id) =>
      CompanySaveNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'companySaveProvider';
}

/// Saves the company form; an empty [id] creates. A 409 comes back as
/// [Duplicates].

abstract class _$CompanySaveNotifier
    extends $AsyncNotifier<SaveOutcome<Company>?> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<SaveOutcome<Company>?> build(String id);
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

/// Deletes a company; true once it is gone.

@ProviderFor(CompanyMutationNotifier)
final companyMutationProvider = CompanyMutationNotifierFamily._();

/// Deletes a company; true once it is gone.
final class CompanyMutationNotifierProvider
    extends $AsyncNotifierProvider<CompanyMutationNotifier, bool> {
  /// Deletes a company; true once it is gone.
  CompanyMutationNotifierProvider._({
    required CompanyMutationNotifierFamily super.from,
    required String super.argument,
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
    r'5f08b976fc996f0d08abcd42c890cad466471f4d';

/// Deletes a company; true once it is gone.

final class CompanyMutationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CompanyMutationNotifier,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  CompanyMutationNotifierFamily._()
    : super(
        retry: null,
        name: r'companyMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a company; true once it is gone.

  CompanyMutationNotifierProvider call(String id) =>
      CompanyMutationNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'companyMutationProvider';
}

/// Deletes a company; true once it is gone.

abstract class _$CompanyMutationNotifier extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<bool> build(String id);
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
