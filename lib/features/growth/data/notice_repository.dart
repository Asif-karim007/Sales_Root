import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/notice.dart';

/// The team notice board. Recipients come back only to people who may see
/// who has read a notice: its author and anyone who can edit notices.
abstract interface class NoticeRepository {
  /// Pinned first, then newest first.
  Future<PageResult<Notice>> list({int page = 1});

  Future<Notice> get(int id);

  Future<Notice> markRead(int id);

  Future<Notice> acknowledge(int id);

  /// Nudges [memberIds] again; returns how many were reminded.
  Future<int> remind(int id, List<int> memberIds);

  Future<Notice> create(NoticeInput input);

  Future<void> delete(int id);

  Future<Map<NoticeAudience, int>> audienceCounts();
}
