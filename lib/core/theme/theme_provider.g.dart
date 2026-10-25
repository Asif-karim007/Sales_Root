// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppThemeNotifier)
final appThemeProvider = AppThemeNotifierProvider._();

final class AppThemeNotifierProvider
    extends $NotifierProvider<AppThemeNotifier, SrThemeId> {
  AppThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeNotifierHash();

  @$internal
  @override
  AppThemeNotifier create() => AppThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SrThemeId value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SrThemeId>(value),
    );
  }
}

String _$appThemeNotifierHash() => r'c2bd545f67066e68cf343e8d8a332e95adfcf6d3';

abstract class _$AppThemeNotifier extends $Notifier<SrThemeId> {
  SrThemeId build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SrThemeId, SrThemeId>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SrThemeId, SrThemeId>,
              SrThemeId,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
