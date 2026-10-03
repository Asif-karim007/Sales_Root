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
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #45: one contact with quick actions, their company, leads and activity.
class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.contactsDeleteContactTitle,
      message: l10n.contactsDeleteContactBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(contactMutationProvider(id).notifier).delete();
  }

  void _menu(BuildContext context, WidgetRef ref, Contact contact) {
    final l10n = context.l10n;
    final access = ref.read(moduleAccessProvider(AppModule.contact));
    showActionSheet(
      context,
      title: contact.name,
      actions: [
        if (access.canEdit && contact.canEdit)
          SheetAction(
            icon: Icons.edit_outlined,
            label: l10n.commonEdit,
            onTap: () => context.push(ContactsPaths.contactEditFor(id)),
          ),
        if (access.canDelete && contact.canDelete)
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
    final contact = ref.watch(contactProvider(id));
    final access = ref.watch(moduleAccessProvider(AppModule.contact));
    final loaded = contact.value;
    final hasMenu =
        loaded != null &&
        ((access.canEdit && loaded.canEdit) ||
            (access.canDelete && loaded.canDelete));

    ref.listen(contactMutationProvider(id), (_, next) {
      if (next.value == RecordChange.deleted) {
        showSrSuccess(context, l10n.contactsDeleted);
        context.pop();
      } else if (next.error case final error?) {
        showFailure(context, error);
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        actions: [
          const ContactsLanguageToggle(),
          if (hasMenu)
            SrIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _menu(context, ref, loaded),
            ),
        ],
      ),
      body: SrAsyncView<Contact>(
        value: contact,
        onRetry: () => ref.invalidate(contactProvider(id)),
        data: (context, contact) => _Body(contact: contact),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final companyId = contact.companyId;
    final subtitle = [?contact.designation, ?contact.companyName].join(' · ');

    return RefreshIndicator(
      color: SrColors.of(context).accent,
      onRefresh: () {
        ref
          ..invalidate(contactLeadsProvider(contact.id))
          ..invalidate(contactActivityProvider(contact.id));
        return ref.refresh(contactProvider(contact.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DetailHero(
            name: contact.name,
            subtitle: subtitle,
            tags: [
              if (contact.isPrimary)
                SrTag(l10n.contactsPrimaryContact, tone: SrTone.accent),
              if (contact.isIndependent) SrTag(l10n.contactsIndependent),
              for (final tag in contact.tags) SrTag(tag),
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
                _QuickTiles(contact: contact),
                InfoLines(lines: _lines(context, contact, fmt, l10n)),
                if (contact.note case final note? when note.isNotEmpty)
                  SrNote(message: note, icon: Icons.sticky_note_2_outlined),
                if (companyId != null) _CompanySection(contact: contact),
                _LeadsSection(contact: contact),
                _ActivitySection(id: contact.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InfoLine> _lines(
    BuildContext context,
    Contact contact,
    AppFormat fmt,
    AppLocalizations l10n,
  ) {
    final birthday = contact.dateOfBirth;
    final created = contact.createdOn;
    return [
      for (final phone in contact.mobiles)
        InfoLine(
          l10n.contactsMobile,
          fmt.phone(BdPhone.display(phone)),
          onTap: () => ContactLauncher.call(context, phone),
        ),
      for (final email in contact.emails)
        InfoLine(
          l10n.contactsEmail,
          email,
          onTap: () => ContactLauncher.email(context, email),
        ),
      if (contact.designation case final designation?)
        InfoLine(l10n.contactsDesignation, designation),
      if (contact.address case final address?)
        InfoLine(l10n.contactsAddress, address),
      if (birthday != null)
        InfoLine(l10n.contactsBirthday, fmt.dayMonth(birthday)),
      if (contact.source case final source?)
        InfoLine(l10n.contactsSource, source),
      if (created != null) InfoLine(l10n.contactsAddedOn, fmt.date(created)),
    ];
  }
}

class _QuickTiles extends StatelessWidget {
  const _QuickTiles({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = contact.phone;
    final email = contact.email;
    return ActionTiles(
      tiles: [
        ActionTileData(
          icon: Icons.call_outlined,
          label: l10n.commonCall,
          onTap: phone == null
              ? null
              : () => ContactLauncher.call(context, phone),
        ),
        ActionTileData(
          icon: Icons.chat_outlined,
          label: l10n.contactsWhatsApp,
          onTap: phone == null
              ? null
              : () => ContactLauncher.whatsApp(context, phone),
        ),
        ActionTileData(
          icon: Icons.sms_outlined,
          label: l10n.contactsSms,
          onTap: phone == null
              ? null
              : () => ContactLauncher.sms(context, phone),
        ),
        ActionTileData(
          icon: Icons.mail_outline_rounded,
          label: l10n.contactsEmail,
          onTap: email == null
              ? null
              : () => ContactLauncher.email(context, email),
        ),
      ],
    );
  }
}

class _CompanySection extends ConsumerWidget {
  const _CompanySection({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final companyId = contact.companyId;
    if (companyId == null) return const SizedBox.shrink();
    final canOpen = ref.watch(moduleAccessProvider(AppModule.company)).canView;
    final company = canOpen
        ? ref.watch(companyProvider(companyId)).value
        : null;
    final people = company?.contactCount;
    final role = contact.isPrimary
        ? l10n.contactsPrimaryContact
        : contact.designation;

    return SrRowGroup(
      title: l10n.contactsCompany,
      rows: [
        SrListRow(
          title: company?.name ?? contact.companyName ?? '',
          subtitle: [
            ?role,
            if (people != null)
              l10n.contactsPeopleCount(people, fmt.number(people)),
          ].join(' · '),
          leading: SrAvatar(
            name: company?.name ?? contact.companyName,
            square: true,
          ),
          chevron: canOpen,
          onTap: canOpen
              ? () => context.push(Routes.companyFor(companyId))
              : null,
          trailing: contact.companyIsClient
              ? SrTag(l10n.contactsCustomer, tone: SrTone.ok)
              : null,
        ),
      ],
    );
  }
}

class _LeadsSection extends ConsumerWidget {
  const _LeadsSection({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final leads = ref.watch(contactLeadsProvider(contact.id));
    final lead = ref.watch(moduleAccessProvider(AppModule.lead));
    final companyId = contact.companyId;
    final count = leads.value?.length;
    final newLead = Uri(
      path: Routes.leadQuick,
      queryParameters: {
        if (companyId != null) 'companyId': '$companyId',
        'contactId': '${contact.id}',
      },
    ).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SrSectionHeader(
          title: count == null
              ? l10n.contactsLeadsWithContact
              : l10n.contactsLeadsWithContactCount(fmt.number(count)),
          actionLabel: lead.canAdd ? l10n.contactsNewLead : null,
          onAction: lead.canAdd ? () => context.push(newLead) : null,
        ),
        switch (leads) {
          AsyncValue(:final value?) when value.isEmpty => SectionEmpty(
            l10n.contactsNoLeads,
          ),
          AsyncValue(:final value?) => SrRowGroup(
            rows: [for (final item in value) LinkedLeadRow(lead: item)],
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(contactLeadsProvider(contact.id)),
          ),
          _ => const SrSkeletonCard(),
        },
      ],
    );
  }
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activity = ref.watch(contactActivityProvider(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SrSectionHeader(title: l10n.contactsActivity),
        switch (activity) {
          AsyncValue(:final value?) when value.isEmpty => SectionEmpty(
            l10n.contactsNoActivity,
          ),
          AsyncValue(:final value?) => SrCard(
            child: Column(
              children: [
                for (var i = 0; i < value.length; i++)
                  _ActivityItem(
                    activity: value[i],
                    last: i == value.length - 1,
                  ),
              ],
            ),
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(contactActivityProvider(id)),
          ),
          _ => const SrSkeletonCard(),
        },
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity, required this.last});

  final ContactActivity activity;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final minutes = activity.durationMinutes;
    final (icon, label) = switch (activity.type) {
      ActivityType.call => (Icons.call_outlined, l10n.commonCall),
      ActivityType.whatsApp => (Icons.chat_outlined, l10n.contactsWhatsApp),
      ActivityType.sms => (Icons.sms_outlined, l10n.contactsSms),
      ActivityType.email => (Icons.mail_outline_rounded, l10n.contactsEmail),
      ActivityType.visit => (Icons.place_outlined, l10n.contactsVisit),
      ActivityType.note => (Icons.sticky_note_2_outlined, l10n.contactsNote),
    };
    final by = activity.byName;

    return SrTimelineItem(
      icon: icon,
      title: minutes == null
          ? label
          : '$label · ${l10n.contactsMinutes(fmt.number(minutes))}',
      time: '${fmt.dayMonth(activity.on)} ${fmt.time(activity.on)}',
      subtitle: [?activity.note, ?by].join(' · '),
      last: last,
    );
  }
}
