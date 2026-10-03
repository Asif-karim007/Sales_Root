import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/signature_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #58: delivery or service completion: what went out, proof, and who took
/// it; optionally makes the bill at once.
class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _receivedBy = TextEditingController();
  final _note = TextEditingController();
  bool _seeded = false;

  DeliveryFormProvider get _provider => deliveryFormProvider(widget.orderId);

  @override
  void dispose() {
    _receivedBy.dispose();
    _note.dispose();
    super.dispose();
  }

  void _seed(DeliveryDraft draft) {
    if (_seeded) return;
    _seeded = true;
    _receivedBy.text = draft.receivedBy;
    _note.text = draft.note;
  }

  Future<void> _photo() async {
    final l10n = context.l10n;
    final source = await showSrSheet<ImageSource>(
      context: context,
      builder: (_) => SrOptionSheet<ImageSource>(
        title: l10n.salesAddPhoto,
        options: const [ImageSource.camera, ImageSource.gallery],
        labelOf: (s) => s == ImageSource.camera
            ? l10n.salesTakePhoto
            : l10n.salesFromGallery,
        isSelected: (_) => false,
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null) return;
    ref.read(_provider.notifier).addPhoto(picked.path);
  }

  Future<void> _sign() async {
    final png = await showSignatureSheet(context);
    if (png != null) ref.read(_provider.notifier).setSignature(png);
  }

  Future<void> _pickTime(DateTime current) async {
    final picked = await showSrDatePicker(
      context: context,
      initial: current,
      withTime: true,
      last: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) ref.read(_provider.notifier).setDeliveredAt(picked);
  }

  void _saved(SalesOrder order) {
    final l10n = context.l10n;
    final invoiceId = order.invoiceId;
    showSrSuccess(context, l10n.salesDeliverySaved);
    if (invoiceId != null && order.status == OrderStatus.invoiced) {
      context.pushReplacement(Routes.invoiceFor(invoiceId));
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
            receivedBy: _receivedBy,
            note: _note,
            onPhoto: _photo,
            onSign: _sign,
            onTime: () => _pickTime(draft.deliveredAt),
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
    required this.receivedBy,
    required this.note,
    required this.onPhoto,
    required this.onSign,
    required this.onTime,
  });

  final DeliveryDraft draft;
  final TextEditingController receivedBy;
  final TextEditingController note;
  final VoidCallback onPhoto;
  final VoidCallback onSign;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final form = ref.read(deliveryFormProvider(draft.order.id).notifier);
    final order = draft.order;
    final canBill =
        order.invoiceId == null &&
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
                  value: draft.delivered.contains(line.productId),
                  onChanged: (_) => form.toggleItem(line.productId),
                ),
                title: line.nameIn(bangla: fmt.isBangla),
                subtitle: '${fmt.qty(line.qty)} ${l10n.unit(line.unit)}',
                onTap: () => form.toggleItem(line.productId),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SrPickerField(
          label: l10n.salesDateTime,
          icon: Icons.event_outlined,
          value:
              '${fmt.date(draft.deliveredAt)} · ${fmt.time(draft.deliveredAt)}',
          onTap: onTime,
        ),
        const SizedBox(height: 14),
        SrFieldLabel(l10n.salesPhotoOrSignature),
        const SizedBox(height: 6),
        _ProofTiles(draft: draft, onPhoto: onPhoto, onSign: onSign),
        if (draft.photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          _PhotoStrip(photos: draft.photos, onRemove: form.removePhoto),
        ],
        const SizedBox(height: 14),
        SrTextField(
          controller: receivedBy,
          label: l10n.salesReceivedBy,
          textCapitalization: TextCapitalization.words,
          onChanged: form.setReceivedBy,
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

class _ProofTiles extends StatelessWidget {
  const _ProofTiles({
    required this.draft,
    required this.onPhoto,
    required this.onSign,
  });

  final DeliveryDraft draft;
  final VoidCallback onPhoto;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signature = draft.signature;
    return Row(
      children: [
        Expanded(
          child: _DashedTile(
            onTap: onPhoto,
            child: _TileLabel(
              icon: Icons.photo_camera_outlined,
              label: draft.photos.isEmpty
                  ? l10n.salesTakePhoto
                  : l10n.salesPhotoCount(
                      context.fmt.number(draft.photos.length),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DashedTile(
            onTap: onSign,
            child: signature == null
                ? _TileLabel(
                    icon: Icons.draw_outlined,
                    label: l10n.salesSignature,
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.memory(signature, fit: BoxFit.contain),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DashedTile extends StatelessWidget {
  const _DashedTile({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SrCard(
      tone: SrCardTone.dashed,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(height: 90, child: Center(child: child)),
    );
  }
}

class _TileLabel extends StatelessWidget {
  const _TileLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c.accent),
        const SizedBox(height: 6),
        Text(label, style: AppText.caption(c.ink, size: 12)),
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onRemove});

  final List<String> photos;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
              child: Image.file(
                File(photos[i]),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                cacheWidth: 216,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SrIconButton(
                icon: Icons.close_rounded,
                compact: true,
                onDark: true,
                tooltip: l10n.commonDelete,
                onTap: () => onRemove(photos[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
