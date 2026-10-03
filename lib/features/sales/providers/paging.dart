import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';

/// Appends the next page to [current], marking it loading first and keeping
/// a failure on the list so the screen can offer a retry at the bottom.
Future<void> loadNextPage<T>({
  required Paged<T>? current,
  required Future<PageResult<T>> Function(int page) fetch,
  required bool Function() mounted,
  required void Function(Paged<T> next) emit,
}) async {
  if (current == null || !current.hasMore || current.isLoadingMore) return;
  emit(current.loadingMore());
  try {
    final next = await fetch(current.page + 1);
    if (!mounted()) return;
    emit(current.append(next));
  } on ApiFailure catch (failure) {
    if (!mounted()) return;
    emit(current.failedMore(failure));
  }
}
