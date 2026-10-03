// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactsRepository)
final contactsRepositoryProvider = ContactsRepositoryProvider._();

final class ContactsRepositoryProvider
    extends
        $FunctionalProvider<
          ContactsRepository,
          ContactsRepository,
          ContactsRepository
        >
    with $Provider<ContactsRepository> {
  ContactsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContactsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContactsRepository create(Ref ref) {
    return contactsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsRepository>(value),
    );
  }
}

String _$contactsRepositoryHash() =>
    r'ad2dcc4ff3c44c6e2f131f3c177498f4056f5a90';

@ProviderFor(ContactsFilterNotifier)
final contactsFilterProvider = ContactsFilterNotifierProvider._();

final class ContactsFilterNotifierProvider
    extends $NotifierProvider<ContactsFilterNotifier, ContactsFilter> {
  ContactsFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsFilterNotifierHash();

  @$internal
  @override
  ContactsFilterNotifier create() => ContactsFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsFilter>(value),
    );
  }
}

String _$contactsFilterNotifierHash() =>
    r'f497cdb9b70b8fe71ca990d33693402adf3a2445';

abstract class _$ContactsFilterNotifier extends $Notifier<ContactsFilter> {
  ContactsFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ContactsFilter, ContactsFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContactsFilter, ContactsFilter>,
              ContactsFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ContactsListNotifier)
final contactsListProvider = ContactsListNotifierProvider._();

final class ContactsListNotifierProvider
    extends $AsyncNotifierProvider<ContactsListNotifier, Paged<Contact>> {
  ContactsListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsListNotifierHash();

  @$internal
  @override
  ContactsListNotifier create() => ContactsListNotifier();
}

String _$contactsListNotifierHash() =>
    r'8f2451f65244d5c9f1381e569f26fc98bf9b0d1a';

abstract class _$ContactsListNotifier extends $AsyncNotifier<Paged<Contact>> {
  FutureOr<Paged<Contact>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Contact>>, Paged<Contact>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Contact>>, Paged<Contact>>,
              AsyncValue<Paged<Contact>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(contact)
final contactProvider = ContactFamily._();

final class ContactProvider
    extends $FunctionalProvider<AsyncValue<Contact>, Contact, FutureOr<Contact>>
    with $FutureModifier<Contact>, $FutureProvider<Contact> {
  ContactProvider._({
    required ContactFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactHash();

  @override
  String toString() {
    return r'contactProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Contact> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Contact> create(Ref ref) {
    final argument = this.argument as int;
    return contact(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactHash() => r'7657552a61e410511444d653d725bd46a7163c45';

final class ContactFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Contact>, int> {
  ContactFamily._()
    : super(
        retry: null,
        name: r'contactProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactProvider call(int id) => ContactProvider._(argument: id, from: this);

  @override
  String toString() => r'contactProvider';
}

@ProviderFor(contactLeads)
final contactLeadsProvider = ContactLeadsFamily._();

final class ContactLeadsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LinkedLead>>,
          List<LinkedLead>,
          FutureOr<List<LinkedLead>>
        >
    with $FutureModifier<List<LinkedLead>>, $FutureProvider<List<LinkedLead>> {
  ContactLeadsProvider._({
    required ContactLeadsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactLeadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactLeadsHash();

  @override
  String toString() {
    return r'contactLeadsProvider'
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
    return contactLeads(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactLeadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactLeadsHash() => r'7cf7091f4f9894b66f52f87b01da851b67b985dc';

final class ContactLeadsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LinkedLead>>, int> {
  ContactLeadsFamily._()
    : super(
        retry: null,
        name: r'contactLeadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactLeadsProvider call(int id) =>
      ContactLeadsProvider._(argument: id, from: this);

  @override
  String toString() => r'contactLeadsProvider';
}

@ProviderFor(contactActivity)
final contactActivityProvider = ContactActivityFamily._();

final class ContactActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ContactActivity>>,
          List<ContactActivity>,
          FutureOr<List<ContactActivity>>
        >
    with
        $FutureModifier<List<ContactActivity>>,
        $FutureProvider<List<ContactActivity>> {
  ContactActivityProvider._({
    required ContactActivityFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactActivityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactActivityHash();

  @override
  String toString() {
    return r'contactActivityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ContactActivity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ContactActivity>> create(Ref ref) {
    final argument = this.argument as int;
    return contactActivity(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactActivityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactActivityHash() => r'c54c9684fbdb31413167a4483af1cdc5ba7990ce';

final class ContactActivityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ContactActivity>>, int> {
  ContactActivityFamily._()
    : super(
        retry: null,
        name: r'contactActivityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactActivityProvider call(int id) =>
      ContactActivityProvider._(argument: id, from: this);

  @override
  String toString() => r'contactActivityProvider';
}

/// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
/// so the form can offer to open the existing contact or save anyway.

@ProviderFor(ContactSaveNotifier)
final contactSaveProvider = ContactSaveNotifierFamily._();

/// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
/// so the form can offer to open the existing contact or save anyway.
final class ContactSaveNotifierProvider
    extends $AsyncNotifierProvider<ContactSaveNotifier, SaveOutcome<Contact>?> {
  /// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
  /// so the form can offer to open the existing contact or save anyway.
  ContactSaveNotifierProvider._({
    required ContactSaveNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactSaveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactSaveNotifierHash();

  @override
  String toString() {
    return r'contactSaveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ContactSaveNotifier create() => ContactSaveNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContactSaveNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactSaveNotifierHash() =>
    r'14602d1366412fadd98bb2de4c1a1ca5f4f89b83';

/// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
/// so the form can offer to open the existing contact or save anyway.

final class ContactSaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContactSaveNotifier,
          AsyncValue<SaveOutcome<Contact>?>,
          SaveOutcome<Contact>?,
          FutureOr<SaveOutcome<Contact>?>,
          int
        > {
  ContactSaveNotifierFamily._()
    : super(
        retry: null,
        name: r'contactSaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
  /// so the form can offer to open the existing contact or save anyway.

  ContactSaveNotifierProvider call(int id) =>
      ContactSaveNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'contactSaveProvider';
}

/// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
/// so the form can offer to open the existing contact or save anyway.

abstract class _$ContactSaveNotifier
    extends $AsyncNotifier<SaveOutcome<Contact>?> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<SaveOutcome<Contact>?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SaveOutcome<Contact>?>, SaveOutcome<Contact>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SaveOutcome<Contact>?>,
                SaveOutcome<Contact>?
              >,
              AsyncValue<SaveOutcome<Contact>?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Deletes one contact; screens listen for [RecordChange.deleted].

@ProviderFor(ContactMutationNotifier)
final contactMutationProvider = ContactMutationNotifierFamily._();

/// Deletes one contact; screens listen for [RecordChange.deleted].
final class ContactMutationNotifierProvider
    extends $AsyncNotifierProvider<ContactMutationNotifier, RecordChange?> {
  /// Deletes one contact; screens listen for [RecordChange.deleted].
  ContactMutationNotifierProvider._({
    required ContactMutationNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'contactMutationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactMutationNotifierHash();

  @override
  String toString() {
    return r'contactMutationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ContactMutationNotifier create() => ContactMutationNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContactMutationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactMutationNotifierHash() =>
    r'3dcb91ad885537c8cc58d3f5071b3a0d74f617b0';

/// Deletes one contact; screens listen for [RecordChange.deleted].

final class ContactMutationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContactMutationNotifier,
          AsyncValue<RecordChange?>,
          RecordChange?,
          FutureOr<RecordChange?>,
          int
        > {
  ContactMutationNotifierFamily._()
    : super(
        retry: null,
        name: r'contactMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes one contact; screens listen for [RecordChange.deleted].

  ContactMutationNotifierProvider call(int id) =>
      ContactMutationNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'contactMutationProvider';
}

/// Deletes one contact; screens listen for [RecordChange.deleted].

abstract class _$ContactMutationNotifier extends $AsyncNotifier<RecordChange?> {
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
