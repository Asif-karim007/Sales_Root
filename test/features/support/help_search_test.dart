import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/providers/help_providers.dart';

import 'support_test_container.dart';

void main() {
  test('browsing pages 20 at a time and loads the rest on scroll', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(helpSearchProvider, (_, _) {});

    final first = await container.read(helpSearchProvider.future);
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);

    await container.read(helpSearchProvider.notifier).loadMore();
    final all = container.read(helpSearchProvider).requireValue;
    expect(all.items.length, all.totalCount);
    expect(all.hasMore, isFalse);
  });

  test('search matches English and Bangla words', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(helpSearchProvider, (_, _) {});
    final query = container.read(helpQueryProvider.notifier);

    query.setTerm('visiting card');
    final english = await container.read(helpSearchProvider.future);
    expect(english.items.first.title.en, 'How do I scan a visiting card?');

    query.setTerm('কালেকশন');
    final bangla = await container.read(helpSearchProvider.future);
    expect(
      bangla.items.map((a) => a.title.en),
      contains('How do I record a collection?'),
    );

    query.setTerm('zzz nothing like this');
    final none = await container.read(helpSearchProvider.future);
    expect(none.isEmpty, isTrue);
  });

  test('a category narrows the results', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(helpSearchProvider, (_, _) {});

    container.read(helpQueryProvider.notifier).setCategory(HelpCategory.sales);
    final page = await container.read(helpSearchProvider.future);
    expect(page.items, isNotEmpty);
    expect(page.items.every((a) => a.category == HelpCategory.sales), isTrue);
  });

  test('offline shows the offline failure', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));
    container.listen(helpSearchProvider, (_, _) {});

    await expectLater(
      container.read(helpSearchProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });

  test('a helpful vote is recorded', () async {
    final container = await supportContainer();
    addTearDown(container.dispose);
    container.listen(articleVoteProvider(1), (_, _) {});
    container.listen(helpArticleProvider(1), (_, _) {});
    final before = await container.read(helpArticleProvider(1).future);

    await container.read(articleVoteProvider(1).notifier).vote(helpful: true);
    container.invalidate(helpArticleProvider(1));
    final after = await container.read(helpArticleProvider(1).future);

    expect(container.read(articleVoteProvider(1)).value, isTrue);
    expect(after.helpfulCount, before.helpfulCount + 1);
  });
}
