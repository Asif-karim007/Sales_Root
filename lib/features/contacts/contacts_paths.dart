/// Edit routes the contacts feature adds next to the shared core routes.
abstract final class ContactsPaths {
  static const contactEdit = '/contacts/:id/edit';
  static const companyEdit = '/companies/:id/edit';
  static String contactEditFor(String id) => '/contacts/$id/edit';
  static String companyEditFor(String id) => '/companies/$id/edit';
}
