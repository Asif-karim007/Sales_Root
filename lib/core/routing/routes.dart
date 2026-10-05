/// Every route in the app. Paths are lowercase kebab-case; screens link to
/// each other only through these.
abstract final class Routes {
  static const splash = '/splash';
  static const unlock = '/unlock';
  static const noAccess = '/no-access';

  static const welcome = '/welcome';
  static const authPhone = '/auth/phone';
  static const authCode = '/auth/code';
  static const authPin = '/auth/pin';
  static const authProfile = '/auth/profile';
  static const authIndustry = '/auth/industry';
  static const tour = '/onboarding/tour';
  static const features = '/onboarding/features';
  static const createTeam = '/onboarding/create-team';
  static const acceptInvite = '/invite/:code';
  static const referralSignup = '/r/:code';
  static String acceptInviteFor(String code) => '/invite/$code';
  static String referralSignupFor(String code) => '/r/$code';

  static const home = '/home';
  static const leads = '/leads';
  static const tasks = '/tasks';
  static const sales = '/sales';
  static const team = '/team';
  static const more = '/more';

  static const notifications = '/notifications';
  static const search = '/search';

  static const leadBoard = '/leads/board';
  static const leadNew = '/leads/new';
  static const leadQuick = '/leads/quick';
  static const leadVoice = '/leads/voice';
  static const lead = '/leads/:id';
  static const leadEdit = '/leads/:id/edit';
  static const leadLinks = '/leads/:id/links';
  static const leadActivity = '/leads/:id/activity';
  static String leadFor(String id) => '/leads/$id';
  static String leadEditFor(String id) => '/leads/$id/edit';
  static String leadLinksFor(String id) => '/leads/$id/links';
  static String leadActivityFor(String id) => '/leads/$id/activity';

  static const taskNew = '/tasks/new';
  static const task = '/tasks/:id';
  static String taskFor(String id) => '/tasks/$id';
  static const calendar = '/calendar';
  static const calendarEventNew = '/calendar/event/new';
  static const scan = '/scan';
  static const scanReview = '/scan/review';
  static const scanLead = '/scan/lead';
  static const scanQr = '/scan/qr';

  static const contacts = '/contacts';
  static const contactsImport = '/contacts/import';
  static const contactNew = '/contacts/new';
  static const contact = '/contacts/:id';
  static String contactFor(String id) => '/contacts/$id';
  static const companies = '/companies';
  static const companyNew = '/companies/new';
  static const company = '/companies/:id';
  static String companyFor(String id) => '/companies/$id';
  static const customer = '/customers/:id';
  static const customerDocuments = '/customers/:id/documents';
  static String customerFor(String id) => '/customers/$id';
  static String customerDocumentsFor(String id) => '/customers/$id/documents';

  static const products = '/products';
  static const quotations = '/quotations';
  static const quotationNew = '/quotations/new';
  static const quotation = '/quotations/:id';
  static String quotationFor(String id) => '/quotations/$id';
  static const order = '/orders/:id';
  static const orderDelivery = '/orders/:id/delivery';
  static String orderFor(String id) => '/orders/$id';
  static String orderDeliveryFor(String id) => '/orders/$id/delivery';
  static const invoice = '/invoices/:id';
  static String invoiceFor(String id) => '/invoices/$id';
  static const collection = '/collection';
  static const collectionNew = '/collection/new';
  static const receipt = '/receipts/:id';
  static String receiptFor(String id) => '/receipts/$id';
  static const outstanding = '/outstanding';

  static const teamInvite = '/team/invite';
  static const teamInviteSent = '/team/invite/sent';
  static const member = '/team/members/:id';
  static const memberRemove = '/team/members/:id/remove';
  static String memberFor(String id) => '/team/members/$id';
  static String memberRemoveFor(String id) => '/team/members/$id/remove';
  static const organogram = '/team/organogram';
  static const chats = '/chat';
  static const chatNew = '/chat/new';
  static const chatOversight = '/chat/oversight';
  static const chat = '/chat/:id';
  static const chatInfo = '/chat/:id/info';
  static String chatFor(String id) => '/chat/$id';
  static String chatInfoFor(String id) => '/chat/$id/info';
  static const files = '/files';
  static const fileUpload = '/files/upload';
  static const file = '/files/:id';
  static String fileFor(String id) => '/files/$id';

  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsNotifications = '/settings/notifications';
  static const settingsSecurity = '/settings/security';
  static const settingsPipelines = '/settings/pipelines';
  static const settingsFormFields = '/settings/form-fields';
  static const settingsImport = '/settings/import';
  static const sync = '/sync';
  static const syncConflict = '/sync/conflicts/:id';
  static String syncConflictFor(String id) => '/sync/conflicts/$id';
  static const reports = '/reports';
  static const reportSales = '/reports/sales';

  static const planUsage = '/billing/plan';
  static const planCompare = '/billing/compare';
  static const planChoose = '/billing/choose';
  static const checkout = '/billing/checkout';
  static const planActivated = '/billing/activated';
  static const addOns = '/billing/add-ons';
  static const addOnsLater = '/billing/add-ons/later';
  static const billingHistory = '/billing/history';
  static const refer = '/refer';
  static const referInvite = '/refer/invite';
  static const referList = '/refer/list';
  static const referWallet = '/refer/wallet';
  static const referQr = '/refer/qr';

  static const feedback = '/feedback';
  static const help = '/help';
  static const helpArticle = '/help/:id';
  static String helpArticleFor(String id) => '/help/$id';
  static const supportNew = '/support/new';
  static const supportTicket = '/support/:id';
  static String supportTicketFor(String id) => '/support/$id';
  static const aiGuide = '/ai-guide';
  static const dataSafety = '/data-safety';
  static const academy = '/academy';
  static const lesson = '/academy/lessons/:id';
  static String lessonFor(String id) => '/academy/lessons/$id';
  static const career = '/academy/career';
  static const about = '/about';
  static const enquiry = '/enquiry';

  static const visits = '/visits';
  static const visitRoute = '/visits/route';
  static const visitReport = '/visits/report';
  static const visit = '/visits/:id';
  static const visitCheckIn = '/visits/:id/check-in';
  static String visitFor(String id) => '/visits/$id';
  static String visitCheckInFor(String id) => '/visits/$id/check-in';
  static const trackingConsent = '/tracking/consent';
  static const trackingHelp = '/tracking/help';
  static const trackingLive = '/tracking/live';
  static const trackingSettings = '/tracking/settings';
  static const trackingMember = '/tracking/members/:id';
  static String trackingMemberFor(String id) => '/tracking/members/$id';
  static const attendance = '/attendance';
  static const attendanceCalendar = '/attendance/calendar';
  static const attendanceTeam = '/attendance/team';

  static const growthChannels = '/growth/channels';
  static const growthFacebook = '/growth/channels/facebook';
  static const newLeads = '/growth/inbox';
  static const newLead = '/growth/inbox/:id';
  static const newLeadAccept = '/growth/inbox/:id/accept';
  static String newLeadFor(String id) => '/growth/inbox/$id';
  static String newLeadAcceptFor(String id) => '/growth/inbox/$id/accept';
  static const distribution = '/growth/rules';
  static const distributionRule = '/growth/rules/:id';
  static String distributionRuleFor(String id) => '/growth/rules/$id';
  static const messages = '/messages';
  static const messageThread = '/messages/:id';
  static String messageThreadFor(String id) => '/messages/$id';
  static const campaigns = '/campaigns';
  static const campaignSms = '/campaigns/sms/new';
  static const campaignEmail = '/campaigns/email/new';
  static const campaignCredits = '/campaigns/credits';
  static const campaign = '/campaigns/:id';
  static String campaignFor(String id) => '/campaigns/$id';
  static const notices = '/notices';
  static const noticeNew = '/notices/new';
  static const notice = '/notices/:id';
  static String noticeFor(String id) => '/notices/$id';

  static const leave = '/leave';
  static const leaveNew = '/leave/new';
  static const expenses = '/expenses';
  static const expenseNew = '/expenses/new';
  static const approvals = '/approvals';
  static const payslip = '/payslip';
  static const ticketNew = '/tickets/new';
  static const employeeCard = '/employee-card';

  static const dev = '/dev';
  static const devGallery = '/dev/gallery';

  /// Reachable while signed out.
  static bool isPublic(String location) =>
      location == welcome ||
      location.startsWith('/auth/') ||
      location.startsWith('/onboarding/') ||
      location.startsWith('/invite/') ||
      location.startsWith('/r/');

  /// Routes that stay open after sign-in, so sign-up can continue into them:
  /// go to [tour] first, then call `signIn`.
  static bool isOnboarding(String location) =>
      location.startsWith('/onboarding/') || location.startsWith('/invite/');

  static String noAccessFor(String module, {bool planLocked = false}) => Uri(
    path: noAccess,
    queryParameters: {'module': module, if (planLocked) 'plan': '1'},
  ).toString();
}
