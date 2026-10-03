import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/features/support/data/fake_help_repository.dart';
import 'package:salesroot/features/support/data/guide_matcher.dart';
import 'package:salesroot/features/support/data/guide_repository.dart';
import 'package:salesroot/features/support/models/guide.dart';

class FakeGuideRepository implements GuideRepository {
  FakeGuideRepository(this._backend);

  final FakeBackend _backend;

  @override
  Future<GuideAnswer> ask(GuideQuestion question) => _backend.run(
    'Guide ask',
    () => GuideMatcher(
      articles: helpTable(_backend).rows,
      graph: _backend.graph,
    ).answer(question),
  );
}
