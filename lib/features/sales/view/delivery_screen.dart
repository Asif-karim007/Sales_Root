import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #58: delivery or service completion: what went out and when; optionally
/// makes the bill at once.
class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _note = TextEditingController();
  bool _seeded = false;

  DeliveryFormProvider get _provider => deliveryFormProvider(widget.orderId);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _seed(DeliveryDraft draft) {
    if (_seeded) return;
    _seeded = true;
    _note.text = draft.note;
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showSrDatePicker(
      context: context,
      initial: current,
      last: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) ref.read(_provider.notifier).setDeliveredOn(picked);
  }

  void _saved(SalesOrder order) {
    final l10n = context.l10n;
    final bill = order.invoices.isEmpty ? null : order.invoices.first;
    showSrSuccess(context, l10n.salesDeliverySaved);
    if (bill != null && ref.read(_provider).value?.createBill == true) {
      context.pushReplacement(Routes.invoiceFor(bill.id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    ref.listen(_provider.select((s) => s.value?.submission), (previous, next) {
      if (previous == next) return;
      switch (next) {
        case AsyncData(:final value):
          _saved(value);
        case AsyncError(:final error):
          showSalesFailure(context, error);
        default:
          break;
      }
    });
    final draft = state.value;
    if (draft != null) _seed(draft);
    return SrScaffold(
      appBar: SrAppBar(title: l10n.salesDeliveryTitle),
      body: SrAsyncView<DeliveryDraft>(
        value: state,
        onRetry: () => ref.invalidate(_provider),
        onUpgrade: upgradeFor(context, state.error),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, draft) => SrKeyboardDismiss(
          child: _DeliveryForm(
            draft: draft,
            note: _note,
            onDate: () => _pickDate(draft.deliveredOn),
          ),
        ),
      ),
      footer: draft == null
          ? null
          : SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: draft.isSaving,
              onPressed: draft.isSaving || draft.delivered.isEmpty
                  ? null
                  : ref.read(_provider.notifier).save,
            ),
    );
  }
}

class _DeliveryForm extends ConsumerWidget {
  const _DeliveryForm({
    required this.draft,
    required this.note,
    required this.onDate,
  });

  final DeliveryDraft draft;
  final TextEditingController note;
  final VoidCallback onDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final form = ref.read(deliveryFormProvider(draft.order.id).notifier);
    final order = draft.order;
    final canBill =
        order.invoices.isEmpty &&
        ref.watch(moduleAccessProvider(AppModule.invoice)).canAdd;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrCard(
          padding: EdgeInsets.zero,
          child: SrListRow(
            leading: SrAvatar(name: order.companyName),
            title: '${order.number} · ${order.companyName}',
            subtitle: [
              for (final line in order.lines)
                '${fmt.qty(line.qty)} ${line.nameIn(bangla: fmt.isBangla)}',
            ].join(' · '),
          ),
        ),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.salesChecklist),
        const SizedBox(height: 8),
        SrRowGroup(
          rows: [
            for (final line in order.lines)
              SrListRow(
                leading: SrCheckbox(
                  value: draft.delivered.contains(line.key),
                  onChanged: (_) => form.toggleItem(line.key),
                ),
                title: line.nameIn(bangla: fmt.isBangla),
                subtitle: '${fmt.qty(line.qty)} ${l10n.unit(line.unit)}',
                onTap: () => form.toggleItem(line.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SrPickerField(
          label: l10n.salesDeliveryDate,
          icon: Icons.event_outlined,
          value: fmt.date(draft.deliveredOn),
          onTap: onDate,
        ),
        const SizedBox(height: 12),
        SrTextField(
          controller: note,
          label: l10n.salesNote,
          optional: true,
          multiline: true,
          onChanged: form.setNote,
        ),
        if (canBill) ...[
          const SizedBox(height: 8),
          SrListRow(
            padding: EdgeInsets.zero,
            title: l10n.salesCreateBillNow,
            subtitle: l10n.salesCreateBillNowHint,
            trailing: SrSwitch(
              value: draft.createBill,
              onChanged: form.setCreateBill,
            ),
          ),
        ],
      ],
    );
  }
}
