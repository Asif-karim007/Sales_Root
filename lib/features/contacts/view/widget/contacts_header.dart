import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The language pill every contacts screen carries.
class ContactsLanguageToggle extends ConsumerWidget {
  const ContactsLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return SrLanguageToggle(
      isBangla: locale == bangla,
      onChanged: (toBangla) =>
          ref.read(appLocaleProvider.notifier).set(toBangla ? bangla : english),
    );
  }
}

/// The header of the contacts and companies lists: title, count, search and
/// add, over the Contacts | Companies switch.
class ContactsHeader extends ConsumerWidget {
  const ContactsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.companies,
    this.onAdd,
  });

  final String title;
  final String? subtitle;

  /// Whether the Companies side of the switch is the current one.
  final bool companies;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final subtitle = this.subtitle;
    final onAdd = this.onAdd;
    final other = companies ? AppModule.contact : AppModule.company;
    final canSwitch = ref.watch(moduleAccessProvider(other)).visible;

    return SrHeader(
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop()) ...[
              SrIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.commonBack,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.pageTitle(c.ink, size: 22)),
                  if (subtitle != null)
                    Text(subtitle, style: AppText.meta(c.ink2)),
                ],
              ),
            ),
            const ContactsLanguageToggle(),
            const SizedBox(width: 8),
            SrIconButton(
              icon: Icons.search_rounded,
              tooltip: l10n.commonSearch,
              onTap: () => context.push(Routes.search),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 8),
              SrIconButton(
                icon: Icons.add_rounded,
                tooltip: l10n.commonAdd,
                onTap: onAdd,
              ),
            ],
          ],
        ),
        if (canSwitch)
          SrSegmented(
            segments: [
              SrSegment(l10n.contactsTabContacts),
              SrSegment(l10n.contactsTabCompanies),
            ],
            index: companies ? 1 : 0,
            onChanged: (index) {
              if ((index == 1) == companies) return;
              context.replace(index == 1 ? Routes.companies : Routes.contacts);
            },
          ),
      ],
    );
  }
}
