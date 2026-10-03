import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';

/// [current] with the next page appended, or marked failed so the list can
/// offer a retry at its end.
Future<Paged<T>> loadPageAfter<T>(
  Paged<T> current,
  Future<PageResult<T>> Function(int page) fetch,
) async {
  try {
    return current.append(await fetch(current.page + 1));
  } on ApiFailure catch (failure) {
    return current.failedMore(failure);
  }
}
