import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/features/growth/data/inbox_fixtures.dart';

const growthChannelsTable = 'growth_channels';
const growthFacebookTable = 'growth_facebook';
const growthFacebookPagesTable = 'growth_facebook_pages';
const growthFacebookFormsTable = 'growth_facebook_forms';

const _pageName = 'Dhaka Sales BD';

List<Map<String, dynamic>> channelFixtures(SeedGraph graph) {
  final random = graph.random('growth_channels');
  return [
    {
      'Id': 1,
      'Kind': 'Facebook',
      'Status': 'Connected',
      'Account': _pageName,
      'FormCount': 2,
      'LeadCount': 155,
      'LeadsThisWeek': 18 + random.nextInt(10),
    },
    {
      'Id': 2,
      'Kind': 'WhatsApp',
      'Status': 'Connected',
      'Account': '+8801711000000',
      'LeadCount': 48,
      'LeadsThisWeek': 6 + random.nextInt(5),
    },
    {
      'Id': 3,
      'Kind': 'Messenger',
      'Status': 'Connected',
      'Account': _pageName,
      'LeadCount': 22,
      'LeadsThisWeek': 2 + random.nextInt(4),
    },
    {
      'Id': 4,
      'Kind': 'Website',
      'Status': 'Available',
      'Account': 'dhakasales.com/contact',
      'EmbedCode':
          '<script src="https://q.salesrootcrm.com/w/dhakasales.js" async></script>',
    },
    {
      'Id': 5,
      'Kind': 'HostedForm',
      'Status': 'Available',
      'Account': 'q.salesrootcrm.com/f/dhakasales',
      'ShareUrl': 'https://q.salesrootcrm.com/f/dhakasales',
    },
    {
      'Id': 6,
      'Kind': 'Email',
      'Status': 'Available',
      'Account': 'sales@dhakasales.com',
    },
    {'Id': 7, 'Kind': 'LinkedIn', 'Status': 'Soon'},
    {'Id': 8, 'Kind': 'GoogleAds', 'Status': 'Soon'},
  ];
}

/// The Pages the signed-in Facebook account manages.
List<Map<String, dynamic>> facebookPageFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'Name': _pageName,
    'AdminName': 'Mohammad Kamal',
    'TokenOk': true,
    'Followers': 18400,
  },
  {
    'Id': 2,
    'Name': 'Dhaka Sales Solar Care',
    'AdminName': 'Mohammad Kamal',
    'TokenOk': true,
    'Followers': 3200,
  },
  {
    'Id': 3,
    'Name': 'Rooftop Solar Bangladesh',
    'AdminName': 'Rafiqul Islam',
    'TokenOk': true,
    'Followers': 940,
  },
];

List<Map<String, dynamic>> facebookFormFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'PageId': 1,
    'Name': solarForm,
    'Campaign': solarCampaign,
    'LeadCount': 124,
    'Enabled': true,
    'Fields': ['full_name', 'phone_number', 'city', 'roof_size'],
  },
  {
    'Id': 2,
    'PageId': 1,
    'Name': dealerForm,
    'LeadCount': 31,
    'Enabled': true,
    'Fields': ['full_name', 'phone_number', 'business_name', 'city'],
  },
  {
    'Id': 3,
    'PageId': 1,
    'Name': 'Old form – 2025',
    'LeadCount': 212,
    'Enabled': false,
    'Fields': ['full_name', 'phone_number', 'email'],
  },
  {
    'Id': 4,
    'PageId': 2,
    'Name': 'Panel cleaning booking',
    'Campaign': 'CleanDec',
    'LeadCount': 46,
    'Enabled': false,
    'Fields': ['full_name', 'phone_number', 'city', 'panel_count'],
  },
  {
    'Id': 5,
    'PageId': 3,
    'Name': 'Free site survey',
    'Campaign': 'SurveyFree',
    'LeadCount': 18,
    'Enabled': false,
    'Fields': ['full_name', 'phone_number', 'city', 'monthly_bill', 'message'],
  },
];

List<Map<String, dynamic>> facebookSetupFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'PageId': 1,
    'Destination': 'Rules',
    'Mappings': [
      {'Field': 'full_name', 'Target': 'Name'},
      {'Field': 'phone_number', 'Target': 'Mobile'},
      {'Field': 'city', 'Target': 'Area'},
      {'Field': 'roof_size', 'Target': 'Custom'},
      {'Field': 'business_name', 'Target': 'Company'},
    ],
  },
];
