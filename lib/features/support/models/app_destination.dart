import 'package:salesroot/core/routing/routes.dart';

/// A place in the app that help articles, lessons and the guide link to. The
/// server sends the [wire] name; the app owns the route.
enum AppDestination {
  addLead('AddLead'),
  leadVoice('LeadVoice'),
  leads('Leads'),
  logCall('LogCall'),
  scanCard('ScanCard'),
  newTask('NewTask'),
  newVisit('NewVisit'),
  attendance('Attendance'),
  newQuotation('NewQuotation'),
  newCollection('NewCollection'),
  outstanding('Outstanding'),
  inviteMember('InviteMember'),
  teamChat('TeamChat'),
  offlineSync('OfflineSync'),
  language('Language'),
  security('Security'),
  plan('Plan'),
  dataSafety('DataSafety'),
  support('Support'),
  help('Help'),
  academy('Academy');

  const AppDestination(this.wire);

  final String wire;

  static AppDestination? fromWire(String? value) {
    for (final destination in values) {
      if (destination.wire == value) return destination;
    }
    return null;
  }

  String get path => switch (this) {
    addLead => Routes.leadNew,
    leadVoice => Routes.leadVoice,
    leads => Routes.leads,
    logCall => '${Routes.leads}?pick=call',
    scanCard => Routes.scan,
    newTask => Routes.taskNew,
    newVisit => '${Routes.visits}?new=1',
    attendance => Routes.attendance,
    newQuotation => Routes.quotationNew,
    newCollection => Routes.collectionNew,
    outstanding => Routes.outstanding,
    inviteMember => Routes.teamInvite,
    teamChat => Routes.chats,
    offlineSync => Routes.sync,
    language => Routes.settingsLanguage,
    security => Routes.settingsSecurity,
    plan => Routes.planUsage,
    dataSafety => Routes.dataSafety,
    support => Routes.supportNew,
    help => Routes.help,
    academy => Routes.academy,
  };

  /// [path] with [params] added to its query.
  String location([Map<String, String> params = const {}]) {
    if (params.isEmpty) return path;
    final uri = Uri.parse(path);
    return uri
        .replace(queryParameters: {...uri.queryParameters, ...params})
        .toString();
  }
}
