import 'package:salesroot/features/support/models/app_destination.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/models/lesson.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/l10n/l10n.dart';

extension SupportLabels on AppLocalizations {
  String destination(AppDestination destination) => switch (destination) {
    AppDestination.addLead => supportGoAddLead,
    AppDestination.leadVoice => supportGoLeadVoice,
    AppDestination.leads => supportGoLeads,
    AppDestination.logCall => supportGoLogCall,
    AppDestination.scanCard => supportGoScanCard,
    AppDestination.newTask => supportGoNewTask,
    AppDestination.newVisit => supportGoNewVisit,
    AppDestination.attendance => supportGoAttendance,
    AppDestination.newQuotation => supportGoNewQuotation,
    AppDestination.newCollection => supportGoNewCollection,
    AppDestination.outstanding => supportGoOutstanding,
    AppDestination.inviteMember => supportGoInviteMember,
    AppDestination.teamChat => supportGoTeamChat,
    AppDestination.offlineSync => supportGoOfflineSync,
    AppDestination.language => supportGoLanguage,
    AppDestination.security => supportGoSecurity,
    AppDestination.plan => supportGoPlan,
    AppDestination.dataSafety => supportGoDataSafety,
    AppDestination.support => supportGoSupport,
    AppDestination.help => supportGoHelp,
    AppDestination.academy => supportGoAcademy,
  };

  String helpCategory(HelpCategory category) => switch (category) {
    HelpCategory.gettingStarted => supportHelpCatStart,
    HelpCategory.leads => supportHelpCatLeads,
    HelpCategory.tasks => supportHelpCatTasks,
    HelpCategory.fieldWork => supportHelpCatField,
    HelpCategory.sales => supportHelpCatSales,
    HelpCategory.team => supportHelpCatTeam,
    HelpCategory.account => supportHelpCatAccount,
  };

  String ticketCategory(TicketCategory category) => switch (category) {
    TicketCategory.question => supportTicketCatQuestion,
    TicketCategory.bug => supportTicketCatBug,
    TicketCategory.billing => supportTicketCatBilling,
    TicketCategory.data => supportTicketCatData,
    TicketCategory.suggestion => supportTicketCatSuggestion,
  };

  String ticketStatus(TicketStatus status) => switch (status) {
    TicketStatus.open => supportTicketStatusOpen,
    TicketStatus.replied => supportTicketStatusReplied,
    TicketStatus.resolved => supportTicketStatusResolved,
  };

  String replyChannel(ReplyChannel channel) => switch (channel) {
    ReplyChannel.inApp => supportChannelInApp,
    ReplyChannel.inAppSms => supportChannelInAppSms,
    ReplyChannel.phone => supportChannelPhone,
  };

  String feedbackArea(FeedbackArea area) => switch (area) {
    FeedbackArea.addingLeads => supportFeedbackAreaLeads,
    FeedbackArea.scanning => supportFeedbackAreaScan,
    FeedbackArea.chat => supportFeedbackAreaChat,
    FeedbackArea.reports => supportFeedbackAreaReports,
    FeedbackArea.payment => supportFeedbackAreaPayment,
    FeedbackArea.nothing => supportFeedbackAreaNothing,
  };

  String feedbackRating(FeedbackRating rating) => switch (rating) {
    FeedbackRating.awful => supportRatingAwful,
    FeedbackRating.poor => supportRatingPoor,
    FeedbackRating.okay => supportRatingOkay,
    FeedbackRating.good => supportRatingGood,
    FeedbackRating.love => supportRatingLove,
  };

  String surveyScore(SurveyScore score) => switch (score) {
    SurveyScore.hard => supportSurveyHard,
    SurveyScore.okay => supportSurveyOkay,
    SurveyScore.easy => supportSurveyEasy,
  };

  String enquiryKind(EnquiryKind kind) => switch (kind) {
    EnquiryKind.customSoftware => supportEnquiryKindCustom,
    EnquiryKind.website => supportEnquiryKindWebsite,
    EnquiryKind.erp => supportEnquiryKindErp,
    EnquiryKind.demo => supportEnquiryKindDemo,
  };

  String callWindow(CallWindow window) => switch (window) {
    CallWindow.morning => supportEnquiryTimeMorning,
    CallWindow.midday => supportEnquiryTimeMidday,
    CallWindow.afternoon => supportEnquiryTimeAfternoon,
    CallWindow.evening => supportEnquiryTimeEvening,
  };

  String lessonCategory(LessonCategory category) => switch (category) {
    LessonCategory.coldCalling => supportAcademyCatCold,
    LessonCategory.closing => supportAcademyCatClosing,
    LessonCategory.followUp => supportAcademyCatFollowUp,
    LessonCategory.career => supportAcademyCatCareer,
  };
}
