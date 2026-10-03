import 'package:salesroot/features/support/models/guide.dart';

abstract interface class GuideRepository {
  Future<GuideAnswer> ask(GuideQuestion question);
}
