import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/models/help_article.dart';

abstract interface class HelpRepository {
  /// Articles matching [query], 20 per page.
  Future<PageResult<HelpArticle>> articles(HelpQuery query, {int page = 1});

  Future<List<HelpArticle>> popular();

  Future<HelpArticle> article(String id);

  /// Records the "did this help?" answer.
  Future<void> rate(String id, {required bool helpful});
}
