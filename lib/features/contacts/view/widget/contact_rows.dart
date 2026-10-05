import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/view/widget/contact_launcher.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A contact in a list: who, where they work, and quick call / WhatsApp.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    this.divider = false,
    this.subtitle,
    this.trailing,
  });

  final Contact contact;
  final bool divider;

  /// Replaces the company · designation line.
  final String? subtitle;

  /// Replaces the call and WhatsApp buttons.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = contact.phone;
    final where = contact.isIndependent
        ? [l10n.contactsIndependent]
        : [?contact.companyName, ?contact.designation];

    return SrListRow(
      title: contact.name,
      subtitle: subtitle ?? where.join(' · '),
      leading: SrAvatar(name: contact.name),
      divider: divider,
      chevron: true,
      onTap: () => context.push(Routes.contactFor(contact.id)),
      trailing:
          trailing ?? (phone == null ? null : _QuickActions(phone: phone)),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SrIconButton(
          icon: Icons.call_outlined,
          compact: true,
          color: c.accent,
          tooltip: l10n.commonCall,
          onTap: () => ContactLauncher.call(context, phone),
        ),
        SrIconButton(
          icon: Icons.chat_outlined,
          compact: true,
          color: c.accent,
          tooltip: l10n.contactsWhatsApp,
          onTap: () => ContactLauncher.whatsApp(context, phone),
        ),
      ],
    );
  }
}

/// A company in a list: industry, area, people and leads, and a customer tag.
class CompanyRow extends StatelessWidget {
  const CompanyRow({super.key, required this.company, this.divider = false});

  final Company company;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final parts = [
      ?company.area,
      l10n.contactsContactCount(
        company.contactCount,
        fmt.number(company.contactCount),
      ),
      if (company.openLeadCount > 0)
        l10n.contactsLeadCount(
          company.openLeadCount,
          fmt.number(company.openLeadCount),
        ),
    ];

    return SrListRow(
      title: company.name,
      subtitle: parts.join(' · '),
      leading: SrAvatar(name: company.name, square: true),
      divider: divider,
      chevron: true,
      onTap: () => context.push(Routes.companyFor(company.id)),
      trailing: company.isClient
          ? SrTag(l10n.contactsCustomer, tone: SrTone.ok)
          : null,
    );
  }
}

extension LeadStatusLabel on LeadStatus {
  String label(AppLocalizations l10n) => switch (this) {
    LeadStatus.open => l10n.contactsLeadOpen,
    LeadStatus.won => l10n.contactsLeadWon,
    LeadStatus.lost => l10n.contactsLeadLost,
  };

  SrTone get tone => switch (this) {
    LeadStatus.open => SrTone.accent,
    LeadStatus.won => SrTone.ok,
    LeadStatus.lost => SrTone.neutral,
  };
}

/// A lead of a contact or company: stage, value and status; opens the lead
/// when the user may see leads.
class LinkedLeadRow extends ConsumerWidget {
  const LinkedLeadRow({super.key, required this.lead});

  final LinkedLead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canOpen = ref.watch(moduleAccessProvider(AppModule.lead)).canView;
    final parts = [lead.stage.of(fmt.isBangla), fmt.moneyCompact(lead.value)];

    return SrListRow(
      title: lead.title,
      subtitle: parts.join(' · '),
      leading: SrAvatar(name: lead.title, tone: SrAvatarTone.accent),
      chevron: canOpen,
      onTap: canOpen ? () => context.push(Routes.leadFor(lead.id)) : null,
      trailing: SrTag(lead.status.label(l10n), tone: lead.status.tone),
    );
  }
}
