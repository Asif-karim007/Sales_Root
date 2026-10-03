import 'package:salesroot/core/fake/seed_graph.dart';

/// The sales pipeline starts from the shared seed stages, so names and ids
/// match the leads the other features show.
List<Map<String, dynamic>> pipelineFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'Name': 'Sales',
    'NameBn': 'বিক্রি',
    'IsDefault': true,
    'Stages': [
      for (final (id, name, nameBn, win) in SeedGraph.stages)
        {
          'Id': id,
          'Name': name,
          'NameBn': nameBn,
          'WinPercent': win,
          'Kind': switch (id) {
            5 => 'Won',
            6 => 'Lost',
            _ => 'Open',
          },
          'MinLevel': id == 4 ? 'Standard' : 'Easy',
          'RequiresQuotation': id == 4,
          'RequiresReason': id == 6,
        },
    ],
  },
  {
    'Id': 2,
    'Name': 'Servicing',
    'NameBn': 'সার্ভিসিং',
    'IsDefault': false,
    'Stages': [
      _stage(11, 'New request', 'নতুন অনুরোধ', 10, 'Easy'),
      _stage(12, 'Site survey', 'সাইট জরিপ', 35, 'Easy'),
      _stage(13, 'Parts ordered', 'যন্ত্রাংশ অর্ডার', 60, 'Standard'),
      _stage(14, 'Installation', 'ইনস্টলেশন', 85, 'Easy'),
      _stage(15, 'Handed over', 'হস্তান্তর', 100, 'Easy', kind: 'Won'),
      _stage(
        16,
        'Cancelled',
        'বাতিল',
        0,
        'Easy',
        kind: 'Lost',
        requiresReason: true,
      ),
    ],
  },
];

Map<String, dynamic> _stage(
  int id,
  String name,
  String nameBn,
  int win,
  String level, {
  String kind = 'Open',
  bool requiresReason = false,
}) => {
  'Id': id,
  'Name': name,
  'NameBn': nameBn,
  'WinPercent': win,
  'Kind': kind,
  'MinLevel': level,
  'RequiresQuotation': false,
  'RequiresReason': requiresReason,
};

const _all = ['Easy', 'Standard', 'Advanced'];
const _standardUp = ['Standard', 'Advanced'];
const _advanced = ['Advanced'];

List<Map<String, dynamic>> formFieldFixtures(SeedGraph graph) => [
  _field(1, 'Lead', 'Name', 'নাম', 'Text', _all, system: true),
  _field(2, 'Lead', 'Mobile', 'মোবাইল', 'Phone', _all, system: true),
  _field(3, 'Lead', 'Interest', 'আগ্রহ', 'MultiChoice', _all),
  _field(4, 'Lead', 'Next follow-up', 'পরের ফলো-আপ', 'Date', _all),
  _field(5, 'Lead', 'Deal value', 'সম্ভাব্য মূল্য', 'Money', _standardUp),
  _field(6, 'Lead', 'Source', 'উৎস', 'Text', _standardUp),
  _field(
    7,
    'Lead',
    'Roof size (sq ft)',
    'ছাদের আকার (sq ft)',
    'Number',
    _standardUp,
    template: 'Solar',
  ),
  _field(
    8,
    'Lead',
    'Monthly electricity bill',
    'মাসিক বিদ্যুৎ বিল',
    'Money',
    _standardUp,
    template: 'Solar',
  ),
  _field(
    9,
    'Lead',
    'Net metering',
    'নেট মিটারিং',
    'YesNo',
    _advanced,
    template: 'Solar',
  ),
  _field(10, 'Lead', 'Email', 'ইমেইল', 'Email', _advanced),
  _field(21, 'Contact', 'Name', 'নাম', 'Text', _all, system: true),
  _field(22, 'Contact', 'Mobile', 'মোবাইল', 'Phone', _all, system: true),
  _field(23, 'Contact', 'Company', 'প্রতিষ্ঠান', 'Text', _all),
  _field(24, 'Contact', 'Designation', 'পদবি', 'Text', _standardUp),
  _field(25, 'Contact', 'Email', 'ইমেইল', 'Email', _standardUp),
  _field(26, 'Contact', 'Area', 'এলাকা', 'Text', _standardUp),
  _field(27, 'Contact', 'Industry', 'শিল্প খাত', 'Text', _advanced),
  _field(28, 'Contact', 'Website', 'ওয়েবসাইট', 'Text', _advanced),
  _field(
    29,
    'Contact',
    'Trade licence no.',
    'ট্রেড লাইসেন্স নং',
    'Text',
    _advanced,
  ),
];

Map<String, dynamic> _field(
  int id,
  String form,
  String name,
  String nameBn,
  String type,
  List<String> levels, {
  bool system = false,
  String? template,
}) => {
  'Id': id,
  'Form': form,
  'Name': name,
  'NameBn': nameBn,
  'Type': type,
  'Required': system,
  'IsSystem': system,
  'Levels': levels,
  'Template': ?template,
};
