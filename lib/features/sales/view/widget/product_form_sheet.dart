import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Adds a product to the catalogue, or edits [product].
Future<void> showProductForm(BuildContext context, {Product? product}) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _ProductForm(product: product),
    );

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  late final _name = TextEditingController(text: widget.product?.name);
  late final _nameBn = TextEditingController(text: widget.product?.nameBn);
  late final _code = TextEditingController(text: widget.product?.code);
  late final _unit = TextEditingController(text: widget.product?.unit);
  late final _price = TextEditingController(
    text: switch (widget.product) {
      final product? => _number(product.price),
      null => '',
    },
  );
  late final _vat = TextEditingController(
    text: switch (widget.product) {
      final product? when product.vatBps > 0 => _number(
        percentFromBps(product.vatBps),
      ),
      _ => '',
    },
  );
  bool _tried = false;

  ProductEditorProvider get _provider =>
      productEditorProvider(widget.product?.id);

  @override
  void dispose() {
    for (final controller in [_name, _nameBn, _code, _unit, _price, _vat]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? get _priceValue => double.tryParse(_price.text.trim());

  void _save() {
    setState(() => _tried = true);
    final price = _priceValue;
    if (_name.text.trim().isEmpty || price == null) return;
    ref
        .read(_provider.notifier)
        .save(
          ProductInput(
            name: _name.text,
            nameBn: _nameBn.text,
            code: _code.text,
            unit: _unit.text,
            price: price,
            vatBps: bpsFromPercent(double.tryParse(_vat.text.trim()) ?? 0),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    ref.listen(_provider, (_, next) {
      switch (next) {
        case AsyncData():
          showSrSuccess(context, l10n.salesProductSaved);
          Navigator.of(context).pop();
        case AsyncError(:final error):
          showSalesFailure(context, error);
        default:
          break;
      }
    });
    final failure = state?.error;
    String? error(String field, {bool missing = false}) {
      if (_tried && missing) return l10n.commonRequired;
      return failure is ApiFailure ? failure.fieldError(field) : null;
    }

    final decimals = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?')),
    ];
    return SrSheet(
      title: widget.product == null
          ? l10n.salesAddProduct
          : l10n.salesEditProduct,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                SrTextField(
                  controller: _name,
                  label: l10n.salesProductName,
                  error: error('nameEn', missing: _name.text.trim().isEmpty),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                SrTextField(
                  controller: _nameBn,
                  label: l10n.salesProductNameBn,
                  optional: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SrTextField(
                        controller: _code,
                        label: l10n.salesProductCode,
                        optional: true,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SrTextField(
                        controller: _unit,
                        label: l10n.salesUnit,
                        optional: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SrTextField(
                        controller: _price,
                        label: l10n.salesPrice,
                        prefix: Text(l10n.salesTaka),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: decimals,
                        error: error('price', missing: _priceValue == null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SrTextField(
                        controller: _vat,
                        label: l10n.salesVatRate,
                        optional: true,
                        suffixText: '%',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: decimals,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SrButton(
            label: l10n.commonSave,
            expand: true,
            loading: state?.isLoading ?? false,
            onPressed: state?.isLoading ?? false ? null : _save,
          ),
        ],
      ),
    );
  }
}
