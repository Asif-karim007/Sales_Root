import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const rafi = '01a10101-8656-7886-b8e5-4f197fbd9159';
const bushra = '01a10101-8656-7ec4-8e2a-2f921b517ab4';
const rumpa = '01a10101-8654-7500-9b5b-0704cbb7d210';
const nadia = '01a10101-8650-7db1-9e3f-2a05bc0d3f10';
const tanvir = '01a10101-8659-7000-a000-00000000aaaa';

/// The recorded members, plus Tanvir invited by Rumpa when [withInvite].
List<Map<String, dynamic>> membersWith({bool withInvite = false}) {
  final rows = [
    for (final row in fixture('team_members') as List)
      Map<String, dynamic>.of(row as Map<String, dynamic>),
  ];
  if (!withInvite) return rows;
  return [
    ...rows,
    {
      ...rows.first,
      'id': tanvir,
      'userId': null,
      'name': null,
      'phone': '+8801912999888',
      'status': 'invited',
      'reportsTo': rumpa,
      'joinedAt': null,
      'inviteExpiresAt': '2026-10-12T09:00:00Z',
    },
  ];
}

/// The API as Rafi's workspace answers it: members, Rafi checked in today,
/// this month's targets and his open lead and overdue task totals.
ApiStub teamStub({bool withInvite = false}) {
  final attendance = fixture('team_attendance') as List;
  return ApiStub()
    ..on('GET', 'workspaces/members', membersWith(withInvite: withInvite))
    ..on('GET', 'attendance', [
      {
        ...attendance.first as Map<String, dynamic>,
        'checkInAt': '2026-10-05T03:10:00Z',
      },
    ])
    ..on('GET', 'targets', fixture('team_targets'))
    ..on('GET', 'leads', fixture('team_open_leads'))
    ..on('GET', 'tasks', fixture('team_overdue_tasks'))
    ..on('GET', 'billing/catalogue', fixture('team_catalogue'));
}

/// A signed-in container over [stub] in Rafi's workspace as [role], with the
/// workspace loaded and fake latency off for chat and files.
Future<ProviderContainer> teamContainer({
  ApiStub? stub,
  String role = 'owner',
  List<Override> overrides = const [],
}) async {
  final container = await apiContainer(
    stub ?? ApiStub(),
    me: meWith(role: role),
    overrides: overrides,
  );
  setDev(container, (s) => s.copyWith(latency: false));
  await container.read(workspacesProvider.future);
  return container;
}

/// Turns a dev-menu switch on, as the developer menu does.
void setDev(
  ProviderContainer container,
  DevSettings Function(DevSettings settings) change,
) => container.read(devSettingsProvider.notifier).update(change);
