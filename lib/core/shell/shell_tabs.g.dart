// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_tabs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The four tabs in the bottom bar. The third one depends on who is using
/// the app: Team for leads and owners, Sales from the Standard level up,
/// Tasks otherwise.

@ProviderFor(shellTabs)
final shellTabsProvider = ShellTabsProvider._();

/// The four tabs in the bottom bar. The third one depends on who is using
/// the app: Team for leads and owners, Sales from the Standard level up,
/// Tasks otherwise.

final class ShellTabsProvider
    extends
        $FunctionalProvider<
          List<ShellBranch>,
          List<ShellBranch>,
          List<ShellBranch>
        >
    with $Provider<List<ShellBranch>> {
  /// The four tabs in the bottom bar. The third one depends on who is using
  /// the app: Team for leads and owners, Sales from the Standard level up,
  /// Tasks otherwise.
  ShellTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellTabsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellTabsHash();

  @$internal
  @override
  $ProviderElement<List<ShellBranch>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ShellBranch> create(Ref ref) {
    return shellTabs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ShellBranch> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ShellBranch>>(value),
    );
  }
}

String _$shellTabsHash() => r'a2bc8e4eeef81ba43c5a75b40429c2a69a893196';
