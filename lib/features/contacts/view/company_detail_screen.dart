import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/contacts_paths.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_launcher.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_sheets.dart';
import 'package:salesroot/features/contacts/view/widget/detail_parts.dart';
import 'package:salesroot/features/contacts/view/widget/info_lines.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #47: a company with its concern persons, leads, address and money.
class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.contactsDeleteCompanyTitle,
      message: l10n.contactsDeleteCompanyBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(companyMutationProvider(id).notifier).delete();
  }

  void _menu(BuildContext context, WidgetRef ref, Company company) {
    final l10n = context.l10n;
    final access = ref.read(moduleAccessProvider(AppModule.company));
    showActionSheet(
      context,
      title: company.name,
      actions: [
        if (access.canEdit && company.canEdit)
          SheetAction(
            icon: Icons.edit_outlined,
            label: l10n.commonEdit,
            onTap: () => context.push(ContactsPaths.companyEditFor(id)),
          ),
        SheetAction(
          icon: Icons.insights_outlined,
          label: l10n.contactsCustomer360,
          onTap: () => context.push(Routes.customerFor(id)),
        ),
        SheetAction(
          icon: Icons.folder_open_outlined,
          label: l10n.contactsDocuments,
          onTap: () => context.push(Routes.customerDocumentsFor(id)),
        ),
        if (access.canDelete && company.canDelete)
          SheetAction(
            icon: Icons.delete_outline_rounded,
            label: l10n.commonDelete,
            destructive: true,
            onTap: () => _delete(context, ref),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final company = ref.watch(companyProvider(id));
    final loaded = company.value;

    ref.listen(companyMutationProvider(id), (_, next) {
      switch (next) {
        case AsyncData(value: RecordChange.deleted):
          showSrSuccess(context, l10n.contactsCompanyDeleted);
          context.pop();
        case AsyncData(value: RecordChange.primarySet):
          showSrSuccess(context, l10n.contactsPrimarySet);
        case AsyncData(value: RecordChange.detached):
          showSrSuccess(context, l10n.contactsDetached);
        case AsyncError(:final error):
          showFailure(context, error);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        actions: [
          const ContactsLanguageToggle(),
          if (loaded != null)
            SrIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _menu(context, ref, loaded),
            ),
        ],
      ),
      footer: loaded == null ? null : _Footer(company: loaded),
      body: SrAsyncView<Company>(
        value: company,
        onRetry: () => ref.invalidate(companyProvider(id)),
        data: (context, company) => _Body(company: company),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final since = company.clientSince;
    final subtitle = [
      ?company.industry(fmt.isBangla),
      ?company.area(fmt.isBangla),
      if (since != null)
        l10n.contactsCustomerSince(fmt.digits('${since.year}')),
    ].join(' · ');
    final industry = company.industry(fmt.isBangla);

    return RefreshIndicator(
      color: c.accent,
      onRefresh: () {
        ref
          ..invalidate(companyContactsProvider(company.id))
          ..invalidate(companyLeadsProvider(company.id));
        return ref.refresh(companyProvider(company.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DetailHero(
            name: company.name,
            subtitle: subtitle,
            company: true,
            tags: [
              if (company.isClient)
                SrTag(l10n.contactsCustomer, tone: SrTone.ok),
              if (industry != null) SrTag(industry),
              for (final tag in company.tags) SrTag(tag),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              16,
              SrMetrics.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                KpiStrip(
                  cells: [
                    KpiCell(
                      l10n.contactsTotalSales,
                      fmt.moneyCompact(company.totalSales),
                    ),
                    KpiCell(
                      l10n.contactsOutstanding,
                      fmt.moneyCompact(company.outstanding),
                      color: company.outstanding > 0 ? c.danger : null,
                    ),
                    KpiCell(
                      l10n.contactsOpenLeads,
                      fmt.number(company.openLeadCount),
                    ),
                  ],
                ),
                _PeopleSection(company: company),
                _LeadsSection(company: company),
                InfoLines(lines: _lines(context, fmt, l10n)),
                if (company.note case final note? when note.isNotEmpty)
                  SrNote(message: note, icon: Icons.sticky_note_2_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InfoLine> _lines(
    BuildContext context,
    AppFormat fmt,
    AppLocalizations l10n,
  ) {
    final address = company.address;
    final phone = company.contactNumber;
    final website = company.websiteProspect;
    final email = company.email;
    final limit = company.creditLimit;
    final days = company.creditDays;
    return [
      if (company.industry(fmt.isBangla) case final industry?)
        InfoLine(l10n.contactsIndustry, industry),
      if (address != null || company.hasLocation)
        InfoLine(
          l10n.contactsAddress,
          address ?? company.area(fmt.isBangla) ?? l10n.contactsOpenMap,
          onTap: () => ContactLauncher.map(
            context,
            label: company.name,
            address: address,
            latitude: company.latitude,
            longitude: company.longitude,
          ),
        ),
      if (phone != null)
        InfoLine(
          l10n.contactsPhone,
          fmt.phone(BdPhone.display(phone)),
          onTap: () => ContactLauncher.call(context, phone),
        ),
      if (email != null)
        InfoLine(
          l10n.contactsEmail,
          email,
          onTap: () => ContactLauncher.email(context, email),
        ),
      if (website != null)
        InfoLine(
          l10n.contactsWebsite,
          website,
          onTap: () => ContactLauncher.website(context, website),
        ),
      if (limit != null)
        InfoLine(
          l10n.contactsCreditLimit,
          days == null
              ? fmt.moneyCompact(limit)
              : l10n.contactsCreditTerms(
                  fmt.moneyCompact(limit),
                  fmt.number(days),
                ),
        ),
      if (company.assignedTo case final owner?)
        InfoLine(l10n.contactsAssignedTo, owner.name),
      if (company.code case final code?) InfoLine(l10n.contactsCode, code),
    ];
  }
}

class _PeopleSection extends ConsumerWidget {
  const _PeopleSection({required this.company});

  final Company company;

  void _personMenu(BuildContext context, WidgetRef ref, Contact person) {
    final l10n = context.l10n;
    final canEdit =
        ref.read(moduleAccessProvider(AppModule.company)).canEdit &&
        company.canEdit;
    final phone = person.phone;
    showActionSheet(
      context,
      title: person.name,
      actions: [
        if (phone != null) ...[
          SheetAction(
            icon: Icons.call_outlined,
            label: l10n.commonCall,
            onTap: () => ContactLauncher.call(context, phone),
          ),
          SheetAction(
            icon: Icons.chat_outlined,
            label: l10n.contactsWhatsApp,
            onTap: () => ContactLauncher.whatsApp(context, phone),
          ),
        ],
        if (canEdit && !person.isPrimary)
          SheetAction(
            icon: Icons.star_outline_rounded,
            label: l10n.contactsSetPrimary,
            onTap: () => ref
                .read(companyMutationProvider(company.id).notifier)
                .setPrimary(person.id),
          ),
        if (canEdit)
          SheetAction(
            icon: Icons.person_remove_outlined,
            label: l10n.contactsRemoveFromCompany,
            destructive: true,
            onTap: () => _detach(context, ref, person),
          ),
      ],
    );
  }

  Future<void> _detach(
    BuildContext context,
    WidgetRef ref,
    Contact person,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.contactsRemoveFromCompanyTitle(person.name),
      message: l10n.contactsRemoveFromCompanyBody,
      confirmLabel: l10n.contactsRemove,
      icon: Icons.person_remove_outlined,
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(companyMutationProvider(company.id).notifier)
        .detach(person.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final people = ref.watch(companyContactsProvider(company.id));
    final canAdd = ref.watch(moduleAccessProvider(AppModule.contact)).canAdd;
    final count = people.value?.length ?? company.contactCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SrSectionHeader(
          title: l10n.contactsConcernPersons(fmt.number(count)),
          actionLabel: canAdd ? l10n.commonAdd : null,
          onAction: canAdd
              ? () =>
                    context.push('${Routes.contactNew}?companyId=${company.id}')
              : null,
        ),
        switch (people) {
          AsyncValue(:final value?) when value.isEmpty => SectionEmpty(
            l10n.contactsNoPeople,
          ),
          AsyncValue(:final value?) => SrRowGroup(
            rows: [
              for (final person in value)
                ContactRow(
                  contact: person,
                  subtitle: [
                    ?person.designation,
                    if (person.isPrimary) l10n.contactsPrimary,
                  ].join(' · '),
                  trailing: SrIconButton(
                    icon: Icons.more_horiz_rounded,
                    compact: true,
                    tooltip: l10n.commonMore,
                    onTap: () => _personMenu(context, ref, person),
                  ),
                ),
            ],
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(companyContactsProvider(company.id)),
          ),
          _ => const SrSkeletonCard(),
        },
      ],
    );
  }
}

class _LeadsSection extends ConsumerWidget {
  const _LeadsSection({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final leads = ref.watch(companyLeadsProvider(company.id));
    final canAdd = ref.watch(moduleAccessProvider(AppModule.lead)).canAdd;
    final count = leads.value?.length ?? company.leadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SrSectionHeader(
          title: l10n.contactsLeadsCount(fmt.number(count)),
          actionLabel: canAdd ? l10n.contactsNewLead : null,
          onAction: canAdd
              ? () =>
                    context.push('${Routes.leadQuick}?companyId=${company.id}')
              : null,
        ),
        switch (leads) {
          AsyncValue(:final value?) when value.isEmpty => SectionEmpty(
            l10n.contactsNoLeads,
          ),
          AsyncValue(:final value?) => SrRowGroup(
            rows: [
              for (final lead in value)
                LinkedLeadRow(lead: lead, showOwner: true),
            ],
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(companyLeadsProvider(company.id)),
          ),
          _ => const SrSkeletonCard(),
        },
      ],
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canQuote = ref
        .watch(moduleAccessProvider(AppModule.quotation))
        .canAdd;
    final openLead = ref
        .watch(companyLeadsProvider(company.id))
        .value
        ?.where((lead) => lead.status == LeadStatus.open)
        .firstOrNull;
    final quotation = openLead == null
        ? Routes.quotationNew
        : '${Routes.quotationNew}?leadId=${openLead.id}';

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: SrButton(
            label: l10n.contactsCustomer360,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => context.push(Routes.customerFor(company.id)),
          ),
        ),
        if (canQuote)
          Expanded(
            child: SrButton(
              label: l10n.contactsQuotation,
              expand: true,
              onPressed: () => context.push(quotation),
            ),
          ),
      ],
    );
  }
}
