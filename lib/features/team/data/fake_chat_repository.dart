import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/role_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/data/chat_fixtures.dart';
import 'package:salesroot/features/team/data/chat_repository.dart';
import 'package:salesroot/features/team/data/fake_file_bytes.dart';
import 'package:salesroot/features/team/data/fake_page.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/member.dart';

/// Chat on the fake server, as there is no chat endpoint yet. After you send,
/// a teammate reads it, types and replies a few seconds later, so the live
/// screen has something to show. Rows keep int ids; the models get them as
/// strings.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository(
    this._backend, {
    this.deliveredAfter = const Duration(milliseconds: 700),
    this.typingAfter = const Duration(milliseconds: 1800),
    this.replyAfter = const Duration(milliseconds: 4200),
  });

  final FakeBackend _backend;
  final Duration deliveredAfter;
  final Duration typingAfter;
  final Duration replyAfter;

  final _events = StreamController<ChatEvent>.broadcast();
  final _changes = StreamController<void>.broadcast();
  final _pending = <int, List<Timer>>{};

  static int _key(String id) => int.tryParse(id) ?? -1;

  FakeTable get _threads => _backend.table('chat/threads', chatThreadFixtures);
  FakeTable get _messages =>
      _backend.table('chat/messages', chatMessageFixtures);
  SeedGraph get _graph => _backend.graph;
  int get _me => _backend.meId;

  void dispose() {
    for (final timers in _pending.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _pending.clear();
    _events.close();
    _changes.close();
  }

  @override
  Stream<ChatEvent> events(String threadId) =>
      _events.stream.where((event) => event.threadId == threadId);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<PageResult<ChatThread>> threads(ChatQuery query) => _backend.run(
    'Chat threads',
    () => _page(
      _threads.rows.where((t) => _people(t).contains(_me)).toList(),
      query,
    ),
    module: AppModule.chat,
  );

  @override
  Future<PageResult<ChatThread>> oversight(ChatQuery query) => _backend.run(
    'Chat oversight',
    () => _page(_threads.rows, query),
    module: AppModule.chatOversight,
  );

  @override
  Future<ChatThread> thread(String id) => _backend.run('Chat thread', () {
    final row = _readable(_key(id));
    return ChatThread.fromJson(_present(row));
  }, module: AppModule.chat);

  @override
  Future<ChatThread> leadThread(String id) => _backend.run(
    'Chat lead thread',
    () {
      final leadId = _key(id);
      final lead = _graph.leads.firstWhereOrNull((l) => l.id == leadId);
      if (lead == null) throw const ApiFailure(404, 'Lead not found');
      final existing = _threads.rows.firstWhereOrNull(
        (t) => t['Kind'] == ChatKind.lead.wire && t['LeadId'] == leadId,
      );
      if (existing != null) {
        final people = _people(existing);
        if (!people.contains(_me)) {
          _threads.update(existing['Id'] as int, {
            'ParticipantIds': [...people, _me],
          });
        }
        return ChatThread.fromJson(_present(existing));
      }
      final owner = _graph.members.firstWhereOrNull(
        (m) => m.id == lead.ownerId,
      );
      final row = _create(
        kind: ChatKind.lead,
        people: {
          _me,
          lead.ownerId,
          if (owner != null) ?managerIdOf(_graph, owner),
        },
        extra: {'LeadId': leadId},
      );
      return ChatThread.fromJson(_present(row));
    },
    module: AppModule.chat,
    right: ModuleRight.add,
  );

  @override
  Future<List<Member>> people() => _backend.run(
    'Chat people',
    () => [
      for (final member in _graph.members)
        Member.fromJson({
          'id': member.id,
          'name': member.name,
          'phone': member.phone,
          'role': member.role.wire,
          'designation': member.designation,
        }).copyWith(isMe: member.id == _me),
    ],
    module: AppModule.chat,
  );

  @override
  Future<ChatThread> direct(String id) => _backend.run(
    'Chat direct',
    () {
      final memberId = _key(id);
      if (memberId == _me) {
        throw const ApiFailure(400, "You can't start a chat with yourself");
      }
      if (!_graph.members.any((m) => m.id == memberId)) {
        throw const ApiFailure(404, 'Member not found');
      }
      final pair = {_me, memberId};
      final existing = _threads.rows.firstWhereOrNull(
        (t) =>
            t['Kind'] == ChatKind.direct.wire &&
            const SetEquality<int>().equals(_people(t).toSet(), pair),
      );
      final row = existing ?? _create(kind: ChatKind.direct, people: pair);
      return ChatThread.fromJson(_present(row));
    },
    module: AppModule.chat,
    right: ModuleRight.add,
  );

  @override
  Future<ChatThread> createGroup(String name, List<String> memberIds) =>
      _backend.run(
        'Chat group create',
        () {
          fakeRequire({'Name': name}, ['Name']);
          final people = memberIds
              .map(_key)
              .where((id) => id != _me && _graph.members.any((m) => m.id == id))
              .toSet();
          if (people.isEmpty) {
            throw const ApiFailure(
              400,
              'Add at least one member',
              fieldErrors: {'MemberIds': 'Add at least one member'},
            );
          }
          final row = _create(
            kind: ChatKind.group,
            people: {_me, ...people},
            extra: {'Title': name.trim(), 'AdminId': _me},
          );
          return ChatThread.fromJson(_present(row));
        },
        module: AppModule.chat,
        right: ModuleRight.add,
      );

  @override
  Future<ChatThread> updateSettings(
    String threadId, {
    bool? notifications,
    bool? autoDownload,
  }) => _backend.run('Chat settings', () {
    final row = _joined(_key(threadId));
    _threads.update(row['Id'] as int, {
      'Notifications': ?notifications,
      'AutoDownload': ?autoDownload,
    });
    return ChatThread.fromJson(_present(row));
  }, module: AppModule.chat);

  @override
  Future<ChatThread> addMembers(String id, List<String> memberIds) =>
      _backend.run(
        'Chat add members',
        () {
          final threadId = _key(id);
          final row = _joined(threadId);
          if (_present(row)['CanAddMembers'] != true) {
            throw const ApiFailure(403, 'Only the group admin can add people');
          }
          final people = {
            ..._people(row),
            ...memberIds
                .map(_key)
                .where((id) => _graph.members.any((m) => m.id == id)),
          };
          _threads.update(threadId, {'ParticipantIds': people.toList()});
          _changed();
          return ChatThread.fromJson(_present(row));
        },
        module: AppModule.chat,
        right: ModuleRight.add,
      );

  @override
  Future<void> leave(String id) => _backend.run('Chat leave', () {
    final threadId = _key(id);
    final row = _joined(threadId);
    if (_present(row)['CanLeave'] != true) {
      throw const ApiFailure(400, "You can't leave this chat");
    }
    _threads.update(threadId, {
      'ParticipantIds': _people(row).where((id) => id != _me).toList(),
    });
    _changed();
  }, module: AppModule.chat);

  @override
  Future<PageResult<ChatMessage>> messages(String id, {int? beforeId}) =>
      _backend.run('Chat messages', () {
        final threadId = _key(id);
        _readable(threadId);
        final older = _messages.rows
            .where(
              (m) =>
                  m['ThreadId'] == threadId &&
                  (beforeId == null || (m['Id'] as int) < beforeId),
            )
            .sorted((a, b) => (b['Id'] as int).compareTo(a['Id'] as int));
        final page = serverPage([for (final m in older) _message(m)], page: 1);
        return PageResult.fromJson(page, ChatMessage.fromJson);
      }, module: AppModule.chat);

  @override
  Future<ChatMessage> send(String id, MessageInput input) => _backend.run(
    'Chat send',
    () {
      final threadId = _key(id);
      final thread = _joined(threadId);
      final body = input.toJson();
      if ((body['Text'] as String).isEmpty && body['Attachment'] == null) {
        throw const ApiFailure(
          400,
          'Write a message',
          fieldErrors: {'Text': 'Write a message'},
        );
      }
      final row = _messages.insert({
        ...body,
        'Id': _messages.nextId(),
        'ThreadId': threadId,
        'SenderId': _me,
        'SentAt': jsonUtc(DateTime.now()),
        'Status': MessageStatus.sent.wire,
      }, first: false);
      final messageId = row['Id'] as int;
      _threads.update(threadId, {'LastReadId': messageId});
      final message = ChatMessage.fromJson(_message(row));
      _emit(MessageAdded(id, message));
      _simulateReply(thread, messageId);
      return message;
    },
    module: AppModule.chat,
    right: ModuleRight.add,
    quota: (input.attachment?.kind.usesStorage ?? false)
        ? QuotaKind.storage
        : null,
  );

  @override
  Future<void> markRead(String id) => _backend.run('Chat read', () {
    final threadId = _key(id);
    final row = _threads.byId(threadId);
    if (!_people(row).contains(_me)) return;
    final last = _messages.rows
        .where((m) => m['ThreadId'] == threadId)
        .fold<int>(0, (top, m) => max(top, m['Id'] as int));
    if ((row['LastReadId'] as int? ?? 0) >= last) return;
    _threads.update(threadId, {'LastReadId': last});
    _changed();
  }, module: AppModule.chat);

  @override
  Future<Uint8List> attachmentBytes(int messageId) =>
      _backend.run('Chat attachment', () async {
        final row = _messages.byId(messageId);
        _readable(row['ThreadId'] as int);
        final attachment = jsonObject(row['Attachment'], Attachment.fromJson);
        if (attachment == null) throw const ApiFailure(404, 'No attachment');
        return await localFileBytes(attachment.localPath) ??
            await fakeFileBytes(attachment.title, _graph);
      }, module: AppModule.chat);

  @override
  Future<PageResult<ChatRef>> attachables(
    AttachmentKind kind,
    String term,
    int page,
  ) => _backend.run('Chat attachables', () {
    final rows = switch (kind) {
      AttachmentKind.lead => [
        for (final lead in _graph.leads)
          {
            'Id': lead.id,
            'Title': lead.title,
            'Subtitle': _graph.contact(lead.contactId).name,
            'LeadId': lead.id,
            'Amount': lead.value,
          },
      ],
      AttachmentKind.quotation => [
        for (final lead in _graph.leads.where((l) => l.stageId >= 4))
          {
            'Id': lead.id,
            'Title': 'Q-${lead.id.toString().padLeft(4, '0')}',
            'Subtitle': lead.title,
            'LeadId': lead.id,
            'Amount': lead.value,
          },
      ],
      AttachmentKind.contact => [
        for (final contact in _graph.contacts)
          {
            'Id': contact.id,
            'Title': contact.name,
            'Subtitle':
                '${contact.designation} · ${_graph.company(contact.companyId).name}',
          },
      ],
      _ => const <Map<String, dynamic>>[],
    };
    final matches = rows
        .where((row) => fakeMatches(row, term, ['Title', 'Subtitle']))
        .toList();
    return PageResult.fromJson(
      serverPage(matches, page: page),
      ChatRef.fromJson,
    );
  }, module: AppModule.chat);

  List<int> _people(Map<String, dynamic> thread) =>
      jsonInts(thread['ParticipantIds']);

  /// A thread the user may read: one they are in, or any with oversight.
  Map<String, dynamic> _readable(int id) {
    final row = _threads.byId(id);
    final oversees = roleGrant(_backend.role, AppModule.chatOversight).canView;
    if (!_people(row).contains(_me) && !oversees) {
      throw const ApiFailure(403, 'You are not in this chat');
    }
    return row;
  }

  /// A thread the user is in, so they may write to it.
  Map<String, dynamic> _joined(int id) {
    final row = _threads.byId(id);
    if (!_people(row).contains(_me)) {
      throw const ApiFailure(403, 'Only members of this chat can do that');
    }
    return row;
  }

  Map<String, dynamic> _create({
    required ChatKind kind,
    required Set<int> people,
    Map<String, dynamic> extra = const {},
  }) {
    final row = _threads.insert({
      'Id': _threads.nextId(),
      'Kind': kind.wire,
      'Title': '',
      'IsEveryone': false,
      'ParticipantIds': people.toList(),
      'CreatedAt': jsonUtc(DateTime.now()),
      'Notifications': true,
      'AutoDownload': false,
      'LastReadId': 0,
      ...extra,
    });
    _changed();
    return row;
  }

  PageResult<ChatThread> _page(
    List<Map<String, dynamic>> rows,
    ChatQuery query,
  ) {
    final presented = [for (final row in rows) _present(row)];
    final matching = presented.where((t) => _matches(t, query.search)).toList();
    final scoped = query.scope == ChatScope.all
        ? matching
        : matching.where((t) => t['Kind'] == query.scope.wire).toList();
    scoped.sort(
      (a, b) => '${b['LastActivityAt']}'.compareTo('${a['LastActivityAt']}'),
    );
    int count(ChatKind kind) =>
        matching.where((t) => t['Kind'] == kind.wire).length;
    return PageResult.fromJson(
      serverPage(
        scoped,
        page: query.page,
        extra: {
          'KindCounts': {
            ChatScope.all.wire: matching.length,
            ChatScope.group.wire: count(ChatKind.group),
            ChatScope.direct.wire: count(ChatKind.direct),
            ChatScope.lead.wire: count(ChatKind.lead),
          },
        },
      ),
      ChatThread.fromJson,
    );
  }

  bool _matches(Map<String, dynamic> thread, String search) {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return true;
    final names = [
      thread['Title'],
      (thread['Lead'] as Map?)?['Title'],
      for (final p in thread['Participants'] as List)
        if (p is Map) ...[p['Name'], p['NameBn']],
    ];
    return names.any((n) => '${n ?? ''}'.toLowerCase().contains(q));
  }

  /// What the server adds on read: people, lead card, last message, unread
  /// count and the caller's rights.
  Map<String, dynamic> _present(Map<String, dynamic> row) {
    final id = row['Id'] as int;
    final people = _people(row);
    final joined = people.contains(_me);
    final messages = _messages.rows.where((m) => m['ThreadId'] == id).toList();
    final last = messages.isEmpty ? null : messages.last;
    final lastRead = row['LastReadId'] as int? ?? 0;
    final now = DateTime.now();
    final group =
        row['Kind'] == ChatKind.group.wire && row['IsEveryone'] != true;
    final leadId = jsonInt(row['LeadId']);
    return {
      ...row,
      'Participants': [for (final person in people) _person(person)],
      'Lead': leadId == null ? null : _lead(leadId),
      'LastMessage': last == null ? null : _preview(last),
      'UnreadCount': joined
          ? messages
                .where(
                  (m) => (m['Id'] as int) > lastRead && m['SenderId'] != _me,
                )
                .length
          : 0,
      'MessagesToday': messages.where((m) {
        final at = jsonDate(m['SentAt']);
        return at != null && AppDateUtils.isSameDay(at, now);
      }).length,
      'LastActivityAt': last?['SentAt'] ?? row['CreatedAt'],
      'IsParticipant': joined,
      'CanLeave': group && joined,
      'CanAddMembers':
          group &&
          joined &&
          (row['AdminId'] == _me ||
              roleGrant(_backend.role, AppModule.team).canEdit),
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _person(int id) {
    final member = _graph.members.firstWhereOrNull((m) => m.id == id);
    return {
      'Id': id,
      'Name': member?.name ?? '',
      'NameBn': member?.nameBn ?? '',
      'Role': member?.role.wire,
      'IsMe': id == _me,
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _lead(int id) {
    final lead = _graph.lead(id);
    final stage = SeedGraph.stages.firstWhere((s) => s.$1 == lead.stageId);
    final owner = _graph.members.firstWhereOrNull((m) => m.id == lead.ownerId);
    return {
      'Id': lead.id,
      'Title': lead.title,
      'CompanyId': lead.companyId,
      'Stage': stage.$2,
      'StageBn': stage.$3,
      'Value': lead.value,
      'OwnerName': owner?.name,
      'OwnerNameBn': owner?.nameBn,
      'ContactPhone': _graph.contact(lead.contactId).phone,
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _preview(Map<String, dynamic> message) {
    final sender = _person(message['SenderId'] as int);
    return {
      'Text': message['Text'],
      'SenderId': message['SenderId'],
      'SenderName': sender['Name'],
      'SenderNameBn': sender['NameBn'],
      'SentAt': message['SentAt'],
      'IsMine': message['SenderId'] == _me,
      'AttachmentKind': (message['Attachment'] as Map?)?['Kind'],
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _message(Map<String, dynamic> row) {
    final sender = _person(row['SenderId'] as int);
    return {
      ...row,
      'SenderName': sender['Name'],
      'SenderNameBn': sender['NameBn'],
      'IsMine': row['SenderId'] == _me,
    };
  }

  void _emit(ChatEvent event) {
    if (_events.isClosed) return;
    _events.add(event);
    if (event is MessageAdded) _changed();
  }

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void _simulateReply(Map<String, dynamic> thread, int messageId) {
    final threadId = thread['Id'] as int;
    final others = _people(thread).where((id) => id != _me).toList();
    if (others.isEmpty) return;
    for (final timer in _pending.remove(threadId) ?? const <Timer>[]) {
      timer.cancel();
    }
    final random = Random(messageId);
    final responderId = others[random.nextInt(others.length)];
    final responder = ChatPerson.fromJson(_person(responderId));
    final key = '$threadId';
    _pending[threadId] = [
      Timer(deliveredAfter, () {
        _markMine(threadId, messageId, MessageStatus.delivered);
      }),
      Timer(typingAfter, () {
        _markMine(threadId, messageId, MessageStatus.read);
        _emit(TypingChanged(key, responder, typing: true));
      }),
      Timer(replyAfter, () {
        _pending.remove(threadId);
        _emit(TypingChanged(key, responder, typing: false));
        final reply = _messages.insert({
          'Id': _messages.nextId(),
          'ThreadId': threadId,
          'SenderId': responderId,
          'Text': chatReplies[random.nextInt(chatReplies.length)],
          'SentAt': jsonUtc(DateTime.now()),
          'Status': MessageStatus.sent.wire,
        }, first: false);
        _emit(MessageAdded(key, ChatMessage.fromJson(_message(reply))));
      }),
    ];
  }

  void _markMine(int threadId, int upToId, MessageStatus status) {
    for (final row in _messages.rows) {
      final mine = row['ThreadId'] == threadId && row['SenderId'] == _me;
      final behind =
          MessageStatus.fromWire(row['Status'] as String?).index < status.index;
      if (mine && behind && (row['Id'] as int) <= upToId) {
        _messages.update(row['Id'] as int, {'Status': status.wire});
      }
    }
    _emit(MessagesStatusChanged('$threadId', upToId, status));
  }
}
