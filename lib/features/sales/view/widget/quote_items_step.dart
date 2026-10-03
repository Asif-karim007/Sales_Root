import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/customer_picker.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/search_box.dart';
import 'package:salesroot/features/sales/view/widget/voice_search_button.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #52: the customer and price list, then products with quantities. The
/// search takes typing or voice.
class QuoteItemsStep extends ConsumerStatefulWidget {
  const QuoteItemsStep({super.key, required this.draft, required this.wizard});

  final QuotationDraft draft;
  final QuotationWizard wizard;

  @override
  ConsumerState<QuoteItemsStep> createState() => _QuoteItemsStepState();
}

class _QuoteItemsStepState extends ConsumerState<QuoteItemsStep> {
  final _search = TextEditingController();
  String _term = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _spoken(String words) {
    _search.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    setState(() => _term = words.trim());
  }

  Future<void> _pickCustomer() async {
    final customer = await pickSalesCustomer(context, ref);
    if (customer != null) widget.wizard.setCustomer(customer);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final provider = productListProvider(_term, null);
    final results = ref.watch(provider);
    final customer = draft.customer;
    return LoadMoreListener(
      paged: results.value,
      onLoadMore: () => ref.read(provider.notifier).loadMore(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          14,
          SrMetrics.gutter,
          32,
        ),
        children: [
          customer == null
              ? _PickCustomerCard(onTap: _pickCustomer)
              : _CustomerCard(customer: customer, onTap: _pickCustomer),
          const SizedBox(height: 10),
          _PriceListRow(
            value: draft.priceList,
            onChanged: widget.wizard.setPriceList,
          ),
          if (draft.lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            SrSectionHeader(
              title: l10n.salesInThisQuotation(
                context.fmt.number(draft.itemCount),
              ),
            ),
            const SizedBox(height: 8),
            SrRowGroup(
              dividerIndent: 66,
              rows: [
                for (final line in draft.lines)
                  _LineRow(line: line, wizard: widget.wizard),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SearchBox(
            hint: l10n.salesSearchOrSay,
            controller: _search,
            onSearch: (term) => setState(() => _term = term),
            suffix: VoiceSearchButton(onText: _spoken),
          ),
          const SizedBox(height: 10),
          _Results(
            value: results,
            draft: draft,
            onAdd: widget.wizard.addProduct,
            onRetry: () => ref.invalidate(provider),
            onLoadMore: () => ref.read(provider.notifier).loadMore(),
          ),
        ],
      ),
    );
  }
}

class _PickCustomerCard extends StatelessWidget {
  const _PickCustomerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrCard(
      tone: SrCardTone.dashed,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SrListRow(
        leading: const SrAvatar(
          icon: Icons.storefront_outlined,
          tone: SrAvatarTone.accent,
        ),
        title: l10n.salesPickCustomer,
        subtitle: l10n.salesPickCustomerHint,
        chevron: true,
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final SalesCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrCard(
      padding: EdgeInsets.zero,
      child: SrListRow(
        leading: SrAvatar(name: customer.name),
        title: customer.name,
        subtitle:
            '${customer.contactName} · ${l10n.salesPriceListOf(l10n.priceList(customer.priceList))}',
        trailing: SrTag(l10n.salesCustomer, tone: SrTone.ok),
        onTap: onTap,
      ),
    );
  }
}

class _PriceListRow extends StatelessWidget {
  const _PriceListRow({required this.value, required this.onChanged});

  final PriceList value;
  final ValueChanged<PriceList> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: Text(l10n.salesPriceList, style: AppText.meta(c.ink2))),
        SizedBox(
          width: 190,
          child: SrSegmented(
            compact: true,
            segments: [
              SrSegment(l10n.priceList(PriceList.list)),
              SrSegment(l10n.priceList(PriceList.dealer)),
            ],
            index: value.index,
            onChanged: (i) => onChanged(PriceList.values[i]),
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.wizard});

  final SalesLine line;
  final QuotationWizard wizard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrListRow(
      leading: SrAvatar(name: line.name, square: true),
      title: line.nameIn(bangla: fmt.isBangla),
      subtitle: '${fmt.money(line.unitPrice)} / ${l10n.unit(line.unit)}',
      trailing: QtyStepper(
        qty: line.qty,
        onChanged: (qty) => wizard.setQty(line.productId, qty),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.value,
    required this.draft,
    required this.onAdd,
    required this.onRetry,
    required this.onLoadMore,
  });

  final AsyncValue<Paged<Product>> value;
  final QuotationDraft draft;
  final ValueChanged<Product> onAdd;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return switch (value) {
      AsyncValue(:final value?) when value.isEmpty => SrEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.salesProductsEmpty,
      ),
      AsyncValue(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.items.any((p) => draft.qtyOf(p.id) == 0))
            SrRowGroup(
              dividerIndent: 66,
              rows: [
                for (final product in value.items)
                  if (draft.qtyOf(product.id) == 0)
                    SrListRow(
                      leading: SrAvatar(name: product.name, square: true),
                      title: product.nameIn(bangla: fmt.isBangla),
                      subtitle:
                          '${fmt.money(product.priceIn(draft.priceList))} / ${l10n.unit(product.unit)}',
                      trailing: SrIconButton(
                        icon: Icons.add_rounded,
                        compact: true,
                        tooltip: l10n.commonAdd,
                        onTap: () => onAdd(product),
                      ),
                      onTap: () => onAdd(product),
                    ),
              ],
            ),
          PagedFooter(paged: value, onRetry: onLoadMore),
        ],
      ),
      AsyncValue(:final error?) => SrErrorState(
        error: error,
        compact: true,
        onRetry: onRetry,
      ),
      _ => const SrSkeletonList(
        count: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    };
  }
}

/// − qty + ; tapping the number lets the user type it.
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onChanged});

  final int qty;
  final ValueChanged<int> onChanged;

  Future<void> _type(BuildContext context) async {
    final typed = await showSrSheet<int>(
      context: context,
      builder: (_) => _QtySheet(qty: qty),
    );
    if (typed != null) onChanged(typed);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SrIconButton(
          icon: Icons.remove_rounded,
          compact: true,
          color: c.ink2,
          tooltip: l10n.salesLess,
          onTap: () => onChanged(qty - 1),
        ),
        InkWell(
          onTap: () => _type(context),
          borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                context.fmt.qty(qty),
                textAlign: TextAlign.center,
                style: AppText.rowTitle(c.ink, size: 15),
              ),
            ),
          ),
        ),
        SrIconButton(
          icon: Icons.add_rounded,
          compact: true,
          color: c.accent,
          tooltip: l10n.salesMore,
          onTap: () => onChanged(qty + 1),
        ),
      ],
    );
  }
}

class _QtySheet extends StatefulWidget {
  const _QtySheet({required this.qty});

  final int qty;

  @override
  State<_QtySheet> createState() => _QtySheetState();
}

class _QtySheetState extends State<_QtySheet> {
  late final _controller = TextEditingController(text: '${widget.qty}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() =>
      Navigator.of(context).pop(int.tryParse(_controller.text.trim()) ?? 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.salesQuantity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrTextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: 14),
          SrButton(label: l10n.commonDone, expand: true, onPressed: _done),
        ],
      ),
    );
  }
}
