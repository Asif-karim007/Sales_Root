import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/team/data/files_fixtures.dart';
import 'package:salesroot/features/team/models/team_file.dart';
import 'package:salesroot/features/team/providers/files_providers.dart';

import 'team_test_helpers.dart';

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  const priceList = LocalFile(
    path: '/tmp/price_list_nov.pdf',
    name: 'Price_list_Nov.pdf',
    sizeBytes: 1300000,
  );

  test('the photos folder pages 20 at a time', () async {
    container = await teamContainer(role: 'executive');
    container.listen(fileListProvider, (_, _) {});
    container.read(fileFolderProvider.notifier).set('$photosFolder');

    final first = await container.read(fileListProvider.future);
    expect(first.items, hasLength(20));
    expect(first.totalCount, 138);

    await container.read(fileListProvider.notifier).loadMore();
    expect(container.read(fileListProvider).requireValue.items, hasLength(40));
  });

  test('an upload reports progress and lands in its folder', () async {
    container = await teamContainer(role: 'executive');
    final upload = uploadProvider(folderId: '$priceListsFolder');
    final progress = <double>[];
    container.listen(upload, (_, next) => progress.add(next.progress));
    final before = (await container.read(
      fileFoldersProvider.future,
    )).firstWhere((f) => f.id == '$priceListsFolder').fileCount;

    container.read(upload.notifier)
      ..pick(priceList)
      ..setVisibleToAll(false);
    await container.read(upload.notifier).start();

    final state = container.read(upload);
    expect(state.phase, UploadPhase.done);
    expect(state.result?.name, 'Price_list_Nov.pdf');
    expect(state.result?.visibility, FileVisibility.leads);
    expect(progress, contains(1.0));
    final folder = (await container.read(
      fileFoldersProvider.future,
    )).firstWhere((f) => f.id == '$priceListsFolder');
    expect(folder.fileCount, before + 1);
  });

  test('a full plan stops the upload with the storage quota', () async {
    container = await teamContainer(role: 'executive');
    setDev(container, (s) => s.copyWith(quotaReached: true));
    final upload = uploadProvider(folderId: '$priceListsFolder');
    container.listen(upload, (_, _) {});

    container.read(upload.notifier).pick(priceList);
    await container.read(upload.notifier).start();

    final state = container.read(upload);
    expect(state.phase, UploadPhase.failed);
    final failure = state.failure;
    expect(failure, isA<ApiFailure>());
    expect((failure as ApiFailure).quota, QuotaKind.storage);
  });

  test('files over 50 MB are refused', () async {
    container = await teamContainer(role: 'executive');
    final upload = uploadProvider(folderId: '$brochuresFolder');
    container.listen(upload, (_, _) {});

    container
        .read(upload.notifier)
        .pick(
          const LocalFile(
            path: '/tmp/video.mp4',
            name: 'video.mp4',
            sizeBytes: maxUploadBytes + 1,
          ),
        );
    await container.read(upload.notifier).start();

    final failure = container.read(upload).failure;
    expect((failure as ApiFailure?)?.isValidation, isTrue);
  });

  test('a new version bumps the version and keeps the history', () async {
    container = await teamContainer();
    final upload = uploadProvider(replaceFileId: '1');
    container.listen(upload, (_, _) {});

    container.read(upload.notifier).pick(priceList);
    await container.read(upload.notifier).start();

    final file = await container.read(teamFileProvider('1').future);
    expect(file.version, 4);
    expect(file.versions.map((v) => v.version), [4, 3, 2, 1]);
  });

  test("a member can't delete someone else's file", () async {
    container = await teamContainer(role: 'executive');
    container.listen(fileEditorProvider('1'), (_, _) {});

    await container.read(fileEditorProvider('1').notifier).delete();

    final failure = container.read(fileEditorProvider('1')).error;
    expect((failure as ApiFailure?)?.isForbidden, isTrue);
  });
}
