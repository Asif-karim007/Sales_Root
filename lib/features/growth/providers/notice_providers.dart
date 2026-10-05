import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/data/fake_notice_repository.dart';
import 'package:salesroot/features/growth/data/notice_repository.dart';
import 'package:salesroot/features/growth/models/notice.dart';

part 'notice_providers.g.dart';

@Riverpod(keepAlive: true)
NoticeRepository noticeRepository(Ref ref) =>
    FakeNoticeRepository(ref.watch(fakeBackendProvider));

/// The notice board (#148).
@riverpod
class NoticeListNotifier extends _$NoticeListNotifier {
  @override
  Future<Paged<Notice>> build() async =>
      Paged.first(await ref.watch(noticeRepositoryProvider).list());

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(noticeRepositoryProvider)
          .list(page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Swaps in a notice that changed on its own screen.
  void patch(Notice notice) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.map((n) => n.id == notice.id ? notice : n));
  }
}

/// One notice (#150). Opening it marks it read.
@riverpod
class NoticeDetail extends _$NoticeDetail {
  @override
  Future<Notice> build(String id) async {
    final repository = ref.watch(noticeRepositoryProvider);
    final notice = await repository.get(id);
    if (notice.myState != NoticeState.unread) return notice;
    return repository.markRead(id);
  }

  Future<Notice> acknowledge() async {
    final notice = await ref.read(noticeRepositoryProvider).acknowledge(id);
    if (ref.mounted) state = AsyncData(notice);
    return notice;
  }

  Future<int> remind(List<String> memberIds) async {
    final repository = ref.read(noticeRepositoryProvider);
    final reminded = await repository.remind(id, memberIds);
    final notice = await repository.get(id);
    if (ref.mounted) state = AsyncData(notice);
    return reminded;
  }

  Future<void> delete() async {
    await ref.read(noticeRepositoryProvider).delete(id);
    if (ref.mounted) ref.invalidate(noticeListProvider);
  }
}

@riverpod
Future<Map<NoticeAudience, int>> noticeAudienceCounts(Ref ref) =>
    ref.watch(noticeRepositoryProvider).audienceCounts();

/// Publishing a notice (#149).
@riverpod
class NoticeSubmit extends _$NoticeSubmit {
  @override
  AsyncValue<Notice?> build() => const AsyncData(null);

  Future<void> submit(NoticeInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(noticeRepositoryProvider).create(input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(noticeListProvider);
  }
}
