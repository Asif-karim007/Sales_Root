import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';

/// The leads, teammates and companies the task and scan screens pick from.
abstract interface class TaskLookupRepository {
  Future<PageResult<LeadOption>> searchLeads(String term, int page);

  Future<LeadOption> lead(int id);

  Future<List<MemberOption>> members();

  /// The id of the company already in the CRM under [name], if any.
  Future<int?> findCompany(String name);
}
