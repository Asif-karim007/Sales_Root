// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskApi)
final taskApiProvider = TaskApiProvider._();

final class TaskApiProvider
    extends $FunctionalProvider<TaskApi, TaskApi, TaskApi>
    with $Provider<TaskApi> {
  TaskApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskApiHash();

  @$internal
  @override
  $ProviderElement<TaskApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskApi create(Ref ref) {
    return taskApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskApi>(value),
    );
  }
}

String _$taskApiHash() => r'd693ea1e327491e070eb18c10447b38a2c683d16';

@ProviderFor(taskRepository)
final taskRepositoryProvider = TaskRepositoryProvider._();

final class TaskRepositoryProvider
    extends $FunctionalProvider<TaskRepository, TaskRepository, TaskRepository>
    with $Provider<TaskRepository> {
  TaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskRepository create(Ref ref) {
    return taskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskRepository>(value),
    );
  }
}

String _$taskRepositoryHash() => r'af1a9bdadf3f524370756686dde1640a3d610c30';

@ProviderFor(taskLookupRepository)
final taskLookupRepositoryProvider = TaskLookupRepositoryProvider._();

final class TaskLookupRepositoryProvider
    extends
        $FunctionalProvider<
          TaskLookupRepository,
          TaskLookupRepository,
          TaskLookupRepository
        >
    with $Provider<TaskLookupRepository> {
  TaskLookupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskLookupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskLookupRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaskLookupRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskLookupRepository create(Ref ref) {
    return taskLookupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskLookupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskLookupRepository>(value),
    );
  }
}

String _$taskLookupRepositoryHash() =>
    r'd23d3a9b78b8636aa08ef14f6b0c32a876b63cff';

@ProviderFor(TaskBucketNotifier)
final taskBucketProvider = TaskBucketNotifierProvider._();

final class TaskBucketNotifierProvider
    extends $NotifierProvider<TaskBucketNotifier, TaskBucket> {
  TaskBucketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskBucketProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskBucketNotifierHash();

  @$internal
  @override
  TaskBucketNotifier create() => TaskBucketNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskBucket value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskBucket>(value),
    );
  }
}

String _$taskBucketNotifierHash() =>
    r'a5bc5df646e5c59960bb603dd6f4c4f2eccd6fd1';

abstract class _$TaskBucketNotifier extends $Notifier<TaskBucket> {
  TaskBucket build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TaskBucket, TaskBucket>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaskBucket, TaskBucket>,
              TaskBucket,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TaskFilterNotifier)
final taskFilterProvider = TaskFilterNotifierProvider._();

final class TaskFilterNotifierProvider
    extends $NotifierProvider<TaskFilterNotifier, TaskFilter> {
  TaskFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskFilterNotifierHash();

  @$internal
  @override
  TaskFilterNotifier create() => TaskFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskFilter>(value),
    );
  }
}

String _$taskFilterNotifierHash() =>
    r'9eabeff9bc971db9b6617a914c2852869a39bfc3';

abstract class _$TaskFilterNotifier extends $Notifier<TaskFilter> {
  TaskFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TaskFilter, TaskFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaskFilter, TaskFilter>,
              TaskFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(taskCounts)
final taskCountsProvider = TaskCountsProvider._();

final class TaskCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TaskCounts>,
          TaskCounts,
          FutureOr<TaskCounts>
        >
    with $FutureModifier<TaskCounts>, $FutureProvider<TaskCounts> {
  TaskCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskCountsHash();

  @$internal
  @override
  $FutureProviderElement<TaskCounts> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TaskCounts> create(Ref ref) {
    return taskCounts(ref);
  }
}

String _$taskCountsHash() => r'ebde8d1077a93134370fc05e59e7efa6b9ad5526';

@ProviderFor(TaskListNotifier)
final taskListProvider = TaskListNotifierProvider._();

final class TaskListNotifierProvider
    extends $AsyncNotifierProvider<TaskListNotifier, Paged<Task>> {
  TaskListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskListNotifierHash();

  @$internal
  @override
  TaskListNotifier create() => TaskListNotifier();
}

String _$taskListNotifierHash() => r'cb3afb2d96de5bbed6f8070248e007a1ca973b2a';

abstract class _$TaskListNotifier extends $AsyncNotifier<Paged<Task>> {
  FutureOr<Paged<Task>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Task>>, Paged<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Task>>, Paged<Task>>,
              AsyncValue<Paged<Task>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(task)
final taskProvider = TaskFamily._();

final class TaskProvider
    extends $FunctionalProvider<AsyncValue<Task>, Task, FutureOr<Task>>
    with $FutureModifier<Task>, $FutureProvider<Task> {
  TaskProvider._({
    required TaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'taskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskHash();

  @override
  String toString() {
    return r'taskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Task> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Task> create(Ref ref) {
    final argument = this.argument as String;
    return task(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskHash() => r'1a02ed026cf4ac6368d2700095e894aef5707b62';

final class TaskFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Task>, String> {
  TaskFamily._()
    : super(
        retry: null,
        name: r'taskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaskProvider call(String id) => TaskProvider._(argument: id, from: this);

  @override
  String toString() => r'taskProvider';
}

@ProviderFor(taskMembers)
final taskMembersProvider = TaskMembersProvider._();

final class TaskMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberOption>>,
          List<MemberOption>,
          FutureOr<List<MemberOption>>
        >
    with
        $FutureModifier<List<MemberOption>>,
        $FutureProvider<List<MemberOption>> {
  TaskMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<MemberOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MemberOption>> create(Ref ref) {
    return taskMembers(ref);
  }
}

String _$taskMembersHash() => r'254ae5c9ccd43445e171c780da70601bbf60017f';

/// Task actions outside the list and the form. Each one refreshes every view
/// of tasks.

@ProviderFor(TaskEditor)
final taskEditorProvider = TaskEditorProvider._();

/// Task actions outside the list and the form. Each one refreshes every view
/// of tasks.
final class TaskEditorProvider extends $NotifierProvider<TaskEditor, void> {
  /// Task actions outside the list and the form. Each one refreshes every view
  /// of tasks.
  TaskEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskEditorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskEditorHash();

  @$internal
  @override
  TaskEditor create() => TaskEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$taskEditorHash() => r'358c751a77af712cc64ff7a10b8e37c301b9d559';

/// Task actions outside the list and the form. Each one refreshes every view
/// of tasks.

abstract class _$TaskEditor extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
/// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
/// default.

@ProviderFor(TaskFormNotifier)
final taskFormProvider = TaskFormNotifierFamily._();

/// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
/// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
/// default.
final class TaskFormNotifierProvider
    extends $AsyncNotifierProvider<TaskFormNotifier, TaskDraft> {
  /// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
  /// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
  /// default.
  TaskFormNotifierProvider._({
    required TaskFormNotifierFamily super.from,
    required ({String? taskId, String? leadId, String? title, DateTime? day})
    super.argument,
  }) : super(
         retry: null,
         name: r'taskFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskFormNotifierHash();

  @override
  String toString() {
    return r'taskFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TaskFormNotifier create() => TaskFormNotifier();

  @override
  bool operator ==(Object other) {
    return other is TaskFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskFormNotifierHash() => r'53e1e849d39d9273953b367340014f89e907842d';

/// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
/// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
/// default.

final class TaskFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskFormNotifier,
          AsyncValue<TaskDraft>,
          TaskDraft,
          FutureOr<TaskDraft>,
          ({String? taskId, String? leadId, String? title, DateTime? day})
        > {
  TaskFormNotifierFamily._()
    : super(
        retry: null,
        name: r'taskFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
  /// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
  /// default.

  TaskFormNotifierProvider call({
    String? taskId,
    String? leadId,
    String? title,
    DateTime? day,
  }) => TaskFormNotifierProvider._(
    argument: (taskId: taskId, leadId: leadId, title: title, day: day),
    from: this,
  );

  @override
  String toString() => r'taskFormProvider';
}

/// The new-task form, prefilled from `?leadId=&title=&date=`, or the edit
/// form for [taskId]. A new task is due at 10:00 on [day], tomorrow by
/// default.

abstract class _$TaskFormNotifier extends $AsyncNotifier<TaskDraft> {
  late final _$args =
      ref.$arg
          as ({String? taskId, String? leadId, String? title, DateTime? day});
  String? get taskId => _$args.taskId;
  String? get leadId => _$args.leadId;
  String? get title => _$args.title;
  DateTime? get day => _$args.day;

  FutureOr<TaskDraft> build({
    String? taskId,
    String? leadId,
    String? title,
    DateTime? day,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TaskDraft>, TaskDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TaskDraft>, TaskDraft>,
              AsyncValue<TaskDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        taskId: _$args.taskId,
        leadId: _$args.leadId,
        title: _$args.title,
        day: _$args.day,
      ),
    );
  }
}
