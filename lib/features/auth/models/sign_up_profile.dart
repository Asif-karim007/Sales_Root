import 'package:salesroot/core/access/experience_level.dart';

enum WorkStyle {
  solo(ExperienceLevel.easy),
  team(ExperienceLevel.standard),
  joining(ExperienceLevel.easy);

  const WorkStyle(this.startingLevel);

  final ExperienceLevel startingLevel;
}

enum IndustryTemplate {
  trading('distribution'),
  realEstate('real_estate'),
  education('education'),
  itServices('it_services'),
  manufacturing('general'),
  general('general');

  const IndustryTemplate(this.wire);

  /// The server's industry pack.
  final String wire;
}

class SignUpProfile {
  const SignUpProfile({required this.name, required this.workStyle});

  final String name;
  final WorkStyle workStyle;

  Map<String, dynamic> toJson() => {'name': name.trim()};
}
