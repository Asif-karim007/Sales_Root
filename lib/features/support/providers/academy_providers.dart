import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/data/academy_repository.dart';
import 'package:salesroot/features/support/data/fake_academy_repository.dart';
import 'package:salesroot/features/support/models/lesson.dart';

part 'academy_providers.g.dart';

@Riverpod(keepAlive: true)
AcademyRepository academyRepository(Ref ref) =>
    FakeAcademyRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<AcademyHome> academyHome(Ref ref) =>
    ref.watch(academyRepositoryProvider).home();

@riverpod
Future<CareerPath> careerPath(Ref ref) =>
    ref.watch(academyRepositoryProvider).careerPath();

@riverpod
Future<Lesson> lesson(Ref ref, int id) =>
    ref.watch(academyRepositoryProvider).lesson(id);

/// The academy's category chip; null shows the "for you" home.
@riverpod
class AcademyCategoryNotifier extends _$AcademyCategoryNotifier {
  @override
  LessonCategory? build() => null;

  void select(LessonCategory? category) => state = category;
}

@riverpod
class AcademyLessonsNotifier extends _$AcademyLessonsNotifier {
  @override
  Future<Paged<Lesson>> build(LessonCategory category) async =>
      Paged.first(await ref.watch(academyRepositoryProvider).lessons(category));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(academyRepositoryProvider)
          .lessons(category, page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

/// Completes lesson [id]; holds the finished lesson once saved.
@riverpod
class LessonCompleteNotifier extends _$LessonCompleteNotifier {
  @override
  FutureOr<Lesson?> build(int id) => null;

  Future<void> complete({int? quizAnswer}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(academyRepositoryProvider)
          .complete(id, quizAnswer: quizAnswer),
    );
    if (!ref.mounted) return;
    state = result;
    if (!result.hasValue) return;
    ref
      ..invalidate(lessonProvider(id))
      ..invalidate(academyHomeProvider)
      ..invalidate(careerPathProvider)
      ..invalidate(academyLessonsProvider);
  }
}
