import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';

/// A lead read out of a spoken sentence in Bangla or English, such as
/// "New lead Rahim Enterprise, number 01912345678, interested in solar,
/// follow up tomorrow".
class LeadTranscript {
  const LeadTranscript({
    required this.text,
    this.name,
    this.company,
    this.phone,
    this.interests = const [],
    this.followUp,
  });

  final String text;
  final String? name;
  final String? company;

  /// Local form, `01XXXXXXXXX`.
  final String? phone;

  /// English interest names: Solar, Inverter, Battery, Servicing…
  final List<String> interests;
  final LeadFollowUp? followUp;

  bool get isEmpty => name == null && company == null && phone == null;

  factory LeadTranscript.parse(String text, {required DateTime now}) {
    final latin = _latinDigits(text).trim();
    final phoneMatch = _phonePattern.firstMatch(latin);
    final phone = phoneMatch == null ? null : _localPhone(phoneMatch[0] ?? '');
    final rest = phoneMatch == null
        ? latin
        : latin.replaceRange(phoneMatch.start, phoneMatch.end, ' ');
    final lower = rest.toLowerCase();
    final named = _name(rest);
    final company = _company(rest) ?? (_looksLikeCompany(named) ? named : null);
    return LeadTranscript(
      text: text.trim(),
      name: named ?? company,
      company: company,
      phone: phone,
      interests: [
        for (final entry in _interestWords.entries)
          if (entry.value.any((w) => _says(lower, w))) entry.key,
      ],
      followUp: _followUp(lower, now),
    );
  }

  /// This transcript with what the server's parser read out of [text],
  /// `POST ai/parse`; what it did not find stays as heard.
  LeadTranscript refinedBy(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final phone = read('phone');
    return LeadTranscript(
      text: text,
      name: read('name') ?? name,
      company: read('company') ?? read('companyName') ?? company,
      phone: phone == null ? this.phone : _localPhone(phone),
      interests: interests,
      followUp: followUp,
    );
  }

  static final _phonePattern = RegExp(
    r'(?:\+?\s*8\s*8\s*)?0\s*1(?:[\s-]*\d){9}',
  );

  static const _digits = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  static String _latinDigits(String text) =>
      text.split('').map((c) => _digits[c] ?? c).join();

  static String _localPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('88') ? digits.substring(2) : digits;
  }

  static const _leadMarkers = [
    'new lead',
    'add lead',
    'lead',
    'নতুন লিড',
    'লিড',
    'name is',
    'নাম',
  ];

  static const _stopWords = [
    'number',
    'phone',
    'mobile',
    'interested',
    'interest',
    'follow',
    'call',
    'visit',
    'meeting',
    'tomorrow',
    'today',
    'from',
    'company',
    'wants',
    'নম্বর',
    'নাম্বার',
    'ফোন',
    'মোবাইল',
    'আগ্রহী',
    'আগ্রহ',
    'ফলো',
    'কল',
    'ভিজিট',
    'মিটিং',
    'কাল',
    'আগামীকাল',
    'আজ',
    'কোম্পানি',
    'প্রতিষ্ঠান',
    'চান',
  ];

  static final _separator = RegExp(r'[,،।;.!?\n]');

  /// The words after a lead marker, up to a comma or a keyword; without a
  /// marker, the first such run.
  static String? _name(String text) {
    var start = 0;
    final lower = text.toLowerCase();
    for (final marker in _leadMarkers) {
      final at = lower.indexOf(marker);
      if (at >= 0) {
        start = at + marker.length;
        break;
      }
    }
    return _run(text, start);
  }

  static String? _company(String text) {
    final lower = text.toLowerCase();
    for (final marker in const ['from', 'company', 'কোম্পানি', 'প্রতিষ্ঠান']) {
      final at = lower.indexOf(' $marker ');
      if (at >= 0) return _run(text, at + marker.length + 2);
    }
    return null;
  }

  static String? _run(String text, int start) {
    final words = <String>[];
    for (final word in text.substring(start).split(RegExp(r'\s+'))) {
      final clean = word.replaceAll(RegExp(r'^[:\-–]+'), '');
      if (clean.isEmpty) {
        if (words.isEmpty) continue;
        break;
      }
      final bare = clean.replaceAll(_separator, '').toLowerCase();
      if (words.isNotEmpty && _stopWords.any(bare.startsWith)) break;
      if (bare.isNotEmpty && !_stopWords.contains(bare)) {
        words.add(clean.replaceAll(_separator, ''));
      }
      if (_separator.hasMatch(clean)) break;
    }
    if (words.isEmpty) return null;
    return _titleCase(words.join(' '));
  }

  static String _titleCase(String text) {
    if (text != text.toLowerCase()) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static const _companySuffixes = [
    'enterprise',
    'traders',
    'trading',
    'textile',
    'group',
    'ltd',
    'limited',
    'store',
    'pharma',
    'agro',
    'power',
    'industries',
    'corporation',
    'electronics',
    'builders',
    'motors',
    'mills',
    'এন্টারপ্রাইজ',
    'ট্রেডার্স',
    'টেক্সটাইল',
    'গ্রুপ',
    'লিমিটেড',
    'স্টোর',
    'ফার্মা',
    'এগ্রো',
    'পাওয়ার',
    'ইন্ডাস্ট্রিজ',
    'মিলস',
  ];

  static bool _looksLikeCompany(String? name) {
    final lower = name?.toLowerCase() ?? '';
    return _companySuffixes.any(lower.contains);
  }

  static const _interestWords = {
    'Solar': ['solar', 'panel', 'সোলার', 'প্যানেল'],
    'Inverter': ['inverter', 'ips', 'ইনভার্টার', 'আইপিএস'],
    'Battery': ['battery', 'ব্যাটারি'],
    'Servicing': ['servic', 'maintenance', 'সার্ভিস', 'মেরামত'],
    'Installation': ['install', 'ইনস্টল', 'লাগানো'],
    'Street light': ['street light', 'স্ট্রিট লাইট'],
    'Water pump': ['pump', 'পাম্প'],
  };

  static const _dayWords = [
    ('day after tomorrow', 2),
    ('পরশু', 2),
    ('next week', 7),
    ('আগামী সপ্তাহ', 7),
    ('tomorrow', 1),
    ('আগামীকাল', 1),
    ('কাল', 1),
    ('today', 0),
    ('আজ', 0),
  ];

  static const _weekdays = [
    (DateTime.monday, ['monday', 'সোমবার']),
    (DateTime.tuesday, ['tuesday', 'মঙ্গলবার']),
    (DateTime.wednesday, ['wednesday', 'বুধবার']),
    (DateTime.thursday, ['thursday', 'বৃহস্পতিবার']),
    (DateTime.friday, ['friday', 'শুক্রবার']),
    (DateTime.saturday, ['saturday', 'শনিবার']),
    (DateTime.sunday, ['sunday', 'রবিবার', 'রোববার']),
  ];

  static const _kindWords = [
    (
      LeadActivityKind.visit,
      ['visit', 'ভিজিট', 'যাব', 'দেখা করব', 'meeting', 'meet', 'মিটিং'],
    ),
    (LeadActivityKind.whatsapp, ['whatsapp', 'হোয়াটসঅ্যাপ']),
    (LeadActivityKind.call, ['call', 'follow', 'কল', 'ফোন', 'ফলো']),
  ];

  static final _wordBreak = RegExp(r'[\s,،।;.!?]+');

  /// Whether [text] has a word starting with [word], or contains [word] when
  /// it is a phrase, so "বিকাল" does not read as "কাল".
  static bool _says(String text, String word) {
    if (word.contains(' ')) return text.contains(word);
    return text.split(_wordBreak).any((token) => token.startsWith(word));
  }

  static LeadFollowUp? _followUp(String lower, DateTime now) {
    int? days;
    for (final (word, offset) in _dayWords) {
      if (_says(lower, word)) {
        days = offset;
        break;
      }
    }
    if (days == null) {
      for (final (weekday, words) in _weekdays) {
        if (words.any((w) => _says(lower, w))) {
          days = (weekday - now.weekday + 7) % 7;
          if (days == 0) days = 7;
          break;
        }
      }
    }
    LeadActivityKind? kind;
    for (final (candidate, words) in _kindWords) {
      if (words.any((w) => _says(lower, w))) {
        kind = candidate;
        break;
      }
    }
    if (days == null && kind == null) return null;
    final (hour, minute) = _time(lower);
    final day = now.add(Duration(days: days ?? 1));
    return LeadFollowUp(
      kind: kind ?? LeadActivityKind.call,
      at: DateTime(day.year, day.month, day.day, hour, minute),
    );
  }

  static final _clock = RegExp(
    r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.|টায়|টা)',
  );

  static (int, int) _time(String lower) {
    final match = _clock.firstMatch(lower);
    if (match == null) return (10, 0);
    var hour = int.tryParse(match[1] ?? '') ?? 10;
    final minute = int.tryParse(match[2] ?? '') ?? 0;
    final suffix = match[3] ?? '';
    final evening = [
      'বিকাল',
      'বিকেল',
      'সন্ধ্যা',
      'রাত',
    ].any((w) => _says(lower, w));
    final noon = _says(lower, 'দুপুর') && hour < 5;
    if ((suffix.startsWith('p') || evening || noon) && hour < 12) hour += 12;
    if (suffix.startsWith('a') && hour == 12) hour = 0;
    return (hour.clamp(0, 23), minute.clamp(0, 59));
  }
}
