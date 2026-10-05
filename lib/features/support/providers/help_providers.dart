import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/data/fake_help_repository.dart';
import 'package:salesroot/features/support/data/help_repository.dart';
import 'package:salesroot/features/support/models/help_article.dart';

part 'help_providers.g.dart';

@Riverpod(keepAlive: true)
HelpRepository helpRepository(Ref ref) =>
    FakeHelpRepository(ref.watch(fakeBackendProvider));

@riverpod
class HelpQueryNotifier extends _$HelpQueryNotifier {
  @override
  HelpQuery build() => const HelpQuery();

  void setTerm(String term) => state = state.copyWith(term: term);

  void setCategory(HelpCategory? category) =>
      state = state.copyWith(category: () => category);
}

/// Search results for the current [HelpQuery], 20 at a time.
@riverpod
class HelpSearchNotifier extends _$HelpSearchNotifier {
  @override
  Future<Paged<HelpArticle>> build() async {
    final query = ref.watch(helpQueryProvider);
    final result = await ref.watch(helpRepositoryProvider).articles(query);
    return Paged.first(result);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(helpRepositoryProvider)
          .articles(ref.read(helpQueryProvider), page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

@riverpod
Future<List<HelpArticle>> popularArticles(Ref ref) =>
    ref.watch(helpRepositoryProvider).popular();

@riverpod
Future<HelpArticle> helpArticle(Ref ref, String id) =>
    ref.watch(helpRepositoryProvider).article(id);

/// The reader's "did this help?" answer; null until they answer.
@riverpod
class ArticleVoteNotifier extends _$ArticleVoteNotifier {
  @override
  FutureOr<bool?> build(String id) => null;

  Future<void> vote({required bool helpful}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(helpRepositoryProvider).rate(id, helpful: helpful);
      return helpful;
    });
    if (!ref.mounted) return;
    state = result;
  }
}
