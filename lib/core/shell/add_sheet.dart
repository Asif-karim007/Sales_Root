import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The centre ＋ sheet (#17). Offers only what the user may add.
class AddSheet extends ConsumerWidget {
  const AddSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showSrSheet<void>(context: context, builder: (_) => const AddSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      for (final action in _AddAction.values)
        if (ref.watch(moduleAccessProvider(action.module)).offersAdd) action,
    ];
    return SrSheet(
      title: context.l10n.addSheetTitle,
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: [
          for (final action in actions)
            _AddTile(
              action: action,
              onTap: () {
                Navigator.of(context).pop();
                context.push(action.location);
              },
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.action, required this.onTap});

  final _AddAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SrAvatar(
            icon: action.icon,
            square: true,
            tone: SrAvatarTone.accent,
            size: 46,
          ),
          const SizedBox(height: 6),
          Text(
            action.label(context.l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.caption(c.ink, size: 12),
          ),
        ],
      ),
    );
  }
}

/// Call logs and notes are logged against a lead, so they open the lead
/// list in pick mode (`?pick=call|note`).
enum _AddAction {
  lead(AppModule.lead, Icons.person_add_alt_1_rounded, Routes.leadQuick),
  contact(AppModule.contact, Icons.contact_phone_outlined, Routes.contactNew),
  company(AppModule.company, Icons.apartment_rounded, Routes.companyNew),
  callLog(AppModule.lead, Icons.call_outlined, '${Routes.leads}?pick=call'),
  visit(AppModule.visit, Icons.place_outlined, '${Routes.visits}?new=1'),
  task(AppModule.task, Icons.task_alt_rounded, Routes.taskNew),
  note(
    AppModule.lead,
    Icons.sticky_note_2_outlined,
    '${Routes.leads}?pick=note',
  ),
  quotation(
    AppModule.quotation,
    Icons.request_quote_outlined,
    Routes.quotationNew,
  ),
  collection(
    AppModule.collection,
    Icons.payments_outlined,
    Routes.collectionNew,
  ),
  scanCard(AppModule.cardScan, Icons.document_scanner_outlined, Routes.scan),
  voice(AppModule.lead, Icons.mic_none_rounded, Routes.leadVoice),
  expense(AppModule.expense, Icons.receipt_long_outlined, Routes.expenseNew);

  const _AddAction(this.module, this.icon, this.location);

  final AppModule module;
  final IconData icon;
  final String location;

  String label(AppLocalizations l10n) => switch (this) {
    lead => l10n.addLead,
    contact => l10n.addContact,
    company => l10n.addCompany,
    callLog => l10n.addCallLog,
    visit => l10n.addVisit,
    task => l10n.addTask,
    note => l10n.addNote,
    quotation => l10n.addQuotation,
    collection => l10n.addCollection,
    scanCard => l10n.addScanCard,
    voice => l10n.addByVoice,
    expense => l10n.addExpense,
  };
}

extension on ModuleAccess {
  bool get offersAdd => visible && canAdd;
}
