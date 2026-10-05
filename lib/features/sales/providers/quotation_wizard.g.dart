// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation_wizard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three-step quotation: customer and items, then discount and terms,
/// then review and send. [editId] edits an existing quotation in place.

@ProviderFor(QuotationWizard)
final quotationWizardProvider = QuotationWizardFamily._();

/// The three-step quotation: customer and items, then discount and terms,
/// then review and send. [editId] edits an existing quotation in place.
final class QuotationWizardProvider
    extends $AsyncNotifierProvider<QuotationWizard, QuotationDraft> {
  /// The three-step quotation: customer and items, then discount and terms,
  /// then review and send. [editId] edits an existing quotation in place.
  QuotationWizardProvider._({
    required QuotationWizardFamily super.from,
    required ({String? leadId, String? editId}) super.argument,
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

String _$quotationWizardHash() => r'575d24754cbc1dcbc1631b0d4a2adb71d1b1fcac';

/// The three-step quotation: customer and items, then discount and terms,
/// then review and send. [editId] edits an existing quotation in place.

final class QuotationWizardFamily extends $Family
    with
        $ClassFamilyOverride<
          QuotationWizard,
          AsyncValue<QuotationDraft>,
          QuotationDraft,
          FutureOr<QuotationDraft>,
          ({String? leadId, String? editId})
        > {
  QuotationWizardFamily._()
    : super(
        retry: null,
        name: r'quotationWizardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The three-step quotation: customer and items, then discount and terms,
  /// then review and send. [editId] edits an existing quotation in place.

  QuotationWizardProvider call({String? leadId, String? editId}) =>
      QuotationWizardProvider._(
        argument: (leadId: leadId, editId: editId),
        from: this,
      );

  @override
  String toString() => r'quotationWizardProvider';
}

/// The three-step quotation: customer and items, then discount and terms,
/// then review and send. [editId] edits an existing quotation in place.

abstract class _$QuotationWizard extends $AsyncNotifier<QuotationDraft> {
  late final _$args = ref.$arg as ({String? leadId, String? editId});
  String? get leadId => _$args.leadId;
  String? get editId => _$args.editId;

  FutureOr<QuotationDraft> build({String? leadId, String? editId});
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
      () => build(leadId: _$args.leadId, editId: _$args.editId),
    );
  }
}
