import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';

enum TeamCurrency {
  bdt('BDT', '৳'),
  usd('USD', r'$');

  const TeamCurrency(this.wire, this.symbol);

  final String wire;
  final String symbol;
}

/// What #9 sets on a team right after it is created.
class TeamSetup {
  const TeamSetup({
    required this.industry,
    required this.currency,
    this.addOns = const {},
  });

  final IndustryTemplate industry;
  final TeamCurrency currency;
  final Set<AddOn> addOns;

  Map<String, dynamic> toJson() => {
    'IndustryTemplate': industry.wire,
    'Currency': currency.wire,
    'AddOns': [for (final addOn in addOns) addOn.wire],
  };
}
