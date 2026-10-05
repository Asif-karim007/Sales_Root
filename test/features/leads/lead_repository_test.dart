import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/leads/data/lead_repository.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/models/lead_transcript.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';

import '../../helpers/api_stub.dart';
import 'lead_stub.dart';

Future<LeadRepository> _repository(ApiStub stub) async {
  final container = await leadContainer(stub);
  return container.read(leadRepositoryProvider);
}

Future<LeadStage> _stage(LeadRepository repository, String id) async =>
    (await repository.stages()).firstWhere((s) => s.id == id);

void main() {
  group('reading', () {
    test('a list page parses the recorded rows', () async {
      final repository = await _repository(leadStub());
      final page = await repository.list(const LeadQuery());
      final rahim = page.items.firstWhere((l) => l.id == rahimId);

      expect(page.totalCount, 3);
      expect(rahim.leadName, 'Mr Rahim');
      expect(rahim.title, '50 cartons soap · November');
      expect(rahim.company?.name, 'Rahim Traders');
      expect(rahim.contact?.name, 'Mr Rahim');
      expect(rahim.stage?.name.bn, 'নমুনা দেওয়া');
      expect(rahim.winProbability, 45);
      expect(rahim.estimatedAmount, 206400);
      expect(rahim.temperature, LeadTemperature.hot);
      expect(rahim.assignedTo?.id, meMemberId);
      expect(rahim.customText('productInterest'), 'Soap 100g x 50 ctn');
      expect(rahim.isOpen, isTrue);
    });

    test('the query sends offset, limit and the server filters', () async {
      final stub = leadStub();
      final repository = await _repository(stub);
      await repository.list(
        const LeadQuery(
          page: 3,
          search: ' rahim ',
          chip: LeadChip.dueToday,
          mine: true,
          source: 'card',
          temperature: LeadTemperature.cold,
        ),
      );
      final query = stub.last('GET', 'leads')?.queryParameters;
      expect(query?['offset'], 40);
      expect(query?['limit'], 20);
      expect(query?['q'], 'rahim');
      expect(query?['scope'], 'mine');
      expect(query?['status'], 'open');
      expect(query?['dueToday'], true);
      expect(query?['source'], 'card');
      expect(query?['temperature'], 'cold');
      expect(query?.containsKey('sleeping'), isFalse);

      await repository.list(
        const LeadQuery(
          chip: LeadChip.hot,
          stageId: sampleStage,
          openOnly: false,
          ownerId: meMemberId,
        ),
      );
      final next = stub.last('GET', 'leads')?.queryParameters;
      expect(next?['temperature'], 'hot');
      expect(next?['stageId'], sampleStage);
      expect(next?['ownerId'], meMemberId);
      expect(next?.containsKey('status'), isFalse);
      expect(next?.containsKey('scope'), isFalse);
    });

    test('the detail carries its timeline, open task and quotation', () async {
      final repository = await _repository(leadStub());
      final lead = await repository.get(rahimId);

      expect(lead.timeline, hasLength(2));
      expect(lead.timeline.first.kind, LeadActivityKind.call);
      expect(lead.timeline.first.outcome, CallOutcome.answered);
      expect(lead.timeline.first.durationMinutes, 4);
      expect(lead.nextTask?.title, 'Visit Rahim Traders');
      expect(lead.nextTask?.kind, LeadActivityKind.visit);
      expect(lead.nextTaskAt, lead.nextTask?.dueAt);
      expect(lead.lastQuoted, 206400);
    });

    test('server entries read as won, lost, stage and system', () async {
      final stub = leadStub()
        ..on('GET', 'leads/{id}', fixture('leads_detail_closed'));
      final repository = await _repository(stub);
      final timeline = (await repository.get('any')).timeline;

      final won = timeline.firstWhere((e) => e.kind == LeadActivityKind.won);
      expect(won.amount, 15000);
      final lost = timeline.firstWhere((e) => e.kind == LeadActivityKind.lost);
      expect(lost.lostReason, 'price');
      final stage = timeline.firstWhere(
        (e) => e.kind == LeadActivityKind.stageChange,
      );
      expect(stage.stageName?.en, 'Sample given');
      expect(stage.stageName?.bn, 'নমুনা দেওয়া');
      expect(
        timeline.where((e) => e.kind == LeadActivityKind.system),
        isNotEmpty,
      );
    });

    test('stages come in funnel order; Easy keeps its own', () async {
      final repository = await _repository(leadStub());
      final stages = await repository.stages();

      expect(stages.won?.id, orderedStage);
      expect(stages.lost?.id, lostStage);
      final standard = stages.visibleFor(ExperienceLevel.standard);
      expect(standard.first.id, toContactStage);
      expect(standard.any((s) => s.isLost), isFalse);
      final easy = stages.visibleFor(ExperienceLevel.easy);
      expect(easy.map((s) => s.name.en), [
        'To contact',
        'Visited',
        'Ordered',
        'Paid',
      ]);
      expect(stages.byId(sampleStage)?.requiredFields, ['productInterest']);
    });

    test('lookups read members and the workspace pack', () async {
      final repository = await _repository(leadStub());
      final lookups = await repository.lookups();

      expect(lookups.currentMemberId, meMemberId);
      expect(lookups.owners, isNotEmpty);
      expect(lookups.lostReason('price')?.name.en, contains('Price'));
      expect(lookups.field('productInterest')?.label.en, 'Products wanted');
    });
  });

  group('writing', () {
    test('a create sends the server fields and logs the note', () async {
      final stub = leadStub()
        ..on('POST', 'leads', fixtureMap('leads_detail')['lead'])
        ..on('POST', 'activities', const <String, dynamic>{});
      final repository = await _repository(stub);
      await repository.create(
        LeadInput(
          leadName: ' Karim Hossain ',
          phone: '01711234567',
          title: '500 pcs',
          estimatedAmount: 200000,
          estimatedClosingDate: DateTime(2026, 10, 30),
          source: 'card',
          stageId: visitedStage,
          ownerId: meMemberId,
          temperature: LeadTemperature.hot,
          custom: const {'productInterest': 'Uniforms'},
          note: 'Met at the fair',
        ),
      );

      final body = stub.lastBody('POST', 'leads');
      expect(body['name'], 'Karim Hossain');
      expect(body['phone'], '01711234567');
      expect(body['amount'], 200000);
      expect(body['expectedClose'], '2026-10-30');
      expect(body['source'], 'card');
      expect(body['stageId'], visitedStage);
      expect(body['temperature'], 'hot');
      expect(body['custom'], {'productInterest': 'Uniforms'});
      expect(body.containsKey('companyId'), isFalse);
      expect(body.containsKey('allowDuplicate'), isFalse);
      expect(stub.last('POST', 'leads/{id}/assign'), isNull);
      expect(stub.lastBody('POST', 'activities'), {
        'type': 'note',
        'leadId': rahimId,
        'body': 'Met at the fair',
      });
    });

    test('a typed company is created and linked', () async {
      final stub = leadStub()
        ..on('POST', 'leads', fixtureMap('leads_detail')['lead'])
        ..on('POST', 'companies', fixtureMap('leads_company')['company'])
        ..on('PATCH', 'leads/{id}', fixtureMap('leads_detail')['lead']);
      final repository = await _repository(stub);
      await repository.create(
        const LeadInput(leadName: 'Karim', companyName: 'Karim Textiles'),
      );

      expect(stub.lastBody('POST', 'companies')['name'], 'Karim Textiles');
      expect(stub.lastBody('PATCH', 'leads/{id}'), {
        'companyId': '01a10101-8657-7f15-8630-b08119f1ae61',
      });
    });

    test('a known phone answers the existing lead to open', () async {
      final stub = leadStub()
        ..on(
          'POST',
          'leads',
          (RequestOptions r) =>
              StubReply(422, fixture('leads_duplicate_error')),
        );
      final repository = await _repository(stub);

      await expectLater(
        repository.create(
          const LeadInput(leadName: 'Rahim', phone: '01811000010'),
        ),
        throwsA(
          isA<LeadDuplicateFailure>()
              .having((f) => f.existing.id, 'existing', rahimId)
              .having((f) => f.existing.leadName, 'name', 'Mr Rahim'),
        ),
      );
      expect(
        stub.last('GET', 'leads/check-phone')?.queryParameters['phone'],
        '01811000010',
      );

      stub.on('POST', 'leads', fixtureMap('leads_detail')['lead']);
      await repository.create(
        const LeadInput(
          leadName: 'Rahim',
          phone: '01811000010',
        ).allowingDuplicate(),
      );
      expect(stub.lastBody('POST', 'leads')['allowDuplicate'], true);
    });

    test('validation keeps the server field', () async {
      final stub = leadStub()
        ..fail(
          'POST',
          'leads',
          422,
          message: 'Please fill this in',
          field: 'name',
        );
      final repository = await _repository(stub);

      await expectLater(
        repository.create(const LeadInput(leadName: '')),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.isValidation, 'validation', isTrue)
              .having((f) => f.fieldError('name'), 'name', isNotNull),
        ),
      );
    });

    test('an edit patches, then moves the stage and the owner', () async {
      final stub = leadStub()
        ..on('PATCH', 'leads/{id}', fixtureMap('leads_detail')['lead'])
        ..on('POST', 'leads/{id}/stage', fixtureMap('leads_detail')['lead'])
        ..on('POST', 'leads/{id}/assign', fixtureMap('leads_detail')['lead']);
      final repository = await _repository(stub);
      final lead = await repository.get(rahimId);
      final input = LeadInput.fromLead(lead);
      await repository.edit(
        lead,
        LeadInput(
          leadName: 'Mr Rahim',
          phone: input.phone,
          estimatedAmount: 210000,
          stageId: visitedStage,
          ownerId: 'someone-else',
          custom: input.custom,
        ),
      );

      final body = stub.lastBody('PATCH', 'leads/{id}');
      expect(body['amount'], 210000);
      expect(body['custom'], {'productInterest': 'Soap 100g x 50 ctn'});
      expect(body.containsKey('stageId'), isFalse);
      expect(stub.lastBody('POST', 'leads/{id}/stage'), {
        'stageId': visitedStage,
      });
      expect(stub.lastBody('POST', 'leads/{id}/assign'), {
        'membershipId': 'someone-else',
      });
    });
  });

  group('stage moves', () {
    test('Lost goes through the lost action with the reason', () async {
      final stub = leadStub()..on('POST', 'leads/{id}/lost', const {});
      final repository = await _repository(stub);
      final lead = await repository.get(rahimId);
      await repository.moveStage(
        lead,
        LeadStageInput(
          stage: await _stage(repository, lostStage),
          lostReason: 'price',
          note: ' Too pricey ',
        ),
      );
      expect(stub.lastBody('POST', 'leads/{id}/lost'), {
        'reason': 'price',
        'note': 'Too pricey',
      });
    });

    test('Won sends the amount without an invoice', () async {
      final stub = leadStub()..on('POST', 'leads/{id}/won', const {});
      final repository = await _repository(stub);
      final lead = await repository.get(rahimId);
      await repository.moveStage(
        lead,
        LeadStageInput(stage: await _stage(repository, orderedStage)),
      );
      expect(stub.lastBody('POST', 'leads/{id}/won'), {
        'amount': 206400.0,
        'createInvoice': false,
      });
    });

    test('a lost lead reopens before it moves on', () async {
      final closed = fixtureMap('leads_detail_closed');
      final lost = {
        ...closed,
        'lead': {
          ...closed['lead'] as Map<String, dynamic>,
          'status': 'lost',
          'stageId': lostStage,
        },
      };
      final stub = leadStub()
        ..on('GET', 'leads/{id}', lost)
        ..on('POST', 'leads/{id}/reopen', closed['lead'])
        ..on('POST', 'leads/{id}/stage', closed['lead']);
      final repository = await _repository(stub);
      final lead = await repository.get('any');
      expect(lead.isLost, isTrue);

      await repository.moveStage(
        lead,
        LeadStageInput(stage: await _stage(repository, sampleStage)),
      );
      expect(stub.last('POST', 'leads/{id}/reopen'), isNotNull);
      expect(stub.last('POST', 'leads/{id}/stage'), isNull);

      await repository.moveStage(
        lead,
        LeadStageInput(stage: await _stage(repository, visitedStage)),
      );
      expect(stub.lastBody('POST', 'leads/{id}/stage'), {
        'stageId': visitedStage,
      });
    });

    test('required fields go with the move, merged into custom', () async {
      final stub = leadStub()
        ..on('POST', 'leads/{id}/stage', fixtureMap('leads_detail')['lead']);
      final repository = await _repository(stub);
      final lead = await repository.get(rahimId);
      await repository.moveStage(
        lead,
        LeadStageInput(
          stage: await _stage(repository, visitedStage),
          custom: const {'route': 'Mirpur-A'},
        ),
      );
      expect(stub.lastBody('POST', 'leads/{id}/stage'), {
        'stageId': visitedStage,
        'custom': {
          'productInterest': 'Soap 100g x 50 ctn',
          'route': 'Mirpur-A',
        },
      });
    });
  });

  group('activities', () {
    test('a call log sends type, outcome, seconds and follow-up', () async {
      final stub = leadStub()..on('POST', 'activities', const {});
      final repository = await _repository(stub);
      await repository.logActivity(
        rahimId,
        LeadActivityInput(
          kind: LeadActivityKind.call,
          occurredOn: DateTime.utc(2026, 10, 5, 10),
          durationMinutes: 3,
          outcome: CallOutcome.noAnswer,
          description: ' ',
          followUpAt: DateTime.utc(2026, 10, 6, 4),
        ),
      );
      final body = stub.lastBody('POST', 'activities');
      expect(body['type'], 'call');
      expect(body['leadId'], rahimId);
      expect(body['outcome'], 'no_answer');
      expect(body['durationSec'], 180);
      expect(body.containsKey('body'), isFalse);
      expect(body['nextFollowUp'], startsWith('2026-10-06T04:00'));
    });

    test('the next task is marked done through its own action', () async {
      final stub = leadStub()..on('POST', 'tasks/{id}/done', const {});
      final repository = await _repository(stub);
      await repository.completeTask(rahimId, 'task-1');
      expect(
        stub.last('POST', 'tasks/{id}/done')?.path,
        endsWith('task-1/done'),
      );
    });
  });

  group('voice', () {
    const heard = LeadTranscript(text: 'karim 01711234567', name: 'Karim');

    test('stays on the phone while the AI is off', () async {
      final stub = leadStub();
      final repository = await _repository(stub);
      expect(identical(await repository.refine(heard), heard), isTrue);
      expect(stub.last('POST', 'ai/parse'), isNull);
    });

    test('takes what the server read when the AI is on', () async {
      final stub = leadStub()
        ..on('GET', 'ai/status', {
          ...fixtureMap('leads_ai_status'),
          'enabled': true,
        })
        ..on('POST', 'ai/parse', fixture('leads_ai_parse'));
      final repository = await _repository(stub);
      final refined = await repository.refine(heard);
      expect(refined.phone, '01711234567');
      expect(refined.name, 'Karim');
      expect(stub.lastBody('POST', 'ai/parse')['kind'], 'lead');
    });

    test('falls back to the phone when the server fails', () async {
      final stub = leadStub()..fail('GET', 'ai/status', 503);
      final repository = await _repository(stub);
      expect(identical(await repository.refine(heard), heard), isTrue);
    });
  });
}
