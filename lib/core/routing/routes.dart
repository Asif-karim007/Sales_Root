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
  static const authEmail = '/auth/email';
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
  static String leadFor(int id) => '/leads/$id';
  static String leadEditFor(int id) => '/leads/$id/edit';
  static String leadLinksFor(int id) => '/leads/$id/links';
  static String leadActivityFor(int id) => '/leads/$id/activity';

  static const taskNew = '/tasks/new';
  static const task = '/tasks/:id';
  static String taskFor(int id) => '/tasks/$id';
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
  static String contactFor(int id) => '/contacts/$id';
  static const companies = '/companies';
  static const companyNew = '/companies/new';
  static const company = '/companies/:id';
  static String companyFor(int id) => '/companies/$id';
  static const customer = '/customers/:id';
  static const customerDocuments = '/customers/:id/documents';
  static String customerFor(int id) => '/customers/$id';
  static String customerDocumentsFor(int id) => '/customers/$id/documents';

  static const products = '/products';
  static const quotations = '/quotations';
  static const quotationNew = '/quotations/new';
  static const quotation = '/quotations/:id';
  static String quotationFor(int id) => '/quotations/$id';
  static const order = '/orders/:id';
  static const orderDelivery = '/orders/:id/delivery';
  static String orderFor(int id) => '/orders/$id';
  static String orderDeliveryFor(int id) => '/orders/$id/delivery';
  static const invoice = '/invoices/:id';
  static String invoiceFor(int id) => '/invoices/$id';
  static const collection = '/collection';
  static const collectionNew = '/collection/new';
  static const receipt = '/receipts/:id';
  static String receiptFor(int id) => '/receipts/$id';
  static const outstanding = '/outstanding';

  static const teamInvite = '/team/invite';
  static const teamInviteSent = '/team/invite/sent';
  static const member = '/team/members/:id';
  static const memberRemove = '/team/members/:id/remove';
  static String memberFor(int id) => '/team/members/$id';
  static String memberRemoveFor(int id) => '/team/members/$id/remove';
  static const organogram = '/team/organogram';
  static const chats = '/chat';
  static const chatNew = '/chat/new';
  static const chatOversight = '/chat/oversight';
  static const chat = '/chat/:id';
  static const chatInfo = '/chat/:id/info';
  static String chatFor(int id) => '/chat/$id';
  static String chatInfoFor(int id) => '/chat/$id/info';
  static const files = '/files';
  static const fileUpload = '/files/upload';
  static const file = '/files/:id';
  static String fileFor(int id) => '/files/$id';

  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsNotifications = '/settings/notifications';
  static const settingsSecurity = '/settings/security';
  static const settingsPipelines = '/settings/pipelines';
  static const settingsFormFields = '/settings/form-fields';
  static const settingsImport = '/settings/import';
  static const sync = '/sync';
  static const syncConflict = '/sync/conflicts/:id';
  static String syncConflictFor(int id) => '/sync/conflicts/$id';
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
  static String helpArticleFor(int id) => '/help/$id';
  static const supportNew = '/support/new';
  static const supportTicket = '/support/:id';
  static String supportTicketFor(int id) => '/support/$id';
  static const aiGuide = '/ai-guide';
  static const dataSafety = '/data-safety';
  static const academy = '/academy';
  static const lesson = '/academy/lessons/:id';
  static String lessonFor(int id) => '/academy/lessons/$id';
  static const career = '/academy/career';
  static const about = '/about';
  static const enquiry = '/enquiry';

  static const visits = '/visits';
  static const visitRoute = '/visits/route';
  static const visitReport = '/visits/report';
  static const visit = '/visits/:id';
  static const visitCheckIn = '/visits/:id/check-in';
  static String visitFor(int id) => '/visits/$id';
  static String visitCheckInFor(int id) => '/visits/$id/check-in';
  static const trackingConsent = '/tracking/consent';
  static const trackingHelp = '/tracking/help';
  static const trackingLive = '/tracking/live';
  static const trackingSettings = '/tracking/settings';
  static const trackingMember = '/tracking/members/:id';
  static String trackingMemberFor(int id) => '/tracking/members/$id';
  static const attendance = '/attendance';
  static const attendanceCalendar = '/attendance/calendar';
  static const attendanceTeam = '/attendance/team';

  static const growthChannels = '/growth/channels';
  static const growthFacebook = '/growth/channels/facebook';
  static const newLeads = '/growth/inbox';
  static const newLead = '/growth/inbox/:id';
  static const newLeadAccept = '/growth/inbox/:id/accept';
  static String newLeadFor(int id) => '/growth/inbox/$id';
  static String newLeadAcceptFor(int id) => '/growth/inbox/$id/accept';
  static const distribution = '/growth/rules';
  static const distributionRule = '/growth/rules/:id';
  static String distributionRuleFor(int id) => '/growth/rules/$id';
  static const messages = '/messages';
  static const messageThread = '/messages/:id';
  static String messageThreadFor(int id) => '/messages/$id';
  static const campaigns = '/campaigns';
  static const campaignSms = '/campaigns/sms/new';
  static const campaignEmail = '/campaigns/email/new';
  static const campaignCredits = '/campaigns/credits';
  static const campaign = '/campaigns/:id';
  static String campaignFor(int id) => '/campaigns/$id';
  static const notices = '/notices';
  static const noticeNew = '/notices/new';
  static const notice = '/notices/:id';
  static String noticeFor(int id) => '/notices/$id';

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
      location.startsWith('/invite/') ||
      location.startsWith('/r/');

  /// Signed-in routes that continue onboarding.
  static bool isOnboarding(String location) =>
      location.startsWith('/onboarding/') || location.startsWith('/invite/');

  static String noAccessFor(String module, {bool planLocked = false}) => Uri(
    path: noAccess,
    queryParameters: {'module': module, if (planLocked) 'plan': '1'},
  ).toString();
}
