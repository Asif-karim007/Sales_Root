import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/tasks/models/scanned_card.dart';
import 'package:salesroot/features/tasks/providers/scan_providers.dart';
import 'package:salesroot/features/tasks/view/widget/card_frame.dart';
import 'package:salesroot/features/tasks/view/widget/scan_empty.dart';
import 'package:salesroot/features/tasks/view/widget/tasks_language_toggle.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #40 `scanreview`: the fields read off the card, editable, with the ones
/// the reader was unsure of marked "Check".
class ScanReviewScreen extends ConsumerWidget {
  const ScanReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final capture = ref.watch(scanSessionProvider).value;
    final card = capture?.card;
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.tasksReviewTitle,
          actions: const [TasksLanguageToggle()],
        ),
        body: capture == null || card == null
            ? const ScanEmpty()
            : _Review(capture: capture, card: card),
      ),
    );
  }
}

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.capture, required this.card});

  final ScanCapture capture;
  final ScannedCard card;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  late final Map<CardField, TextEditingController> _fields = {
    for (final field in CardField.values)
      field: TextEditingController(text: widget.card.valueOf(field)),
  };
  bool _missingName = false;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScannedCard? _edited() {
    final card = widget.card.edited({
      for (final entry in _fields.entries) entry.key: entry.value.text,
    });
    final missing = card.contactName.isEmpty && card.companyName.isEmpty;
    setState(() => _missingName = missing);
    if (missing) return null;
    ref.read(scanSessionProvider.notifier).edit(card);
    return card;
  }

  void _saveContact() {
    final card = _edited();
    if (card == null) return;
    context.push(
      Uri(
        path: Routes.contactNew,
        queryParameters: {
          'name': ?_nonEmpty(card.contactName),
          'phone': ?_nonEmpty(card.phone),
          'email': ?_nonEmpty(card.email),
          'company': ?_nonEmpty(card.companyName),
          'designation': ?_nonEmpty(card.designation),
        },
      ).toString(),
    );
  }

  void _createLead() {
    if (_edited() != null) context.push(Routes.scanLead);
  }

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = widget.card;
    final canContact = ref
        .watch(moduleAccessProvider(AppModule.contact))
        .canAdd;
    final canLead = ref.watch(moduleAccessProvider(AppModule.lead)).canAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              16,
              SrMetrics.gutter,
              24,
            ),
            children: [
              CardFrame(
                height: 120,
                child: Image.memory(widget.capture.image, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              SrNote(
                icon: Icons.auto_awesome_outlined,
                message: l10n.tasksReviewFilled(
                  context.fmt.number(card.filledCount),
                ),
              ),
              if (card.unsure.isNotEmpty) ...[
                const SizedBox(height: 8),
                SrNote(
                  tone: SrNoteTone.gold,
                  icon: Icons.visibility_outlined,
                  message: l10n.tasksReviewUnsure,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(CardField.contactName)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(CardField.designation)),
                ],
              ),
              _field(CardField.companyName),
              _field(CardField.phone),
              _field(CardField.email),
              _field(CardField.address),
            ],
          ),
        ),
        if (canContact || canLead)
          SrFooter(
            child: Row(
              children: [
                if (canContact)
                  Expanded(
                    child: SrButton(
                      label: l10n.tasksSaveContactOnly,
                      variant: SrButtonVariant.secondary,
                      expand: true,
                      onPressed: _saveContact,
                    ),
                  ),
                if (canContact && canLead) const SizedBox(width: 10),
                if (canLead)
                  Expanded(
                    child: SrButton(
                      label: l10n.tasksCreateLead,
                      expand: true,
                      onPressed: _createLead,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _field(CardField field) {
    final controller = _fields[field];
    if (controller == null) return const SizedBox.shrink();
    return _ReviewField(
      field: field,
      controller: controller,
      unsure: widget.card.unsure.contains(field),
      error: _missingName && field == CardField.contactName
          ? context.l10n.commonRequired
          : null,
    );
  }
}

class _ReviewField extends ConsumerWidget {
  const _ReviewField({
    required this.field,
    required this.controller,
    required this.unsure,
    this.error,
  });

  final CardField field;
  final TextEditingController controller;
  final bool unsure;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = switch (field) {
      CardField.contactName => l10n.tasksFieldName,
      CardField.designation => l10n.tasksFieldDesignation,
      CardField.companyName => l10n.tasksFieldCompany,
      CardField.phone => l10n.tasksFieldMobile,
      CardField.email => l10n.tasksFieldEmail,
      CardField.address => l10n.tasksFieldAddress,
    };
    final company = field == CardField.companyName && controller.text.isNotEmpty
        ? ref.watch(scannedCompanyMatchProvider(controller.text))
        : null;
    final known = company?.value;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SrFieldLabel(label)),
              if (unsure)
                SrTag(
                  l10n.tasksCheckField,
                  tone: SrTone.warn,
                  icon: Icons.error_outline_rounded,
                ),
              if (company != null && company.hasValue)
                SrTag(
                  known == null
                      ? l10n.tasksCompanyNew
                      : l10n.tasksCompanyExisting,
                  tone: known == null ? SrTone.ok : SrTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 6),
          SrTextField(
            controller: controller,
            error: error,
            prefixIcon: switch (field) {
              CardField.phone => Icons.phone_outlined,
              CardField.email => Icons.mail_outline_rounded,
              CardField.address => Icons.place_outlined,
              _ => null,
            },
            keyboardType: switch (field) {
              CardField.phone => TextInputType.phone,
              CardField.email => TextInputType.emailAddress,
              _ => TextInputType.text,
            },
            textCapitalization: field == CardField.email
                ? TextCapitalization.none
                : TextCapitalization.words,
          ),
        ],
      ),
    );
  }
}
