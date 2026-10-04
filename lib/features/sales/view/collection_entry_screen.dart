import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/collection_fields.dart';
import 'package:salesroot/features/sales/view/widget/customer_picker.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #61: records money received, by any method, against the customer's
/// oldest dues or the instalments the user picks.
class CollectionEntryScreen extends ConsumerStatefulWidget {
  const CollectionEntryScreen({
    super.key,
    this.customerId,
    this.invoiceId,
    this.orderId,
  });

  final int? customerId;
  final int? invoiceId;
  final int? orderId;

  @override
  ConsumerState<CollectionEntryScreen> createState() =>
      _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends ConsumerState<CollectionEntryScreen> {
  final _amount = TextEditingController();

  CollectionEntryProvider get _provider => collectionEntryProvider(
    customerId: widget.customerId,
    invoiceId: widget.invoiceId,
    orderId: widget.orderId,
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final picked = await pickDebtor(context, ref);
    if (picked == null) return;
    await ref.read(_provider.notifier).pickCustomer(picked.companyId);
  }

  Future<void> _photo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked != null) ref.read(_provider.notifier).setPhoto(picked.path);
  }

  Future<void> _pickTargets(CollectionDraft draft) async {
    final dues = draft.dues;
    if (dues == null) return;
    final l10n = context.l10n;
    final fmt = context.fmt;
    final targets = {for (final item in draft.targets) item.key};
    final picked = await showSrSheet<List<DueItem>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<DueItem>(
        title: l10n.salesApplyTo,
        options: dues.items,
        labelOf: (item) =>
            '${item.invoiceNumber ?? item.orderNumber} · ${l10n.instalment(item.instalment)}',
        subtitleOf: (item) =>
            '${fmt.money(item.due)} · ${fmt.dayMonth(item.instalment.dueDate)}',
        isSelected: (item) => targets.contains(item.key),
      ),
    );
    if (picked == null) return;
    ref
        .read(_provider.notifier)
        .setTargets(
          picked.isEmpty || picked.length == dues.items.length
              ? null
              : {for (final item in picked) item.key},
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    ref
      ..listen(_provider.select((s) => s.value?.dues?.companyId), (_, _) {
        final amount = ref.read(_provider).value?.amount ?? 0;
        _amount.text = amount > 0 ? '$amount' : '';
      })
      ..listen(_provider.select((s) => s.value?.submission), (previous, next) {
        if (previous == next) return;
        switch (next) {
          case AsyncData(:final value):
            showSrSuccess(context, l10n.salesCollectionSaved);
            context.pushReplacement(Routes.receiptFor(value.id));
          case AsyncError(:final error):
            showSalesFailure(context, error);
          default:
            break;
        }
      });
    final draft = state.value;
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    return SrScaffold(
      appBar: SrAppBar(title: l10n.salesCollection),
      body: SrAsyncView<CollectionDraft>(
        value: state,
        onRetry: () => ref.invalidate(_provider),
        onUpgrade: upgradeFor(context, state.error),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, draft) => SrKeyboardDismiss(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              14,
              SrMetrics.gutter,
              32,
            ),
            children: [
              _CustomerCard(draft: draft, onTap: _pickCustomer),
              if (draft.dues != null) ...[
                const SizedBox(height: 14),
                _AmountField(
                  controller: _amount,
                  draft: draft,
                  onChanged: (value) => ref
                      .read(_provider.notifier)
                      .setAmount(int.tryParse(value) ?? 0),
                ),
                const SizedBox(height: 14),
                CollectionMethodFields(
                  easy: easy,
                  draft: draft,
                  form: ref.read(_provider.notifier),
                  failure: switch (draft.submission) {
                    AsyncError(error: final ApiFailure failure) => failure,
                    _ => null,
                  },
                ),
                const SizedBox(height: 12),
                _ApplyTo(
                  draft: draft,
                  onChange: easy ? null : () => _pickTargets(draft),
                ),
                const SizedBox(height: 12),
                _PhotoButton(
                  draft: draft,
                  onTake: _photo,
                  onRemove: () => ref.read(_provider.notifier).setPhoto(null),
                ),
              ],
            ],
          ),
        ),
      ),
      footer: draft == null || draft.dues == null
          ? null
          : SrButton(
              label: l10n.salesSaveAndSendReceipt,
              expand: true,
              loading: draft.isSaving,
              onPressed: draft.isSaving || draft.amount <= 0
                  ? null
                  : ref.read(_provider.notifier).save,
            ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.draft, required this.onTap});

  final CollectionDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final dues = draft.dues;
    if (dues == null) {
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
          subtitle: l10n.salesPickDebtorHint,
          chevron: true,
        ),
      );
    }
    return SrCard(
      padding: EdgeInsets.zero,
      child: SrListRow(
        leading: SrAvatar(name: dues.companyName),
        title: dues.companyName,
        subtitle: dues.items.isEmpty
            ? l10n.salesNothingDue
            : l10n.salesDueSummary(
                fmt.money(dues.due),
                fmt.number(dues.items.length),
              ),
        chevron: true,
        onTap: onTap,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.draft,
    required this.onChanged,
  });

  final TextEditingController controller;
  final CollectionDraft draft;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final failure = draft.submission?.error;
    return SrTextField(
      controller: controller,
      label: l10n.salesAmount,
      prefix: Text(l10n.salesTaka, style: AppText.metric(c.ink2, size: 20)),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      helper: draft.amount > 0 ? context.fmt.money(draft.amount) : null,
      error: failure is ApiFailure && failure.fieldError('Amount') != null
          ? l10n.salesEnterAmount
          : null,
      onChanged: onChanged,
    );
  }
}

class _ApplyTo extends StatelessWidget {
  const _ApplyTo({required this.draft, required this.onChange});

  final CollectionDraft draft;

  /// Null keeps the oldest-first allocation, as the Easy level does.
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final allocations = draft.allocations;
    final left = draft.unallocated;
    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.salesApplyTo, style: AppText.rowTitle(c.ink)),
              ),
              if (onChange != null && (draft.dues?.items.isNotEmpty ?? false))
                SrStagePill(label: l10n.salesChange, onTap: onChange),
            ],
          ),
          const SizedBox(height: 4),
          if (allocations.isEmpty)
            Text(l10n.salesNothingToApply, style: AppText.meta(c.ink2))
          else
            for (final a in allocations)
              Text(
                '${a.invoiceNumber ?? a.orderNumber} · ${l10n.salesInstalmentOf(l10n.ordinal(a.seq))} · ${fmt.money(a.amount)}',
                style: AppText.meta(c.ink2),
              ),
          if (draft.selected == null && allocations.isNotEmpty)
            Text(l10n.salesOldestFirst, style: AppText.meta(c.ink3, size: 12)),
          if (left > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.salesUnallocated(fmt.money(left)),
              style: AppText.meta(c.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.draft,
    required this.onTake,
    required this.onRemove,
  });

  final CollectionDraft draft;
  final VoidCallback onTake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cheque = draft.method == PaymentMethod.cheque;
    final label = cheque ? l10n.salesPhotoOfCheque : l10n.salesPhotoOfSlip;
    if (draft.photoPath == null) {
      return SrButton(
        label: label,
        icon: Icons.photo_camera_outlined,
        variant: SrButtonVariant.secondary,
        size: SrButtonSize.sm,
        onPressed: onTake,
      );
    }
    return SrListRow(
      padding: EdgeInsets.zero,
      leading: const SrAvatar(
        icon: Icons.check_rounded,
        tone: SrAvatarTone.accent,
      ),
      title: l10n.salesPhotoAdded,
      subtitle: label,
      trailing: SrIconButton(
        icon: Icons.close_rounded,
        compact: true,
        tooltip: l10n.commonDelete,
        onTap: onRemove,
      ),
    );
  }
}
