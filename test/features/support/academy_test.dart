import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/models/lesson.dart';
import 'package:salesroot/features/support/providers/academy_providers.dart';

import 'support_test_container.dart';

void main() {
  const handlingObjections = 14;

  test('completing a career lesson updates every progress view', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container
      ..listen(careerPathProvider, (_, _) {})
      ..listen(academyHomeProvider, (_, _) {})
      ..listen(lessonProvider(handlingObjections), (_, _) {})
      ..listen(lessonCompleteProvider(handlingObjections), (_, _) {});

    final before = await container.read(careerPathProvider.future);
    expect(before.done, 3);
    expect(before.steps[3].status, CareerStepStatus.current);
    final lesson = await container.read(
      lessonProvider(handlingObjections).future,
    );
    final quiz = lesson.quiz;
    expect(quiz, isNotNull);

    final complete = container.read(
      lessonCompleteProvider(handlingObjections).notifier,
    );
    await complete.complete(quizAnswer: quiz?.correctIndex);

    final after = await container.read(careerPathProvider.future);
    expect(after.done, 4);
    expect(after.steps[3].status, CareerStepStatus.done);
    expect(after.steps[4].status, CareerStepStatus.current);
    final home = await container.read(academyHomeProvider.future);
    expect(home.career.done, 4);
    final done = await container.read(
      lessonProvider(handlingObjections).future,
    );
    expect(done.isDone, isTrue);
  });

  test('a wrong quiz answer does not complete the lesson', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(lessonCompleteProvider(3), (_, _) {});
    final lesson = await container.read(academyRepositoryProvider).lesson(3);
    final wrong = (lesson.quiz?.correctIndex ?? 0) == 0 ? 1 : 0;

    await container
        .read(lessonCompleteProvider(3).notifier)
        .complete(quizAnswer: wrong);

    final error = container.read(lessonCompleteProvider(3)).error;
    expect(error, isA<ApiFailure>().having((f) => f.isValidation, '400', true));
    final unchanged = await container.read(academyRepositoryProvider).lesson(3);
    expect(unchanged.progress, 40);
  });

  test('a later career step stays locked', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    final repository = container.read(academyRepositoryProvider);
    final coaching = await repository.lesson(16);

    await expectLater(
      repository.complete(16, quizAnswer: coaching.quiz?.correctIndex),
      throwsA(isA<ApiFailure>().having((f) => f.isConflict, '409', true)),
    );
  });

  test('a category lists only its lessons', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    final provider = academyLessonsProvider(LessonCategory.career);
    container.listen(provider, (_, _) {});

    final page = await container.read(provider.future);
    expect(page.items.map((l) => l.careerStep), [1, 2, 3, 4, 5, 6, 7, 8]);
  });
}
