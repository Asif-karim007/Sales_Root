// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation_wizard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three-step new quotation: customer and items, then discount and
/// terms, then review and send. [fromId] copies an existing quotation, or
/// with [revise] makes its next version.

@ProviderFor(QuotationWizard)
final quotationWizardProvider = QuotationWizardFamily._();

/// The three-step new quotation: customer and items, then discount and
/// terms, then review and send. [fromId] copies an existing quotation, or
/// with [revise] makes its next version.
final class QuotationWizardProvider
    extends $AsyncNotifierProvider<QuotationWizard, QuotationDraft> {
  /// The three-step new quotation: customer and items, then discount and
  /// terms, then review and send. [fromId] copies an existing quotation, or
  /// with [revise] makes its next version.
  QuotationWizardProvider._({
    required QuotationWizardFamily super.from,
    required ({int? leadId, int? fromId, bool revise}) super.argument,
  }) : super(
         retry: null,
         name: r'quotationWizardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quotationWizardHash();

  @override
  String toString() {
    return r'quotationWizardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  QuotationWizard create() => QuotationWizard();

  @override
  bool operator ==(Object other) {
    return other is QuotationWizardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quotationWizardHash() => r'4bc0cd5258e5dae0c708e0038e68b2f9a8994f55';

/// The three-step new quotation: customer and items, then discount and
/// terms, then review and send. [fromId] copies an existing quotation, or
/// with [revise] makes its next version.

final class QuotationWizardFamily extends $Family
    with
        $ClassFamilyOverride<
          QuotationWizard,
          AsyncValue<QuotationDraft>,
          QuotationDraft,
          FutureOr<QuotationDraft>,
          ({int? leadId, int? fromId, bool revise})
        > {
  QuotationWizardFamily._()
    : super(
        retry: null,
        name: r'quotationWizardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The three-step new quotation: customer and items, then discount and
  /// terms, then review and send. [fromId] copies an existing quotation, or
  /// with [revise] makes its next version.

  QuotationWizardProvider call({
    int? leadId,
    int? fromId,
    bool revise = false,
  }) => QuotationWizardProvider._(
    argument: (leadId: leadId, fromId: fromId, revise: revise),
    from: this,
  );

  @override
  String toString() => r'quotationWizardProvider';
}

/// The three-step new quotation: customer and items, then discount and
/// terms, then review and send. [fromId] copies an existing quotation, or
/// with [revise] makes its next version.

abstract class _$QuotationWizard extends $AsyncNotifier<QuotationDraft> {
  late final _$args = ref.$arg as ({int? leadId, int? fromId, bool revise});
  int? get leadId => _$args.leadId;
  int? get fromId => _$args.fromId;
  bool get revise => _$args.revise;

  FutureOr<QuotationDraft> build({
    int? leadId,
    int? fromId,
    bool revise = false,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<QuotationDraft>, QuotationDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuotationDraft>, QuotationDraft>,
              AsyncValue<QuotationDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        leadId: _$args.leadId,
        fromId: _$args.fromId,
        revise: _$args.revise,
      ),
    );
  }
}
