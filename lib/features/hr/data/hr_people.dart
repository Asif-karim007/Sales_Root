import 'package:salesroot/core/fake/seed_graph.dart';

/// The member with [id], or null when the workspace has no such member.
SeedMember? memberOrNull(SeedGraph graph, int? id) =>
    graph.members.where((m) => m.id == id).firstOrNull;

/// Who approves [employeeId]'s requests: their manager, or null for the
/// person at the top.
SeedMember? approverOf(SeedGraph graph, int employeeId) =>
    memberOrNull(graph, memberOrNull(graph, employeeId)?.managerId);

/// The owner, who approves a second time above the expense limit.
SeedMember? ownerOf(SeedGraph graph) =>
    graph.members.where((m) => m.managerId == null).firstOrNull;

/// `{<key>: name, <key>Bn: nameBn}` for [member], or nothing.
Map<String, dynamic> personFields(String key, SeedMember? member) =>
    member == null ? const {} : {key: member.name, '${key}Bn': member.nameBn};
