import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The Customer 360 timeline: money, documents, talks and visits, newest
/// first; entries for a quotation, order, invoice or receipt open it.
class CustomerTimeline extends ConsumerWidget {
  const CustomerTimeline({super.key, required this.events});

  final List<CustomerEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool can(AppModule module) =>
        ref.watch(moduleAccessProvider(module)).canView;
    final allowed = {
      CustomerEventKind.quotation: can(AppModule.quotation),
      CustomerEventKind.order: can(AppModule.order),
      CustomerEventKind.delivery: can(AppModule.order),
      CustomerEventKind.invoice: can(AppModule.invoice),
      CustomerEventKind.collection: can(AppModule.collection),
    };
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _Entry(
              event: events[i],
              last: i == events.length - 1,
              canOpen: allowed[events[i].kind] ?? false,
            ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.event,
    required this.last,
    required this.canOpen,
  });

  final CustomerEvent event;
  final bool last;
  final bool canOpen;

  String? _route() {
    final id = event.refId;
    if (id == null || !canOpen) return null;
    return switch (event.kind) {
      CustomerEventKind.quotation => Routes.quotationFor(id),
      CustomerEventKind.order ||
      CustomerEventKind.delivery => Routes.orderFor(id),
      CustomerEventKind.invoice => Routes.invoiceFor(id),
      CustomerEventKind.collection => Routes.receiptFor(id),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final amount = event.amount;
    final money = amount == null ? '' : fmt.moneyCompact(amount);
    final number = event.number ?? '';
    final minutes = event.durationMinutes;
    final duration = minutes == null
        ? null
        : l10n.contactsMinutes(fmt.number(minutes));
    final by = event.byName;

    final (icon, color, title, subtitle) = switch (event.kind) {
      CustomerEventKind.collection => (
        Icons.payments_outlined,
        c.success,
        l10n.contactsEventCollection(
          money,
          paymentMethodLabel(l10n, event.method),
        ),
        number.isEmpty ? null : l10n.contactsEventReceipt(number),
      ),
      CustomerEventKind.invoice => (
        Icons.receipt_long_outlined,
        c.accent,
        l10n.contactsEventInvoice(number, money),
        by,
      ),
      CustomerEventKind.quotation => (
        Icons.request_quote_outlined,
        c.accent,
        l10n.contactsEventQuotation(number, money),
        by,
      ),
      CustomerEventKind.order => (
        Icons.inventory_2_outlined,
        c.accent,
        l10n.contactsEventOrder(number, money),
        by,
      ),
      CustomerEventKind.delivery => (
        Icons.local_shipping_outlined,
        c.success,
        l10n.contactsEventDelivered,
        l10n.contactsEventDeliveredBody(number),
      ),
      CustomerEventKind.call => (
        Icons.call_outlined,
        c.ink2,
        [l10n.commonCall, ?duration].join(' · '),
        [?event.note, ?by].join(' · '),
      ),
      CustomerEventKind.whatsApp => (
        Icons.chat_outlined,
        c.ink2,
        l10n.contactsWhatsApp,
        [?event.note, ?by].join(' · '),
      ),
      CustomerEventKind.visit => (
        Icons.place_outlined,
        c.ink2,
        [l10n.contactsVisit, ?event.note, ?duration].join(' · '),
        by,
      ),
      CustomerEventKind.note => (
        Icons.sticky_note_2_outlined,
        c.ink2,
        l10n.contactsNote,
        [?event.note, ?by].join(' · '),
      ),
      CustomerEventKind.document => (
        Icons.description_outlined,
        c.ink2,
        number,
        by,
      ),
    };
    final route = _route();

    return SrTimelineItem(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      time: fmt.dayMonth(event.on),
      last: last,
      onTap: route == null ? null : () => context.push(route),
    );
  }
}

/// The name of a payment method the server sends as a key.
String paymentMethodLabel(AppLocalizations l10n, String? method) =>
    switch (method) {
      'cash' => l10n.contactsMethodCash,
      'bkash' => l10n.contactsMethodBkash,
      'nagad' => l10n.contactsMethodNagad,
      'rocket' => l10n.contactsMethodRocket,
      'bank' => l10n.contactsMethodBank,
      'cheque' => l10n.contactsMethodCheque,
      'card' => l10n.contactsMethodCard,
      _ => method ?? '',
    };
