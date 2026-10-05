import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/models/lesson.dart';

abstract interface class AcademyRepository {
  Future<AcademyHome> home();

  Future<PageResult<Lesson>> lessons(LessonCategory category, {int page = 1});

  Future<Lesson> lesson(String id);

  /// Marks [id] complete; [quizAnswer] must be right when it has a quiz.
  Future<Lesson> complete(String id, {int? quizAnswer});

  Future<CareerPath> careerPath();
}
