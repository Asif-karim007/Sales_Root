import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/tasks/data/card_scan_repository.dart';
import 'package:salesroot/features/tasks/data/fake_card_scan_repository.dart';
import 'package:salesroot/features/tasks/data/gemini_api.dart';
import 'package:salesroot/features/tasks/data/gemini_card_scan_repository.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/providers/task_providers.dart';

part 'scan_providers.g.dart';

/// Gemini when the build carries a key, the fake reader otherwise.
@Riverpod(keepAlive: true)
CardScanRepository cardScanRepository(Ref ref) {
  final backend = ref.watch(fakeBackendProvider);
  return GeminiApi.apiKey.isEmpty
      ? FakeCardScanRepository(backend)
      : GeminiCardScanRepository(backend);
}

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
    final result = await AsyncValue.guard(
      () => ref.read(cardScanRepositoryProvider).scan(image, mode: mode),
    );
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
Future<int?> scannedCompanyMatch(Ref ref, String name) =>
    ref.watch(taskLookupRepositoryProvider).findCompany(name);
