import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/data/hr_sources.dart';
import 'package:salesroot/features/hr/data/ticket_repository.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

class ApiTicketRepository implements TicketRepository {
  ApiTicketRepository(this._api);

  final HrApi _api;

  @override
  Future<PageResult<TicketCustomer>> searchCustomers(
    String term,
    int page,
  ) async {
    final text = term.trim();
    final json = await apiRequest(
      'Ticket customers',
      () =>
          _api.companies({if (text.isNotEmpty) 'q': text, ...pageQuery(page)}),
    );
    return PageResult.fromJson(jsonMap(json), TicketCustomer.fromJson);
  }

  @override
  Future<Ticket> create(TicketInput input) async {
    final json = await apiRequest(
      'Ticket create',
      () => _api.createTicket(input.toJson()),
    );
    final id = jsonId(jsonMap(json)['id']) ?? '';
    for (final path in input.photos) {
      await uploadHrPhoto(_api, path, entityType: 'ticket', entityId: id);
    }
    return get(id);
  }

  @override
  Future<Ticket> get(String id) async => Ticket.fromJson(
    jsonMap(await apiRequest('Ticket $id', () => _api.ticket(id))),
  );

  @override
  Future<void> setStatus(String id, TicketStatus status) => apiRequest(
    'Ticket ${status.wire}',
    () => _api.updateTicket(id, {'status': status.wire}),
  );

  @override
  Future<void> reply(String id, String text) => apiRequest(
    'Ticket reply',
    () => _api.replyTicket(id, {'body': text.trim()}),
  );
}
