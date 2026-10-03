import 'package:salesroot/core/access/experience_level.dart';

enum WorkStyle {
  solo('Solo', ExperienceLevel.easy),
  team('Team', ExperienceLevel.standard),
  joining('Joining', ExperienceLevel.easy);

  const WorkStyle(this.wire, this.startingLevel);

  final String wire;
  final ExperienceLevel startingLevel;
}

enum IndustryTemplate {
  trading('Trading'),
  realEstate('RealEstate'),
  education('Education'),
  itServices('ItServices'),
  manufacturing('Manufacturing'),
  general('General');

  const IndustryTemplate(this.wire);

  final String wire;
}

class SignUpProfile {
  const SignUpProfile({required this.name, required this.workStyle});

  final String name;
  final WorkStyle workStyle;

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'WorkStyle': workStyle.wire,
  };
}
