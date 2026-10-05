import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/translations/translations.dart';

/// What the workspace's industry pack calls a company, such as "Outlet".
String companyTerm(BuildContext context, WidgetRef ref) =>
    ref
        .watch(contactsPackProvider)
        .value
        ?.companyTerm
        ?.of(context.fmt.isBangla) ??
    context.l10n.contactsCompany;

/// What the workspace's industry pack calls a contact, such as "Shop owner".
String contactTerm(BuildContext context, WidgetRef ref) =>
    ref
        .watch(contactsPackProvider)
        .value
        ?.contactTerm
        ?.of(context.fmt.isBangla) ??
    context.l10n.contactsContact;
