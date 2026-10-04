import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/digits.dart';
import 'package:salesroot/translations/translations.dart';

/// Every number, amount and date shown on screen goes through here, so Bangla
/// gets Bangla digits and lakh/crore.
class AppFormat {
  AppFormat(this._l10n, this.locale);

  final AppLocalizations _l10n;
  final Locale locale;

  bool get isBangla => locale.languageCode == 'bn';
  String get _tag => isBangla ? 'bn' : 'en';

  String digits(String text) => localizeDigits(text, bangla: isBangla);

  String number(num value, {int decimals = 0}) {
    final whole = value.truncate();
    final grouped = groupIndian(whole);
    if (decimals == 0) return digits(grouped);
    final fraction = (value - whole)
        .abs()
        .toStringAsFixed(decimals)
        .substring(1);
    return digits('$grouped$fraction');
  }

  /// ৳ 2,40,000
  String money(num amount) => '৳ ${number(amount.round())}';

  /// ৳ 18.6 lakh / ৳ ১৮.৬ লাখ; falls back to [money] below one lakh.
  String moneyCompact(num amount) {
    final value = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (value >= 10000000) {
      return '৳ $sign${_short(value / 10000000)} ${_l10n.moneyCrore}';
    }
    if (value >= 100000) {
      return '৳ $sign${_short(value / 100000)} ${_l10n.moneyLakh}';
    }
    return money(amount);
  }

  String _short(double value) {
    final text = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return digits(
      text.endsWith('.0') ? text.substring(0, text.length - 2) : text,
    );
  }

  String percent(num value) => '${number(value.round())}%';

  String phone(String raw) => digits(raw);

  /// 4 Oct
  String dayMonth(DateTime date) =>
      digits(DateFormat('d MMM', _tag).format(date));

  /// 4 Oct 2026
  String date(DateTime date) =>
      digits(DateFormat('d MMM y', _tag).format(date));

  /// Sat, 4 Oct
  String weekdayDate(DateTime date) =>
      digits(DateFormat('EEE, d MMM', _tag).format(date));

  /// October 2026
  String monthYear(DateTime date) =>
      digits(DateFormat('MMMM y', _tag).format(date));

  /// 14:30 in Bangla, 2:30 PM in English.
  String time(DateTime date) =>
      digits(DateFormat(isBangla ? 'H:mm' : 'h:mm a', _tag).format(date));

  /// Today 14:30, Yesterday 9:05, or 2 Oct 11:00.
  String dayTime(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    if (AppDateUtils.isSameDay(date, today)) {
      return '${_l10n.commonToday} ${time(date)}';
    }
    if (AppDateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))) {
      return '${_l10n.commonYesterday} ${time(date)}';
    }
    return '${dayMonth(date)} ${time(date)}';
  }

  /// "5 min ago". Only for device-made timestamps; never compare server
  /// stamps against the device clock.
  String relative(DateTime date, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.inMinutes < 1) return _l10n.relativeJustNow;
    if (diff.inHours < 1) return _l10n.relativeMinutes(number(diff.inMinutes));
    if (diff.inDays < 1) return _l10n.relativeHours(number(diff.inHours));
    return _l10n.relativeDays(number(diff.inDays));
  }
}

extension AppFormatContext on BuildContext {
  AppFormat get fmt => AppFormat(l10n, Localizations.localeOf(this));
}
