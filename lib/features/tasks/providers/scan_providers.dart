import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
import 'package:salesroot/features/tasks/data/gemini_api.dart';
import 'package:salesroot/features/tasks/data/gemini_card_scan_repository.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';

part 'scan_providers.g.dart';

/// Gemini when the build carries a key; null when card scanning is not set
/// up.
@Riverpod(keepAlive: true)
CardScanRepository? cardScanRepository(Ref ref) =>
    GeminiApi.apiKey.isEmpty ? null : GeminiCardScanRepository();

/// A photo and what the reader made of it.
class ScanCapture {
  const ScanCapture({
    required this.image,
    required this.mode,
    required this.result,
  });

  final Uint8List image;
  final ScanMode mode;
  final ScanResult result;

  ScannedCard? get card => switch (result) {
    CardScanResult(:final card) => card,
    QrScanResult() => null,
  };

  ScanCapture withCard(ScannedCard card) =>
      ScanCapture(image: image, mode: mode, result: CardScanResult(card));
}

/// The scan in progress, shared by the capture, review, lead and QR screens.
@Riverpod(keepAlive: true)
class ScanSessionNotifier extends _$ScanSessionNotifier {
  @override
  Future<ScanCapture?> build() async {
    ref.watch(cardScanRepositoryProvider);
    return null;
  }

  Future<void> scan(Uint8List image, ScanMode mode) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final reader = ref.read(cardScanRepositoryProvider);
      if (reader == null) throw scanUnavailable;
      final plan = await ref.read(planProvider.future);
      if (plan != null && plan.cardScansUsed >= plan.cardScans) {
        throw const ApiFailure(
          402,
          'Plan limit reached',
          quota: QuotaKind.cardScans,
        );
      }
      return reader.scan(image, mode: mode);
    });
    if (!ref.mounted) return;
    state = result.whenData(
      (scanned) => ScanCapture(image: image, mode: mode, result: scanned),
    );
  }

  /// Keeps the user's corrections for the lead and contact screens.
  void edit(ScannedCard card) {
    final capture = state.value;
    if (capture == null) return;
    state = AsyncData(capture.withCard(card));
  }
}

/// The CRM company matching the scanned [name], if there is one.
@riverpod
Future<String?> scannedCompanyMatch(Ref ref, String name) =>
    ref.watch(taskLookupRepositoryProvider).findCompany(name);
