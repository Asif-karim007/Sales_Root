import 'package:salesroot/core/access/experience_level.dart';

enum AddOn {
  fieldForce('fieldforce'),
  growth('growth');

  const AddOn(this.wire);

  final String wire;

  static AddOn? fromWire(String? value) {
    for (final addOn in values) {
      if (addOn.wire == value) return addOn;
    }
    return null;
  }
}

/// A part of the app the server grants per role. [addOn] is the plan add-on
/// it needs; [minLevel] is the experience level that shows it in menus.
enum AppModule {
  lead('Lead'),
  contact('Contact'),
  company('Company'),
  task('Task'),
  calendar('Calendar'),
  cardScan('CardScan'),
  product('Product', minLevel: ExperienceLevel.standard),
  quotation('Quotation', minLevel: ExperienceLevel.standard),
  order('Order', minLevel: ExperienceLevel.standard),
  invoice('Invoice', minLevel: ExperienceLevel.standard),
  collection('Collection'),
  team('Team'),
  chat('Chat'),
  chatOversight('ChatOversight'),
  files('Files'),
  reports('Reports', minLevel: ExperienceLevel.standard),
  pipelines('Pipelines', minLevel: ExperienceLevel.advanced),
  formFields('FormFields', minLevel: ExperienceLevel.advanced),
  dataImport('DataImport', minLevel: ExperienceLevel.advanced),
  billing('Billing'),
  referral('Referral'),
  visit('Visit', addOn: AddOn.fieldForce),
  liveTracking('LiveTracking', addOn: AddOn.fieldForce),
  attendance('Attendance', addOn: AddOn.fieldForce),
  teamAttendance('TeamAttendance', addOn: AddOn.fieldForce),
  leadSources('LeadSources', addOn: AddOn.growth),
  inbox('Inbox', addOn: AddOn.growth),
  campaign('Campaign', addOn: AddOn.growth),
  distribution(
    'Distribution',
    addOn: AddOn.growth,
    minLevel: ExperienceLevel.advanced,
  ),
  notice('Notice'),
  leave('Leave'),
  expense('Expense'),
  approvals('Approvals'),
  payroll('Payroll'),
  support('Support'),
  ownerDashboard('OwnerDashboard');

  const AppModule(
    this.wire, {
    this.addOn,
    this.minLevel = ExperienceLevel.easy,
  });

  final String wire;
  final AddOn? addOn;
  final ExperienceLevel minLevel;

  static AppModule? fromWire(String? value) {
    for (final module in values) {
      if (module.wire == value) return module;
    }
    return null;
  }
}
