import 'package:salesroot/core/utils/json_fields.dart';

/// A lead a task can be linked to.
class LeadOption {
  const LeadOption({
    required this.id,
    required this.title,
    this.companyName,
    this.contactName,
  });

  final String id;
  final String title;
  final String? companyName;
  final String? contactName;

  /// The name to put in a task title: the company when there is one.
  String get shortName => companyName ?? contactName ?? title;

  factory LeadOption.fromJson(Map<String, dynamic> json) => LeadOption(
    id: jsonId(json['id']) ?? '',
    title: json['title'] as String? ?? '',
    companyName: json['companyName'] as String?,
    contactName: json['contactName'] as String? ?? json['name'] as String?,
  );
}

/// A teammate a task can be assigned to. [id] is the membership id.
class MemberOption {
  const MemberOption({
    required this.id,
    required this.name,
    this.userId,
    this.designation,
    this.isMe = false,
  });

  final String id;
  final LocalizedName name;
  final String? userId;
  final String? designation;
  final bool isMe;

  /// [me] is the user's membership id.
  factory MemberOption.fromJson(Map<String, dynamic> json, {String? me}) {
    final id = jsonId(json['id']) ?? '';
    return MemberOption(
      id: id,
      name: LocalizedName.pair(json),
      userId: jsonId(json['userId']),
      designation: json['designation'] as String?,
      isMe: me != null && id == me,
    );
  }
}
