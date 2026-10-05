import 'package:salesroot/features/support/models/guide.dart';

abstract interface class GuideRepository {
  Future<GuideStatus> status();

  /// Answers [question]; [conversationId] continues an earlier thread.
  Future<GuideAnswer> ask(String question, {String? conversationId});

  /// Records how helpful the thread was, from 1 to 5.
  Future<void> rate(String conversationId, int rating);
}
