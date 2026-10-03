import 'dart:async';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/support_fixtures.dart';
import 'package:salesroot/features/support/data/support_repository.dart';
import 'package:salesroot/features/support/models/localized.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository(this._backend, {required this.agentDelay});

  final FakeBackend _backend;

  /// How long the fake agent takes to answer.
  final Duration agentDelay;

  final StreamController<int> _changes = StreamController<int>.broadcast();
  final List<Timer> _timers = [];

  FakeTable get _tickets => _backend.table('support/tickets', ticketFixtures);
  FakeTable get _feedback => _backend.table('support/feedback', (_) => []);
  FakeTable get _surveys => _backend.table('support/surveys', (_) => []);
  FakeTable get _enquiries => _backend.table('support/enquiries', (_) => []);

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _changes.close();
  }

  @override
  Stream<int> get ticketChanges => _changes.stream;

  @override
  Future<PageResult<SupportTicket>> tickets({int page = 1}) =>
      _backend.run('Support tickets', () {
        final rows = [..._tickets.rows]
          ..sort((a, b) => '${b['UpdatedAt']}'.compareTo('${a['UpdatedAt']}'));
        return PageResult.fromJson(
          fakePage(rows, page: page),
          SupportTicket.fromJson,
        );
      }, module: AppModule.support);

  @override
  Future<SupportTicket> ticket(int id) => _backend.run(
    'Support ticket $id',
    () => SupportTicket.fromJson(_tickets.byId(id)),
    module: AppModule.support,
  );

  @override
  Future<SupportTicket> createTicket(TicketInput input) => _backend.run(
    'Support ticket create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Category', 'Description']);
      final description = body['Description'] as String;
      if (description.length < 10) {
        throw const ApiFailure(
          400,
          'Please describe the problem in a few more words.',
          fieldErrors: {
            'Description': 'Please describe the problem in a few more words.',
          },
        );
      }
      final now = DateTime.now();
      final row = _tickets.insert({
        'Number': 'SR-${_nextNumber()}',
        'Subject': _subjectOf(description),
        'Category': body['Category'],
        'Status': TicketStatus.open.wire,
        'ReplyWithinHours': input.category == TicketCategory.billing ? 4 : 8,
        'ReplyChannel': body['ReplyChannel'],
        'Diagnostics': ?body['Diagnostics'],
        'UpdatedAt': jsonUtc(now),
        'Messages': [_mine(1, description, now, body['Attachments'] as List)],
      });
      final id = row['Id'] as int;
      _scheduleAgent(id);
      return SupportTicket.fromJson(row);
    },
    module: AppModule.support,
    right: ModuleRight.add,
  );

  @override
  Future<SupportTicket> reply(
    int ticketId,
    String text, {
    List<SupportAttachment> attachments = const [],
  }) => _backend.run(
    'Support ticket reply $ticketId',
    () {
      final row = _tickets.byId(ticketId);
      if (text.trim().isEmpty && attachments.isEmpty) {
        throw const ApiFailure(400, 'Write a reply first.');
      }
      final messages = [...row['Messages'] as List];
      final now = DateTime.now();
      messages.add(
        _mine(messages.length + 1, text.trim(), now, [
          for (final a in attachments) a.toJson(),
        ]),
      );
      _tickets.update(ticketId, {
        'Messages': messages,
        'Status': TicketStatus.open.wire,
        'UpdatedAt': jsonUtc(now),
      });
      _scheduleAgent(ticketId);
      return SupportTicket.fromJson(_tickets.byId(ticketId));
    },
    module: AppModule.support,
    right: ModuleRight.add,
  );

  @override
  Future<SupportTicket> resolve(int ticketId) => _backend.run(
    'Support ticket resolve $ticketId',
    () => SupportTicket.fromJson(
      _tickets.update(ticketId, {
        'Status': TicketStatus.resolved.wire,
        'UpdatedAt': jsonUtc(DateTime.now()),
      }),
    ),
    module: AppModule.support,
    right: ModuleRight.edit,
  );

  @override
  Future<FeedbackReceipt> sendFeedback(FeedbackInput input) =>
      _backend.run('Feedback send', () {
        final body = input.toJson();
        fakeRequire(body, ['Rating']);
        final id = _feedback.nextId();
        final row = _feedback.insert({
          ...body,
          'Id': id,
          'Number': 'FB-${2290 + id}',
          'CreatedAt': jsonUtc(DateTime.now()),
        });
        return FeedbackReceipt.fromJson(row);
      });

  @override
  Future<void> sendSurvey(String moment, SurveyScore score) =>
      _backend.run('Survey send', () {
        _surveys.insert({
          'Moment': moment,
          'Score': score.score,
          'CreatedAt': jsonUtc(DateTime.now()),
        });
      });

  @override
  Future<EnquiryReceipt> sendEnquiry(EnquiryInput input) =>
      _backend.run('Enquiry send', () {
        final body = input.toJson();
        fakeRequire(body, ['Kind', 'Company', 'Name', 'Mobile', 'Details']);
        final digits = RegExp(
          '[0-9০-৯]',
        ).allMatches(body['Mobile'] as String).length;
        if (digits < 11) {
          throw const ApiFailure(
            400,
            'Enter a full mobile number.',
            fieldErrors: {'Mobile': 'Enter a full mobile number.'},
          );
        }
        final id = _enquiries.nextId();
        final row = _enquiries.insert({
          ...body,
          'Id': id,
          'Reference': 'NX-${(516 + id).toString().padLeft(4, '0')}',
          'CreatedAt': jsonUtc(DateTime.now()),
        });
        return EnquiryReceipt.fromJson(row);
      });

  @override
  Future<void> requestDataExport() => _backend.run('Data export', () {});

  int _nextNumber() {
    var highest = 1000;
    for (final row in _tickets.rows) {
      final number = int.tryParse('${row['Number']}'.replaceAll('SR-', ''));
      if (number != null && number > highest) highest = number;
    }
    return highest + 1;
  }

  static String _subjectOf(String description) {
    final line = description.split(RegExp(r'[\n।.?!]')).first.trim();
    final subject = line.isEmpty ? description : line;
    return subject.length <= 60 ? subject : '${subject.substring(0, 57)}…';
  }

  Map<String, dynamic> _mine(
    int id,
    String body,
    DateTime at,
    List<dynamic> attachments,
  ) => {
    'Id': id,
    'Body': body,
    'FromAgent': false,
    'AuthorName': _backend.graph.me.name,
    'SentAt': jsonUtc(at),
    'Attachments': attachments,
  };

  void _scheduleAgent(int ticketId) {
    late final Timer timer;
    timer = Timer(agentDelay, () {
      _timers.remove(timer);
      _agentAnswers(ticketId);
    });
    _timers.add(timer);
  }

  void _agentAnswers(int ticketId) {
    final row = _tickets.byIdOrNull(ticketId);
    if (row == null || _changes.isClosed) return;
    final messages = [...row['Messages'] as List];
    final last = messages.lastOrNull as Map<String, dynamic>?;
    if (last == null || last['FromAgent'] == true) return;
    final text = last['Body'] as String? ?? '';
    final bangla = hasBanglaScript(text);
    final agent = row['AgentName'] as String? ?? supportAgents.first;
    final me = _backend.graph.me;
    final now = DateTime.now();
    messages.add({
      'Id': messages.length + 1,
      'Body': agentReply(
        text: text,
        category: '${row['Category']}',
        firstName: (bangla ? me.nameBn : me.name).split(' ').first,
        agent: agent,
        bangla: bangla,
        followUp: messages.any((m) => (m as Map)['FromAgent'] == true),
      ),
      'FromAgent': true,
      'AuthorName': agent,
      'SentAt': jsonUtc(now),
      'Attachments': const <Map<String, dynamic>>[],
    });
    _tickets.update(ticketId, {
      'Messages': messages,
      'Status': TicketStatus.replied.wire,
      'AgentName': agent,
      'UpdatedAt': jsonUtc(now),
    });
    _changes.add(ticketId);
  }
}
