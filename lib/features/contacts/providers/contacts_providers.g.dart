// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactsApi)
final contactsApiProvider = ContactsApiProvider._();

final class ContactsApiProvider
    extends $FunctionalProvider<ContactsApi, ContactsApi, ContactsApi>
    with $Provider<ContactsApi> {
  ContactsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsApiHash();

  @$internal
  @override
  $ProviderElement<ContactsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContactsApi create(Ref ref) {
    return contactsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsApi>(value),
    );
  }
}

String _$contactsApiHash() => r'6f2a449bc51f9601495e25d0030f180b77c539af';

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
    r'038737462f46feed10629f547674683b34047213';

@ProviderFor(ContactsSearchNotifier)
final contactsSearchProvider = ContactsSearchNotifierProvider._();

final class ContactsSearchNotifierProvider
    extends $NotifierProvider<ContactsSearchNotifier, String> {
  ContactsSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsSearchNotifierHash();

  @$internal
  @override
  ContactsSearchNotifier create() => ContactsSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$contactsSearchNotifierHash() =>
    r'3ea110a235dd81aa614e5caa49d9eb92c6e91844';

abstract class _$ContactsSearchNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
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
    r'36be770780c71f7ee15ad4a9f4f0dc0c2022fc74';

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

@ProviderFor(contactDetail)
final contactDetailProvider = ContactDetailFamily._();

final class ContactDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContactDetail>,
          ContactDetail,
          FutureOr<ContactDetail>
        >
    with $FutureModifier<ContactDetail>, $FutureProvider<ContactDetail> {
  ContactDetailProvider._({
    required ContactDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'contactDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contactDetailHash();

  @override
  String toString() {
    return r'contactDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ContactDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContactDetail> create(Ref ref) {
    final argument = this.argument as String;
    return contactDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContactDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contactDetailHash() => r'242938e9497be7c9b9615301966df1376706746e';

final class ContactDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ContactDetail>, String> {
  ContactDetailFamily._()
    : super(
        retry: null,
        name: r'contactDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactDetailProvider call(String id) =>
      ContactDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'contactDetailProvider';
}

@ProviderFor(contact)
final contactProvider = ContactFamily._();

final class ContactProvider
    extends $FunctionalProvider<AsyncValue<Contact>, Contact, FutureOr<Contact>>
    with $FutureModifier<Contact>, $FutureProvider<Contact> {
  ContactProvider._({
    required ContactFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$contactHash() => r'a8258ed43975614ed3cff5d02c0a9c6c62b6cf3b';

final class ContactFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Contact>, String> {
  ContactFamily._()
    : super(
        retry: null,
        name: r'contactProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactProvider call(String id) =>
      ContactProvider._(argument: id, from: this);

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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$contactLeadsHash() => r'c808ccd27cd30d57d436541ed6e8ba673b4e307c';

final class ContactLeadsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LinkedLead>>, String> {
  ContactLeadsFamily._()
    : super(
        retry: null,
        name: r'contactLeadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactLeadsProvider call(String id) =>
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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$contactActivityHash() => r'87be2ff95f391c5e3f949d08f805a938e6815d56';

final class ContactActivityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ContactActivity>>, String> {
  ContactActivityFamily._()
    : super(
        retry: null,
        name: r'contactActivityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContactActivityProvider call(String id) =>
      ContactActivityProvider._(argument: id, from: this);

  @override
  String toString() => r'contactActivityProvider';
}

/// Saves the contact form; an empty [id] creates. A 409 comes back as
/// [Duplicates] so the form can offer to open the existing contact.

@ProviderFor(ContactSaveNotifier)
final contactSaveProvider = ContactSaveNotifierFamily._();

/// Saves the contact form; an empty [id] creates. A 409 comes back as
/// [Duplicates] so the form can offer to open the existing contact.
final class ContactSaveNotifierProvider
    extends $AsyncNotifierProvider<ContactSaveNotifier, SaveOutcome<Contact>?> {
  /// Saves the contact form; an empty [id] creates. A 409 comes back as
  /// [Duplicates] so the form can offer to open the existing contact.
  ContactSaveNotifierProvider._({
    required ContactSaveNotifierFamily super.from,
    required String super.argument,
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
    r'ee02775576faf1d4aa7dfa95bade84368916f9e3';

/// Saves the contact form; an empty [id] creates. A 409 comes back as
/// [Duplicates] so the form can offer to open the existing contact.

final class ContactSaveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContactSaveNotifier,
          AsyncValue<SaveOutcome<Contact>?>,
          SaveOutcome<Contact>?,
          FutureOr<SaveOutcome<Contact>?>,
          String
        > {
  ContactSaveNotifierFamily._()
    : super(
        retry: null,
        name: r'contactSaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Saves the contact form; an empty [id] creates. A 409 comes back as
  /// [Duplicates] so the form can offer to open the existing contact.

  ContactSaveNotifierProvider call(String id) =>
      ContactSaveNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'contactSaveProvider';
}

/// Saves the contact form; an empty [id] creates. A 409 comes back as
/// [Duplicates] so the form can offer to open the existing contact.

abstract class _$ContactSaveNotifier
    extends $AsyncNotifier<SaveOutcome<Contact>?> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<SaveOutcome<Contact>?> build(String id);
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

/// Deletes one contact; true once it is gone.

@ProviderFor(ContactMutationNotifier)
final contactMutationProvider = ContactMutationNotifierFamily._();

/// Deletes one contact; true once it is gone.
final class ContactMutationNotifierProvider
    extends $AsyncNotifierProvider<ContactMutationNotifier, bool> {
  /// Deletes one contact; true once it is gone.
  ContactMutationNotifierProvider._({
    required ContactMutationNotifierFamily super.from,
    required String super.argument,
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
    r'209db713094ffd99b0de023fbb339cd4af156b30';

/// Deletes one contact; true once it is gone.

final class ContactMutationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContactMutationNotifier,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  ContactMutationNotifierFamily._()
    : super(
        retry: null,
        name: r'contactMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes one contact; true once it is gone.

  ContactMutationNotifierProvider call(String id) =>
      ContactMutationNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'contactMutationProvider';
}

/// Deletes one contact; true once it is gone.

abstract class _$ContactMutationNotifier extends $AsyncNotifier<bool> {
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
