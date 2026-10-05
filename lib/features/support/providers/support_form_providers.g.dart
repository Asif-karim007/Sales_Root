// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_form_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True once the feedback is sent.

@ProviderFor(FeedbackSubmitNotifier)
final feedbackSubmitProvider = FeedbackSubmitNotifierProvider._();

/// True once the feedback is sent.
final class FeedbackSubmitNotifierProvider
    extends $AsyncNotifierProvider<FeedbackSubmitNotifier, bool> {
  /// True once the feedback is sent.
  FeedbackSubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedbackSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedbackSubmitNotifierHash();

  @$internal
  @override
  FeedbackSubmitNotifier create() => FeedbackSubmitNotifier();
}

String _$feedbackSubmitNotifierHash() =>
    r'd708ea1e14acfac4aac678349065a72b883f97ea';

/// True once the feedback is sent.

abstract class _$FeedbackSubmitNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// True once the enquiry is sent.

@ProviderFor(EnquirySubmitNotifier)
final enquirySubmitProvider = EnquirySubmitNotifierProvider._();

/// True once the enquiry is sent.
final class EnquirySubmitNotifierProvider
    extends $AsyncNotifierProvider<EnquirySubmitNotifier, bool> {
  /// True once the enquiry is sent.
  EnquirySubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enquirySubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enquirySubmitNotifierHash();

  @$internal
  @override
  EnquirySubmitNotifier create() => EnquirySubmitNotifier();
}

String _$enquirySubmitNotifierHash() =>
    r'6925068b356666a6494552cf4b14b44e7b277e3b';

/// True once the enquiry is sent.

abstract class _$EnquirySubmitNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// When the moment survey was last shown. It is shown at most once every
/// [interval], whatever the moment.

@ProviderFor(SurveyGateNotifier)
final surveyGateProvider = SurveyGateNotifierProvider._();

/// When the moment survey was last shown. It is shown at most once every
/// [interval], whatever the moment.
final class SurveyGateNotifierProvider
    extends $NotifierProvider<SurveyGateNotifier, DateTime?> {
  /// When the moment survey was last shown. It is shown at most once every
  /// [interval], whatever the moment.
  SurveyGateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'surveyGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$surveyGateNotifierHash();

  @$internal
  @override
  SurveyGateNotifier create() => SurveyGateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$surveyGateNotifierHash() =>
    r'a8babba2a62bdb14bc9167fbc0264a8e9300b756';

/// When the moment survey was last shown. It is shown at most once every
/// [interval], whatever the moment.

abstract class _$SurveyGateNotifier extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The face the user tapped for [moment]; null until they answer.

@ProviderFor(MomentSurveyNotifier)
final momentSurveyProvider = MomentSurveyNotifierFamily._();

/// The face the user tapped for [moment]; null until they answer.
final class MomentSurveyNotifierProvider
    extends $AsyncNotifierProvider<MomentSurveyNotifier, SurveyScore?> {
  /// The face the user tapped for [moment]; null until they answer.
  MomentSurveyNotifierProvider._({
    required MomentSurveyNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'momentSurveyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$momentSurveyNotifierHash();

  @override
  String toString() {
    return r'momentSurveyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MomentSurveyNotifier create() => MomentSurveyNotifier();

  @override
  bool operator ==(Object other) {
    return other is MomentSurveyNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$momentSurveyNotifierHash() =>
    r'affe2e5547009bf1ef89e3766fe2131948868944';

/// The face the user tapped for [moment]; null until they answer.

final class MomentSurveyNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MomentSurveyNotifier,
          AsyncValue<SurveyScore?>,
          SurveyScore?,
          FutureOr<SurveyScore?>,
          String
        > {
  MomentSurveyNotifierFamily._()
    : super(
        retry: null,
        name: r'momentSurveyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The face the user tapped for [moment]; null until they answer.

  MomentSurveyNotifierProvider call(String moment) =>
      MomentSurveyNotifierProvider._(argument: moment, from: this);

  @override
  String toString() => r'momentSurveyProvider';
}

/// The face the user tapped for [moment]; null until they answer.

abstract class _$MomentSurveyNotifier extends $AsyncNotifier<SurveyScore?> {
  late final _$args = ref.$arg as String;
  String get moment => _$args;

  FutureOr<SurveyScore?> build(String moment);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SurveyScore?>, SurveyScore?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SurveyScore?>, SurveyScore?>,
              AsyncValue<SurveyScore?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

final class PackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'854bbb0e381edfdddbd736229351d6cc918a2ad1';

@ProviderFor(supportDiagnostics)
final supportDiagnosticsProvider = SupportDiagnosticsProvider._();

final class SupportDiagnosticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SupportDiagnostics>,
          SupportDiagnostics,
          FutureOr<SupportDiagnostics>
        >
    with
        $FutureModifier<SupportDiagnostics>,
        $FutureProvider<SupportDiagnostics> {
  SupportDiagnosticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportDiagnosticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportDiagnosticsHash();

  @$internal
  @override
  $FutureProviderElement<SupportDiagnostics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SupportDiagnostics> create(Ref ref) {
    return supportDiagnostics(ref);
  }
}

String _$supportDiagnosticsHash() =>
    r'e3cf9f125046bee580e5c21774d152cf2c21a3de';
