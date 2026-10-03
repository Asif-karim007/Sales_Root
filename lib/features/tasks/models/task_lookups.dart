import 'package:salesroot/core/utils/json_fields.dart';

/// A lead a task can be linked to.
class LeadOption {
  const LeadOption({
    required this.id,
    required this.title,
    this.companyName,
    this.contactName,
    this.ownerId,
  });

  final int id;
  final String title;
  final String? companyName;
  final String? contactName;
  final int? ownerId;

  /// The name to put in a task title: the company when there is one.
  String get shortName => companyName ?? title;

  factory LeadOption.fromJson(Map<String, dynamic> json) => LeadOption(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    companyName: json['CompanyName'] as String?,
    contactName: json['ContactName'] as String?,
    ownerId: jsonInt(json['OwnerId']),
  );
}

/// A teammate a task can be assigned to.
class MemberOption {
  const MemberOption({
    required this.id,
    required this.name,
    this.designation,
    this.isMe = false,
  });

  final int id;
  final LocalizedName name;
  final String? designation;
  final bool isMe;

  factory MemberOption.fromJson(Map<String, dynamic> json) => MemberOption(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    designation: json['Designation'] as String?,
    isMe: jsonBool(json['IsMe']),
  );
}
