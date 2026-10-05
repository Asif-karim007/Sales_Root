import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/call_outcome_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/lead_launcher.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #29: the lead's company and contacts, and the other details.
class LeadLinksScreen extends ConsumerWidget {
  const LeadLinksScreen({super.key, required this.id});

  static const _slot = 'links';

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(leadProvider(id));
    final locale = ref.watch(appLocaleProvider);
    ref.listen(leadSaveProvider(_slot), (_, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        showSrError(context, leadFailureText(l10n, next.error ?? ''));
      } else if (next.value != null) {
        showSrSuccess(context, l10n.leadsCompanyChanged);
      }
    });
    return LeadCallWatcher(
      child: SrScaffold(
        appBar: SrAppBar(
          title: value.value?.leadName ?? l10n.leadsDetailTitle,
          subtitle: l10n.leadsLinksSubtitle,
          actions: [
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
          ],
        ),
        body: SrAsyncView(
          value: value,
          onRetry: () => ref.invalidate(leadProvider(id)),
          data: (context, lead) => _Body(lead: lead),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.lead});

  final Lead lead;

  Future<void> _changeCompany(BuildContext context, WidgetRef ref) async {
    final save = ref.read(leadSaveProvider(LeadLinksScreen._slot).notifier);
    final repository = ref.read(leadRepositoryProvider);
    final picked = await showSrSheet<LeadLookupCompany>(
      context: context,
      builder: (context) => SrSearchSheet<LeadLookupCompany>(
        title: context.l10n.leadsCompany,
        search: repository.companies,
        labelOf: (c) => c.name,
        subtitleOf: (c) => c.area,
        withAvatar: true,
        isSelected: (c) => c.id == lead.company?.id,
      ),
    );
    if (picked == null || picked.id == lead.company?.id) return;
    await save.edit(lead, LeadInput.fromLead(lead).withCompany(picked.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editable = ref.watch(moduleAccessProvider(AppModule.lead)).canEdit;
    final canAddContact = ref
        .watch(moduleAccessProvider(AppModule.contact))
        .canAdd;
    final companyId = lead.company?.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        SrSectionHeader(
          title: l10n.leadsCompany,
          actionLabel: editable ? l10n.leadsChange : null,
          onAction: editable ? () => _changeCompany(context, ref) : null,
        ),
        const SizedBox(height: 8),
        _CompanyCard(
          lead: lead,
          onLink: editable ? () => _changeCompany(context, ref) : null,
        ),
        const SizedBox(height: 18),
        SrSectionHeader(
          title: l10n.leadsContactsOnLead,
          actionLabel: canAddContact ? l10n.commonAdd : null,
          onAction: canAddContact
              ? () => context.push(
                  companyId == null
                      ? Routes.contactNew
                      : '${Routes.contactNew}?companyId=$companyId',
                )
              : null,
        ),
        const SizedBox(height: 8),
        _Contacts(lead: lead),
        const SizedBox(height: 14),
        SrNote(message: l10n.leadsLinksNote),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.leadsOtherDetails),
        const SizedBox(height: 8),
        _Details(lead: lead),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.lead, this.onLink});

  final Lead lead;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final company = lead.company;
    if (company == null) {
      return SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: SrListRow(
          title: l10n.leadsNoCompanyLinked,
          subtitle: onLink == null ? null : l10n.leadsLinkCompany,
          leading: const SrAvatar(icon: Icons.apartment_rounded),
          onTap: onLink,
        ),
      );
    }
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: SrListRow(
        title: company.name,
        leading: SrAvatar(name: company.name),
        trailing: SrTag(l10n.leadsCompanyTag),
        chevron: true,
        onTap: () => context.push(Routes.companyFor(company.id)),
      ),
    );
  }
}

class _Contacts extends ConsumerWidget {
  const _Contacts({required this.lead});

  final Lead lead;

  Future<void> _call(
    BuildContext context,
    WidgetRef ref,
    LeadContact contact,
    String phone,
  ) async {
    final l10n = context.l10n;
    final pending = ref.read(pendingCallProvider.notifier)
      ..start(
        PendingCall(
          leadId: lead.id,
          contactName: contact.name,
          startedAt: DateTime.now(),
        ),
      );
    if (await LeadLauncher.call(phone) || !context.mounted) return;
    pending.take();
    showSrError(context, l10n.leadsLaunchFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final contact = lead.contact;
    final phone = lead.phone;
    if (contact == null) {
      return SrCard(
        child: Text(l10n.leadsNoContactsLinked, style: AppText.meta(c.ink2)),
      );
    }
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: SrListRow(
        title: contact.name,
        subtitle: phone == null ? null : context.fmt.phone(phone),
        leading: SrAvatar(name: contact.name),
        trailing: phone == null
            ? null
            : SrIconButton(
                icon: Icons.call_outlined,
                compact: true,
                color: c.accent,
                tooltip: l10n.commonCall,
                onTap: () => _call(context, ref, contact, phone),
              ),
        onTap: () => context.push(Routes.contactFor(contact.id)),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final bangla = fmt.isBangla;
    final fields = ref.watch(leadLookupsProvider).value?.fields ?? const [];
    final created = lead.createdOn;
    final lines = [
      (l10n.leadsLeadTitle, lead.title),
      for (final field in fields)
        (field.label.of(bangla), lead.customText(field.key)),
      (l10n.leadsSource, leadSourceLabel(l10n, lead.source)),
      (l10n.leadsOwner, lead.assignedTo?.name.of(bangla)),
      (l10n.leadsTags, lead.tags.isEmpty ? null : lead.tags.join(', ')),
      (l10n.leadsCreated, created == null ? null : fmt.date(created)),
    ];
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final (i, (label, value)) in lines.indexed)
            _Line(
              label: label,
              value: value ?? l10n.leadsNone,
              divider: i < lines.length - 1,
            ),
        ],
      ),
    );
  }
}

/// The prototype's `.line`: a label on the left, a bold value on the right.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.divider,
  });

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.line)) : null,
      ),
      child: Row(
        children: [
          Text(label, style: AppText.body(c.ink2, size: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.rowTitle(c.ink, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
