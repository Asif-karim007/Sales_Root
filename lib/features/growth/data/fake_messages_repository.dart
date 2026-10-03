import 'dart:async';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/fake_distribution_repository.dart';
import 'package:salesroot/features/growth/data/messages_fixtures.dart';
import 'package:salesroot/features/growth/data/messages_repository.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';

class FakeMessagesRepository implements MessagesRepository {
  FakeMessagesRepository(this._backend, {Duration? replyDelay})
    : _desk = FakeDistributionDesk(_backend),
      _replyDelay =
          replyDelay ??
          (_backend.settings.latency
              ? const Duration(seconds: 3)
              : const Duration(milliseconds: 20));

  static const _window = Duration(hours: 24);

  final FakeBackend _backend;
  final FakeDistributionDesk _desk;
  final Duration _replyDelay;
  final _changes = StreamController<int>.broadcast();
  var _replyTurn = 0;

  FakeTable get _threads => _backend.table(growthThreadsTable, threadFixtures);

  FakeTable get _messages =>
      _backend.table(growthMessagesTable, messageFixtures);

  FakeTable get _templates =>
      _backend.table(growthTemplatesTable, templateFixtures);

  @override
  Future<PageResult<MessageThread>> threads(
    ThreadFilter filter, {
    int page = 1,
  }) => _backend.run('Message threads', () {
    final now = DateTime.now();
    final all = [for (final row in _threads.rows) _shape(row, now)]
      ..sort(
        (a, b) => (jsonInt(a['LastAgoSeconds']) ?? 0).compareTo(
          jsonInt(b['LastAgoSeconds']) ?? 0,
        ),
      );
    return PageResult.fromJson(
      fakePage(
        all.where((row) => _matches(filter, row)).toList(),
        page: page,
        extra: {
          'Counts': {
            for (final f in ThreadFilter.values)
              f.wire: all.where((row) => _matches(f, row)).length,
          },
        },
      ),
      MessageThread.fromJson,
    );
  }, module: AppModule.inbox);

  @override
  Future<MessagingAccount> account() => _backend.run(
    'Messaging account',
    () => const MessagingAccount(
      pageName: 'Dhaka Sales BD',
      number: '+8801711000000',
    ),
    module: AppModule.inbox,
  );

  @override
  Future<MessageThread> thread(int id) => _backend.run(
    'Message thread',
    () => MessageThread.fromJson(_shape(_threads.byId(id), DateTime.now())),
    module: AppModule.inbox,
  );

  @override
  Stream<List<ThreadMessage>> watch(int threadId) async* {
    yield await _backend.run(
      'Thread messages',
      () => _messagesOf(threadId),
      module: AppModule.inbox,
    );
    await for (final changed in _changes.stream) {
      if (changed == threadId) yield _messagesOf(threadId);
    }
  }

  @override
  Future<ThreadMessage> send(int threadId, SendMessageInput input) =>
      _backend.run(
        'Send message',
        () {
          final thread = _threads.byId(threadId);
          final body = input.toJson();
          final template = jsonInt(body['TemplateId']);
          final attachment = input.attachment;
          if (body['Text'] == null && template == null && attachment == null) {
            throw const ApiFailure(400, 'Write a message first');
          }
          final now = DateTime.now();
          final shaped = _shape(thread, now);
          if (template == null && jsonInt(shaped['WindowSecondsLeft']) == 0) {
            throw const ApiFailure(
              400,
              'The 24-hour window has closed. Send an approved template.',
            );
          }
          final saved = _messages.insert({
            'Id': _messages.nextId(),
            'ThreadId': threadId,
            'Text': body['Text'] ?? '',
            'Mine': true,
            'At': jsonUtc(now),
            'Status': DeliveryStatus.sent.wire,
            'Attachment': attachment?.toJson(),
          }, first: false);
          if (thread['AssignedToId'] == null) {
            _threads.update(threadId, {'AssignedToId': _backend.meId});
          }
          _changes.add(threadId);
          _scheduleReply(threadId, jsonInt(saved['Id']) ?? 0);
          return ThreadMessage.fromJson(saved);
        },
        module: AppModule.inbox,
        right: ModuleRight.add,
      );

  @override
  Future<MessageThread> markRead(int threadId) => _backend.run(
    'Thread read',
    () => MessageThread.fromJson(
      _shape(_threads.update(threadId, {'Unread': 0}), DateTime.now()),
    ),
    module: AppModule.inbox,
  );

  @override
  Future<MessageThread> assign(int threadId, int memberId) => _backend.run(
    'Thread assign',
    () {
      if (_desk.members.byIdOrNull(memberId) == null) {
        throw const ApiFailure(400, 'Pick a team member');
      }
      return MessageThread.fromJson(
        _shape(
          _threads.update(threadId, {'AssignedToId': memberId}),
          DateTime.now(),
        ),
      );
    },
    module: AppModule.inbox,
    right: ModuleRight.edit,
  );

  @override
  Future<List<MessageTemplate>> templates() => _backend.run(
    'Message templates',
    () => [for (final row in _templates.rows) MessageTemplate.fromJson(row)],
    module: AppModule.inbox,
  );

  @override
  Future<int> openThread({
    required String phone,
    required String name,
    ThreadChannel channel = ThreadChannel.whatsapp,
  }) => _backend.run('Open thread', () {
    for (final row in _threads.rows) {
      if (row['Phone'] == phone && row['Channel'] == channel.wire) {
        return jsonInt(row['Id']) ?? 0;
      }
    }
    final row = _threads.insert({
      'Channel': channel.wire,
      'Name': name.trim().isEmpty ? phone : name.trim(),
      'Phone': phone,
      'Kind': ThreadPartyKind.lead.wire,
      'AssignedToId': _backend.meId,
    }, first: false);
    return jsonInt(row['Id']) ?? 0;
  }, module: AppModule.inbox);

  void _scheduleReply(int threadId, int sentId) {
    Timer(_replyDelay, () {
      if (_threads.byIdOrNull(threadId) == null) return;
      if (_messages.byIdOrNull(sentId) != null) {
        _messages.update(sentId, {'Status': DeliveryStatus.read.wire});
      }
      _messages.insert({
        'Id': _messages.nextId(),
        'ThreadId': threadId,
        'Text': customerReplies[_replyTurn++ % customerReplies.length],
        'Mine': false,
        'At': jsonUtc(DateTime.now()),
        'Status': DeliveryStatus.delivered.wire,
      }, first: false);
      final unread = jsonInt(_threads.byId(threadId)['Unread']) ?? 0;
      _threads.update(threadId, {'Unread': unread + 1});
      _changes.add(threadId);
    });
  }

  List<Map<String, dynamic>> _rowsOf(int threadId) => [
    for (final row in _messages.rows)
      if (row['ThreadId'] == threadId) row,
  ]..sort((a, b) => '${a['At']}'.compareTo('${b['At']}'));

  List<ThreadMessage> _messagesOf(int threadId) => [
    for (final row in _rowsOf(threadId)) ThreadMessage.fromJson(row),
  ];

  bool _matches(ThreadFilter filter, Map<String, dynamic> row) =>
      switch (filter) {
        ThreadFilter.all => true,
        ThreadFilter.mine => row['AssignedToId'] == _backend.meId,
        ThreadFilter.unassigned => row['AssignedToId'] == null,
        ThreadFilter.whatsapp => row['Channel'] == ThreadChannel.whatsapp.wire,
        ThreadFilter.messenger =>
          row['Channel'] == ThreadChannel.messenger.wire,
        ThreadFilter.sms => row['Channel'] == ThreadChannel.sms.wire,
      };

  Map<String, dynamic> _shape(Map<String, dynamic> row, DateTime now) {
    final messages = _rowsOf(jsonInt(row['Id']) ?? 0);
    final last = messages.isEmpty ? null : messages.last;
    final lastAt = jsonDate(last?['At']);
    final lastCustomer = jsonDate(
      messages.lastWhere((m) => m['Mine'] != true, orElse: () => {})['At'],
    );
    final attachment = last?['Attachment'];
    final windowLeft = lastCustomer == null
        ? Duration.zero
        : _window - now.difference(lastCustomer);
    return {
      ...row,
      'LastMessage': attachment is Map
          ? '${attachment['Name']}'
          : last?['Text'],
      'LastMine': last?['Mine'] == true,
      'LastAgoSeconds': lastAt == null ? 0 : now.difference(lastAt).inSeconds,
      if (row['Channel'] == ThreadChannel.whatsapp.wire)
        'WindowSecondsLeft': windowLeft.isNegative ? 0 : windowLeft.inSeconds,
      'AssignedToMe': row['AssignedToId'] == _backend.meId,
      ..._desk.memberFields(jsonInt(row['AssignedToId']), 'AssignedTo'),
    };
  }
}
