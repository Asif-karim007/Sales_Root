import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

abstract interface class TicketRepository {
  /// Companies matching [term] by name or area, 20 per page.
  Future<PageResult<TicketCustomer>> searchCustomers(String term, int page);

  Future<List<TicketProduct>> products();

  Future<Ticket> create(TicketInput input);

  Future<Ticket> get(int id);

  Future<Ticket> setStatus(int id, TicketStatus status);

  Future<Ticket> reply(int id, String text);
}
