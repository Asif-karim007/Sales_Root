import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/contacts/contacts_paths.dart';
import 'package:salesroot/features/contacts/view/companies_screen.dart';
import 'package:salesroot/features/contacts/view/company_detail_screen.dart';
import 'package:salesroot/features/contacts/view/company_form_screen.dart';
import 'package:salesroot/features/contacts/view/contact_detail_screen.dart';
import 'package:salesroot/features/contacts/view/contact_form_screen.dart';
import 'package:salesroot/features/contacts/view/contact_import_screen.dart';
import 'package:salesroot/features/contacts/view/contacts_screen.dart';
import 'package:salesroot/features/contacts/view/customer_360_screen.dart';
import 'package:salesroot/features/contacts/view/customer_documents_screen.dart';

String? _query(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key]?.trim();
  return value == null || value.isEmpty ? null : value;
}

final List<RouteBase> contactsRoutes = [
  GoRoute(
    path: Routes.contacts,
    redirect: requireAccess(AppModule.contact),
    builder: (context, state) => const ContactsScreen(),
  ),
  GoRoute(
    path: Routes.contactsImport,
    redirect: requireAccess(AppModule.contact, ModuleRight.add),
    builder: (context, state) => const ContactImportScreen(),
  ),
  GoRoute(
    path: Routes.contactNew,
    redirect: requireAccess(AppModule.contact, ModuleRight.add),
    builder: (context, state) => ContactFormScreen(
      prefill: ContactPrefill(
        companyId: _query(state, 'companyId'),
        name: _query(state, 'name'),
        phone: _query(state, 'phone'),
        email: _query(state, 'email'),
      ),
    ),
  ),
  GoRoute(
    path: ContactsPaths.contactEdit,
    redirect: requireAccess(AppModule.contact, ModuleRight.edit),
    builder: (context, state) => ContactFormScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.contact,
    redirect: requireAccess(AppModule.contact),
    builder: (context, state) => ContactDetailScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.companies,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) => const CompaniesScreen(),
  ),
  GoRoute(
    path: Routes.companyNew,
    redirect: requireAccess(AppModule.company, ModuleRight.add),
    builder: (context, state) => CompanyFormScreen(name: _query(state, 'name')),
  ),
  GoRoute(
    path: ContactsPaths.companyEdit,
    redirect: requireAccess(AppModule.company, ModuleRight.edit),
    builder: (context, state) => CompanyFormScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.company,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) => CompanyDetailScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.customer,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) => Customer360Screen(companyId: idParam(state)),
  ),
  GoRoute(
    path: Routes.customerDocuments,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) =>
        CustomerDocumentsScreen(companyId: idParam(state)),
  ),
];
