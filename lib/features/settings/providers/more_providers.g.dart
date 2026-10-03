// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'more_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The More menu: every entry the role, plan and level let the user see,
/// grouped. Entries the plan locks stay, marked [MoreItem.locked].

@ProviderFor(moreSections)
final moreSectionsProvider = MoreSectionsProvider._();

/// The More menu: every entry the role, plan and level let the user see,
/// grouped. Entries the plan locks stay, marked [MoreItem.locked].

final class MoreSectionsProvider
    extends
        $FunctionalProvider<
          List<MoreSection>,
          List<MoreSection>,
          List<MoreSection>
        >
    with $Provider<List<MoreSection>> {
  /// The More menu: every entry the role, plan and level let the user see,
  /// grouped. Entries the plan locks stay, marked [MoreItem.locked].
  MoreSectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moreSectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moreSectionsHash();

  @$internal
  @override
  $ProviderElement<List<MoreSection>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MoreSection> create(Ref ref) {
    return moreSections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MoreSection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MoreSection>>(value),
    );
  }
}

String _$moreSectionsHash() => r'47501d4e8d0a5658b63ab0ac56bafe1cb036e89b';
