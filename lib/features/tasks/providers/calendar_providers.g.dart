// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calendarRepository)
final calendarRepositoryProvider = CalendarRepositoryProvider._();

final class CalendarRepositoryProvider
    extends
        $FunctionalProvider<
          CalendarRepository,
          CalendarRepository,
          CalendarRepository
        >
    with $Provider<CalendarRepository> {
  CalendarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalendarRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarRepository create(Ref ref) {
    return calendarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarRepository>(value),
    );
  }
}

String _$calendarRepositoryHash() =>
    r'df3b44fdc25587a8290eb49a291d77d8467de6d9';

@ProviderFor(CalendarCursorNotifier)
final calendarCursorProvider = CalendarCursorNotifierProvider._();

final class CalendarCursorNotifierProvider
    extends $NotifierProvider<CalendarCursorNotifier, CalendarCursor> {
  CalendarCursorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarCursorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarCursorNotifierHash();

  @$internal
  @override
  CalendarCursorNotifier create() => CalendarCursorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarCursor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarCursor>(value),
    );
  }
}

String _$calendarCursorNotifierHash() =>
    r'625bb16297ab1394a42b08e52fb0149e34b48702';

abstract class _$CalendarCursorNotifier extends $Notifier<CalendarCursor> {
  CalendarCursor build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarCursor, CalendarCursor>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarCursor, CalendarCursor>,
              CalendarCursor,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The user's tasks and private events in [from]..[to), merged.

@ProviderFor(calendarAgenda)
final calendarAgendaProvider = CalendarAgendaFamily._();

/// The user's tasks and private events in [from]..[to), merged.

final class CalendarAgendaProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalendarAgenda>,
          CalendarAgenda,
          FutureOr<CalendarAgenda>
        >
    with $FutureModifier<CalendarAgenda>, $FutureProvider<CalendarAgenda> {
  /// The user's tasks and private events in [from]..[to), merged.
  CalendarAgendaProvider._({
    required CalendarAgendaFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'calendarAgendaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarAgendaHash();

  @override
  String toString() {
    return r'calendarAgendaProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CalendarAgenda> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalendarAgenda> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return calendarAgenda(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarAgendaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarAgendaHash() => r'af9bc360012b57031816dfb59de76ffcad0b60e9';

/// The user's tasks and private events in [from]..[to), merged.

final class CalendarAgendaFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CalendarAgenda>,
          (DateTime, DateTime)
        > {
  CalendarAgendaFamily._()
    : super(
        retry: null,
        name: r'calendarAgendaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The user's tasks and private events in [from]..[to), merged.

  CalendarAgendaProvider call(DateTime from, DateTime to) =>
      CalendarAgendaProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'calendarAgendaProvider';
}

/// The private-event form: new on [day], or editing [eventId].

@ProviderFor(EventFormNotifier)
final eventFormProvider = EventFormNotifierFamily._();

/// The private-event form: new on [day], or editing [eventId].
final class EventFormNotifierProvider
    extends $AsyncNotifierProvider<EventFormNotifier, EventDraft> {
  /// The private-event form: new on [day], or editing [eventId].
  EventFormNotifierProvider._({
    required EventFormNotifierFamily super.from,
    required ({String? eventId, DateTime? day}) super.argument,
  }) : super(
         retry: null,
         name: r'eventFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventFormNotifierHash();

  @override
  String toString() {
    return r'eventFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  EventFormNotifier create() => EventFormNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventFormNotifierHash() => r'e5e5395b2cc18b947790fe381a4bacf1212dc308';

/// The private-event form: new on [day], or editing [eventId].

final class EventFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventFormNotifier,
          AsyncValue<EventDraft>,
          EventDraft,
          FutureOr<EventDraft>,
          ({String? eventId, DateTime? day})
        > {
  EventFormNotifierFamily._()
    : super(
        retry: null,
        name: r'eventFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The private-event form: new on [day], or editing [eventId].

  EventFormNotifierProvider call({String? eventId, DateTime? day}) =>
      EventFormNotifierProvider._(
        argument: (eventId: eventId, day: day),
        from: this,
      );

  @override
  String toString() => r'eventFormProvider';
}

/// The private-event form: new on [day], or editing [eventId].

abstract class _$EventFormNotifier extends $AsyncNotifier<EventDraft> {
  late final _$args = ref.$arg as ({String? eventId, DateTime? day});
  String? get eventId => _$args.eventId;
  DateTime? get day => _$args.day;

  FutureOr<EventDraft> build({String? eventId, DateTime? day});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EventDraft>, EventDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventDraft>, EventDraft>,
              AsyncValue<EventDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(eventId: _$args.eventId, day: _$args.day),
    );
  }
}
