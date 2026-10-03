import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/localized.dart';

enum LessonCategory {
  coldCalling('ColdCalling'),
  closing('Closing'),
  followUp('FollowUp'),
  career('Career');

  const LessonCategory(this.wire);

  final String wire;

  static LessonCategory fromWire(String? value) => values.firstWhere(
    (category) => category.wire == value,
    orElse: () => LessonCategory.closing,
  );
}

/// Why the academy recommends a lesson.
enum LessonReason {
  lostLeads('LostLeads'),
  quotationsSent('QuotationsSent'),
  continueLesson('Continue');

  const LessonReason(this.wire);

  final String wire;

  static LessonReason? fromWire(String? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

class LessonQuiz {
  const LessonQuiz({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final LocalizedName question;
  final List<LocalizedName> options;
  final int correctIndex;
  final LocalizedName explanation;

  factory LessonQuiz.fromJson(Map<String, dynamic> json) => LessonQuiz(
    question: localizedField(json, 'Question'),
    options: localizedList(json['Options'], 'Text'),
    correctIndex: jsonInt(json['CorrectIndex']) ?? 0,
    explanation: localizedField(json, 'Explanation'),
  );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.minutes,
    this.body = const [],
    this.points = const [],
    this.videoSeconds,
    this.progress = 0,
    this.isNew = false,
    this.quiz,
    this.action,
    this.actionLabel,
    this.careerStep,
    this.reason,
    this.reasonCount = 0,
  });

  final int id;
  final LessonCategory category;
  final LocalizedName title;
  final LocalizedName summary;
  final int minutes;
  final List<LocalizedName> body;
  final List<LocalizedName> points;
  final int? videoSeconds;

  /// 0–100.
  final int progress;
  final bool isNew;
  final LessonQuiz? quiz;
  final AppDestination? action;
  final LocalizedName? actionLabel;

  /// The step number when the lesson is part of the career path.
  final int? careerStep;
  final LessonReason? reason;
  final int reasonCount;

  bool get isDone => progress >= 100;
  bool get isStarted => progress > 0 && !isDone;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final actionLabel = localizedField(json, 'ActionLabel');
    return Lesson(
      id: jsonInt(json['Id']) ?? 0,
      category: LessonCategory.fromWire(json['Category'] as String?),
      title: localizedField(json, 'Title'),
      summary: localizedField(json, 'Summary'),
      minutes: jsonInt(json['Minutes']) ?? 1,
      body: localizedList(json['Body'], 'Text'),
      points: localizedList(json['Points'], 'Text'),
      videoSeconds: jsonInt(json['VideoSeconds']),
      progress: (jsonInt(json['Progress']) ?? 0).clamp(0, 100),
      isNew: jsonBool(json['IsNew']),
      quiz: jsonObject(json['Quiz'], LessonQuiz.fromJson),
      action: AppDestination.fromWire(json['Action'] as String?),
      actionLabel: actionLabel.en.isEmpty ? null : actionLabel,
      careerStep: jsonInt(json['CareerStep']),
      reason: LessonReason.fromWire(json['Reason'] as String?),
      reasonCount: jsonInt(json['ReasonCount']) ?? 0,
    );
  }
}

enum CareerStepStatus { done, current, locked }

class CareerStep {
  const CareerStep({
    required this.index,
    required this.lessonId,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final int index;
  final int lessonId;
  final LocalizedName title;
  final LocalizedName subtitle;
  final CareerStepStatus status;

  factory CareerStep.fromJson(Map<String, dynamic> json) => CareerStep(
    index: jsonInt(json['Index']) ?? 0,
    lessonId: jsonInt(json['LessonId']) ?? 0,
    title: localizedField(json, 'Title'),
    subtitle: localizedField(json, 'Subtitle'),
    status: switch (json['Status']) {
      'Done' => CareerStepStatus.done,
      'Current' => CareerStepStatus.current,
      _ => CareerStepStatus.locked,
    },
  );
}

class CareerPath {
  const CareerPath({
    required this.title,
    required this.done,
    required this.total,
    this.calls = 0,
    this.visits = 0,
    this.wins = 0,
    this.steps = const [],
  });

  final LocalizedName title;
  final int done;
  final int total;
  final int calls;
  final int visits;
  final int wins;
  final List<CareerStep> steps;

  double get ratio => total == 0 ? 0 : done / total;

  factory CareerPath.fromJson(Map<String, dynamic> json) => CareerPath(
    title: localizedField(json, 'Title'),
    done: jsonInt(json['Done']) ?? 0,
    total: jsonInt(json['Total']) ?? 0,
    calls: jsonInt(json['Calls']) ?? 0,
    visits: jsonInt(json['Visits']) ?? 0,
    wins: jsonInt(json['Wins']) ?? 0,
    steps: jsonList(json['Steps'], CareerStep.fromJson),
  );
}

class AcademyHome {
  const AcademyHome({
    required this.tip,
    required this.forYou,
    required this.career,
  });

  final Lesson? tip;
  final List<Lesson> forYou;
  final CareerPath career;

  factory AcademyHome.fromJson(Map<String, dynamic> json) => AcademyHome(
    tip: jsonObject(json['Tip'], Lesson.fromJson),
    forYou: jsonList(json['ForYou'], Lesson.fromJson),
    career:
        jsonObject(json['Career'], CareerPath.fromJson) ??
        const CareerPath(title: LocalizedName('', ''), done: 0, total: 0),
  );
}
