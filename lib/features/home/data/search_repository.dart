import 'package:salesroot/features/home/models/search_result.dart';

abstract interface class SearchRepository {
  /// Matches across leads, contacts, companies and tasks. Searching
  /// everything returns the top few of each kind; a single kind pages 20 at
  /// a time.
  Future<SearchResults> search(SearchQuery query, {int page = 1});
}
