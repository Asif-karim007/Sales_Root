import 'dart:typed_data';

import 'package:salesroot/features/contacts/models/customer.dart';

/// The Customer 360 view and the customer's files.
abstract interface class CustomerRepository {
  Future<CustomerSummary> summary(String companyId);

  /// Counts against the storage quota (402 when full).
  Future<void> upload(String companyId, DocumentUpload upload);

  Future<Uint8List> download(CustomerDocument document);
}
