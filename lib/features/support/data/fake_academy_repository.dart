import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/academy_fixtures.dart';
import 'package:salesroot/features/support/data/academy_repository.dart';
import 'package:salesroot/features/support/models/lesson.dart';

class FakeAcademyRepository implements AcademyRepository {
  FakeAcademyRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.store.table(
    'support/lessons',
    () => lessonFixtures(_backend.graph),
    always: true,
  );

  @override
  Future<AcademyHome> home() => _backend.run('Academy home', () {
    final rows = _table.rows;
    final tip = rows.where((row) => row['Tip'] == true).firstOrNull;
    final forYou = rows.where((row) => row['Recommended'] != null).toList()
      ..sort(
        (a, b) => (a['Recommended'] as int).compareTo(b['Recommended'] as int),
      );
    return AcademyHome.fromJson({
      'Tip': tip,
      'ForYou': forYou,
      'Career': _career(withSteps: false),
    });
  });

  @override
  Future<PageResult<Lesson>> lessons(LessonCategory category, {int page = 1}) =>
      _backend.run('Academy lessons ${category.wire}', () {
        final rows =
            _table.rows
                .where((row) => row['Category'] == category.wire)
                .toList()
              ..sort((a, b) => _order(a).compareTo(_order(b)));
        return PageResult.fromJson(fakePage(rows, page: page), Lesson.fromJson);
      });

  @override
  Future<Lesson> lesson(int id) => _backend.run(
    'Academy lesson $id',
    () => Lesson.fromJson(_table.byId(id)),
  );

  @override
  Future<Lesson> complete(int id, {int? quizAnswer}) => _backend.run(
    'Academy complete $id',
    () {
      final row = _table.byId(id);
      final quiz = jsonObject(row['Quiz'], (json) => json);
      if (quiz != null && quizAnswer != quiz['CorrectIndex']) {
        throw const ApiFailure(
          400,
          'Answer the question correctly to finish the lesson.',
          fieldErrors: {
            'QuizAnswer': 'Answer the question correctly to finish the lesson.',
          },
        );
      }
      final step = jsonInt(row['CareerStep']);
      if (step != null && step > 1) {
        final previous = _table.rows.firstWhere(
          (r) => r['CareerStep'] == step - 1,
        );
        if ((jsonInt(previous['Progress']) ?? 0) < 100) {
          throw const ApiFailure(409, 'Finish the earlier step first.');
        }
      }
      return Lesson.fromJson(
        _table.update(id, {'Progress': 100, 'IsNew': false}),
      );
    },
  );

  @override
  Future<CareerPath> careerPath() => _backend.run(
    'Academy career',
    () => CareerPath.fromJson(_career(withSteps: true)),
  );

  static int _order(Map<String, dynamic> row) =>
      jsonInt(row['CareerStep']) ?? jsonInt(row['Id']) ?? 0;

  Map<String, dynamic> _career({required bool withSteps}) {
    final rows = _table.rows.where((row) => row['CareerStep'] != null).toList()
      ..sort((a, b) => _order(a).compareTo(_order(b)));
    final steps = <Map<String, dynamic>>[];
    var current = false;
    for (final row in rows) {
      final done = (jsonInt(row['Progress']) ?? 0) >= 100;
      final status = done
          ? 'Done'
          : current
          ? 'Locked'
          : 'Current';
      if (!done) current = true;
      steps.add({
        'Index': row['CareerStep'],
        'LessonId': row['Id'],
        'Title': row['Title'],
        'TitleBn': row['TitleBn'],
        'Subtitle': row['Subtitle'],
        'SubtitleBn': row['SubtitleBn'],
        'Status': status,
      });
    }
    return {
      ...careerTitle,
      ...careerActivity,
      'Done': steps.where((step) => step['Status'] == 'Done').length,
      'Total': steps.length,
      if (withSteps) 'Steps': steps,
    };
  }
}
