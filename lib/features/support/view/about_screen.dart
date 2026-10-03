import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/support_links.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #117 about Nexzen, its products and services, and the app version.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static String _enquiry(EnquiryKind kind) => Uri(
    path: Routes.enquiry,
    queryParameters: {'kind': kind.wire},
  ).toString();

  Future<void> _openSaleBee(BuildContext context) async {
    final failed = context.l10n.supportCantOpen;
    if (await openExternal(Uri.parse(SupportLinks.saleBee)) ||
        !context.mounted) {
      return;
    }
    showSrError(context, failed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final package = ref.watch(packageInfoProvider).value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportAboutTitle,
        actions: const [SupportLanguagePill()],
      ),
      footer: SrButton(
        label: l10n.supportAboutTalk,
        icon: Icons.chat_bubble_outline_rounded,
        expand: true,
        onPressed: () => context.push(Routes.enquiry),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SrMetrics.gutter),
        children: [
          const _CompanyCard(),
          const SizedBox(height: 20),
          SrRowGroup(
            title: l10n.supportAboutProducts,
            rows: [
              SrListRow(
                title: SupportLinks.saleBeeName,
                subtitle: l10n.supportAboutSaleBee,
                leading: const _Badge(SupportLinks.saleBeeInitials),
                chevron: true,
                onTap: () => _openSaleBee(context),
              ),
              SrListRow(
                title: SupportLinks.erpName,
                subtitle: l10n.supportAboutErp,
                leading: const _Badge(SupportLinks.erpInitials),
                chevron: true,
                onTap: () => context.push(_enquiry(EnquiryKind.erp)),
              ),
              SrListRow(
                title: SupportLinks.salesRootName,
                subtitle: l10n.supportAboutSalesRoot,
                leading: const _Badge(SupportLinks.salesRootInitials),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SrRowGroup(
            title: l10n.supportAboutServices,
            rows: [
              SrListRow(
                title: l10n.supportAboutCustom,
                subtitle: l10n.supportAboutCustomSub,
                leading: const SrAvatar(
                  icon: Icons.code_rounded,
                  tone: SrAvatarTone.gold,
                ),
                chevron: true,
                onTap: () => context.push(_enquiry(EnquiryKind.customSoftware)),
              ),
              SrListRow(
                title: l10n.supportAboutWebsite,
                subtitle: l10n.supportAboutWebsiteSub,
                leading: const SrAvatar(
                  icon: Icons.language_rounded,
                  tone: SrAvatarTone.gold,
                ),
                chevron: true,
                onTap: () => context.push(_enquiry(EnquiryKind.website)),
              ),
            ],
          ),
          if (package != null) ...[
            const SizedBox(height: 20),
            Text(
              l10n.supportAboutVersion(
                context.fmt.digits(package.version),
                context.fmt.digits(package.buildNumber),
              ),
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _Badge(SupportLinks.companyInitials, dark: true, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SupportLinks.company,
                      style: AppText.rowTitle(c.ink, size: 16),
                    ),
                    Text(l10n.supportAboutWhere, style: AppText.meta(c.ink2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l10n.supportAboutBody, style: AppText.lead(c.ink, size: 13)),
        ],
      ),
    );
  }
}

/// A rounded square with a product's initials.
class _Badge extends StatelessWidget {
  const _Badge(this.initials, {this.dark = false, this.size = 38});

  final String initials;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? c.deep : c.tint,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Text(
        initials,
        style: AppText.caption(dark ? c.onDeep : c.accent, size: size / 3.5),
      ),
    );
  }
}
