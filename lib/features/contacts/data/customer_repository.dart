import 'dart:typed_data';

import 'package:salesroot/features/contacts/models/customer.dart';

/// The Customer 360 view and the customer's documents.
abstract interface class CustomerRepository {
  Future<CustomerSummary> summary(int companyId);

  /// Newest first.
  Future<List<CustomerDocument>> documents(int companyId);

  /// Counts against the storage quota (402 when full).
  Future<CustomerDocument> upload(int companyId, DocumentUpload upload);

  Future<Uint8List> download(int documentId);

  Future<void> deleteDocument(int documentId);
}
