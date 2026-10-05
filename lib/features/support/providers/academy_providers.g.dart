// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(academyRepository)
final academyRepositoryProvider = AcademyRepositoryProvider._();

final class AcademyRepositoryProvider
    extends
        $FunctionalProvider<
          AcademyRepository,
          AcademyRepository,
          AcademyRepository
        >
    with $Provider<AcademyRepository> {
  AcademyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyRepositoryHash();

  @$internal
  @override
  $ProviderElement<AcademyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AcademyRepository create(Ref ref) {
    return academyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AcademyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AcademyRepository>(value),
    );
  }
}

String _$academyRepositoryHash() => r'175701834175885fb86e8116713783d3823ade34';

@ProviderFor(academyHome)
final academyHomeProvider = AcademyHomeProvider._();

final class AcademyHomeProvider
    extends
        $FunctionalProvider<
          AsyncValue<AcademyHome>,
          AcademyHome,
          FutureOr<AcademyHome>
        >
    with $FutureModifier<AcademyHome>, $FutureProvider<AcademyHome> {
  AcademyHomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyHomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyHomeHash();

  @$internal
  @override
  $FutureProviderElement<AcademyHome> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AcademyHome> create(Ref ref) {
    return academyHome(ref);
  }
}

String _$academyHomeHash() => r'786940bb6d329f6c0c0ecbf365d495890a020d5e';

@ProviderFor(careerPath)
final careerPathProvider = CareerPathProvider._();

final class CareerPathProvider
    extends
        $FunctionalProvider<
          AsyncValue<CareerPath>,
          CareerPath,
          FutureOr<CareerPath>
        >
    with $FutureModifier<CareerPath>, $FutureProvider<CareerPath> {
  CareerPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'careerPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$careerPathHash();

  @$internal
  @override
  $FutureProviderElement<CareerPath> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CareerPath> create(Ref ref) {
    return careerPath(ref);
  }
}

String _$careerPathHash() => r'883d315dc02d5d17b6f64524ed0a861072d63456';

@ProviderFor(lesson)
final lessonProvider = LessonFamily._();

final class LessonProvider
    extends $FunctionalProvider<AsyncValue<Lesson>, Lesson, FutureOr<Lesson>>
    with $FutureModifier<Lesson>, $FutureProvider<Lesson> {
  LessonProvider._({
    required LessonFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lessonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lessonHash();

  @override
  String toString() {
    return r'lessonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Lesson> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Lesson> create(Ref ref) {
    final argument = this.argument as String;
    return lesson(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lessonHash() => r'899be76f146fdaa80fc2a2ef319a92208c6c6124';

final class LessonFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Lesson>, String> {
  LessonFamily._()
    : super(
        retry: null,
        name: r'lessonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LessonProvider call(String id) => LessonProvider._(argument: id, from: this);

  @override
  String toString() => r'lessonProvider';
}

/// The academy's category chip; null shows the "for you" home.

@ProviderFor(AcademyCategoryNotifier)
final academyCategoryProvider = AcademyCategoryNotifierProvider._();

/// The academy's category chip; null shows the "for you" home.
final class AcademyCategoryNotifierProvider
    extends $NotifierProvider<AcademyCategoryNotifier, LessonCategory?> {
  /// The academy's category chip; null shows the "for you" home.
  AcademyCategoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyCategoryNotifierHash();

  @$internal
  @override
  AcademyCategoryNotifier create() => AcademyCategoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonCategory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonCategory?>(value),
    );
  }
}

String _$academyCategoryNotifierHash() =>
    r'd38ee5cb3795a4c890e1e8e63188444b6101adc0';

/// The academy's category chip; null shows the "for you" home.

abstract class _$AcademyCategoryNotifier extends $Notifier<LessonCategory?> {
  LessonCategory? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LessonCategory?, LessonCategory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LessonCategory?, LessonCategory?>,
              LessonCategory?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AcademyLessonsNotifier)
final academyLessonsProvider = AcademyLessonsNotifierFamily._();

final class AcademyLessonsNotifierProvider
    extends $AsyncNotifierProvider<AcademyLessonsNotifier, Paged<Lesson>> {
  AcademyLessonsNotifierProvider._({
    required AcademyLessonsNotifierFamily super.from,
    required LessonCategory super.argument,
  }) : super(
         retry: null,
         name: r'academyLessonsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$academyLessonsNotifierHash();

  @override
  String toString() {
    return r'academyLessonsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AcademyLessonsNotifier create() => AcademyLessonsNotifier();

  @override
  bool operator ==(Object other) {
    return other is AcademyLessonsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$academyLessonsNotifierHash() =>
    r'f158b5acc89d3f10d6e73f7edf221cd14cad5ab1';

final class AcademyLessonsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AcademyLessonsNotifier,
          AsyncValue<Paged<Lesson>>,
          Paged<Lesson>,
          FutureOr<Paged<Lesson>>,
          LessonCategory
        > {
  AcademyLessonsNotifierFamily._()
    : super(
        retry: null,
        name: r'academyLessonsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AcademyLessonsNotifierProvider call(LessonCategory category) =>
      AcademyLessonsNotifierProvider._(argument: category, from: this);

  @override
  String toString() => r'academyLessonsProvider';
}

abstract class _$AcademyLessonsNotifier extends $AsyncNotifier<Paged<Lesson>> {
  late final _$args = ref.$arg as LessonCategory;
  LessonCategory get category => _$args;

  FutureOr<Paged<Lesson>> build(LessonCategory category);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Lesson>>, Paged<Lesson>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Lesson>>, Paged<Lesson>>,
              AsyncValue<Paged<Lesson>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Completes lesson [id]; holds the finished lesson once saved.

@ProviderFor(LessonCompleteNotifier)
final lessonCompleteProvider = LessonCompleteNotifierFamily._();

/// Completes lesson [id]; holds the finished lesson once saved.
final class LessonCompleteNotifierProvider
    extends $AsyncNotifierProvider<LessonCompleteNotifier, Lesson?> {
  /// Completes lesson [id]; holds the finished lesson once saved.
  LessonCompleteNotifierProvider._({
    required LessonCompleteNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lessonCompleteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lessonCompleteNotifierHash();

  @override
  String toString() {
    return r'lessonCompleteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LessonCompleteNotifier create() => LessonCompleteNotifier();

  @override
  bool operator ==(Object other) {
    return other is LessonCompleteNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lessonCompleteNotifierHash() =>
    r'7bd1bdabf78fd371887d380355bda8ed92056a91';

/// Completes lesson [id]; holds the finished lesson once saved.

final class LessonCompleteNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          LessonCompleteNotifier,
          AsyncValue<Lesson?>,
          Lesson?,
          FutureOr<Lesson?>,
          String
        > {
  LessonCompleteNotifierFamily._()
    : super(
        retry: null,
        name: r'lessonCompleteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Completes lesson [id]; holds the finished lesson once saved.

  LessonCompleteNotifierProvider call(String id) =>
      LessonCompleteNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'lessonCompleteProvider';
}

/// Completes lesson [id]; holds the finished lesson once saved.

abstract class _$LessonCompleteNotifier extends $AsyncNotifier<Lesson?> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<Lesson?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Lesson?>, Lesson?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Lesson?>, Lesson?>,
              AsyncValue<Lesson?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
