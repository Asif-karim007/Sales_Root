import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

abstract interface class TicketRepository {
  /// Companies matching [term] by name, 20 per page.
  Future<PageResult<TicketCustomer>> searchCustomers(String term, int page);

  /// Raises the ticket, attaches its photos and returns it.
  Future<Ticket> create(TicketInput input);

  Future<Ticket> get(String id);

  Future<void> setStatus(String id, TicketStatus status);

  Future<void> reply(String id, String text);
}
