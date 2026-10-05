import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

const Map<String, String> _t = {
  'title': 'Design system',
  'subtitle': 'Every Sr widget in its states',
  'buttons': 'Buttons',
  'primary': 'Save lead',
  'secondary': 'Add contact',
  'ghost': 'See all',
  'danger': 'Delete',
  'dark': 'Start visit',
  'small': 'Call',
  'large': 'Continue',
  'loading': 'Saving',
  'disabled': 'Disabled',
  'controls': 'Icon buttons, switch, checkbox',
  'switchLabel': 'Reminders',
  'checkLabel': 'Remember me',
  'cards': 'Cards',
  'plainCard': 'Plain card on the surface',
  'tintCard': 'Tint card for highlights',
  'goldCard': 'Gold card for plan and money hints',
  'dashedCard': 'Dashed card: add a new item',
  'rows': 'List rows',
  'todayCalls': 'Today\'s calls',
  'karimTextiles': 'Karim Textiles',
  'karimSub': 'Mirpur 10 · Interested',
  'deltaPower': 'Delta Power',
  'deltaSub': 'Tejgaon · Quotation sent',
  'meghna': 'Meghna Group',
  'meghnaSub': 'Motijheel · New',
  'rafiq': 'Rafiqul Islam',
  'rafiqSub': 'Team lead · Gulshan',
  'avatars': 'Avatars',
  'tags': 'Tags, chips, badges',
  'won': 'Won',
  'pending': 'Pending',
  'overdue': 'Overdue',
  'hot': 'Hot',
  'neutralTag': 'Textile',
  'darkTag': 'Owner',
  'stage': 'Interested',
  'all': 'All',
  'dueToday': 'Due today',
  'stalled': 'Stalled',
  'fields': 'Fields',
  'name': 'Company name',
  'nameHint': 'e.g. Karim Textiles',
  'phone': 'Mobile number',
  'phoneError': 'Enter an 11-digit number',
  'amount': 'Deal value',
  'note': 'Note',
  'noteHint': 'What did they say?',
  'area': 'Area',
  'areaHint': 'Choose an area',
  'pickers': 'Pickers and sheets',
  'single': 'Option sheet',
  'search': 'Paged search sheet',
  'multi': 'Multi-select sheet',
  'lookup': 'Lookup picker',
  'lookupMulti': 'Lookup multi picker',
  'assignee': 'Assignee',
  'tags2': 'Labels',
  'confirm': 'Confirm sheet',
  'confirmTitle': 'Delete this lead?',
  'confirmBody': 'Its tasks and notes are deleted too.',
  'loader': 'Loader',
  'sheet': 'Plain sheet',
  'sheetBody': 'Anything goes in a sheet.',
  'dialogs': 'Dialogs and snackbars',
  'alert': 'Alert dialog',
  'alertTitle': 'Location is off',
  'alertBody': 'Turn on location to check in.',
  'success': 'Success dialog',
  'successTitle': 'Lead saved',
  'successBody': 'Karim Textiles is in your list.',
  'noResponse': 'No-response dialog',
  'snackSuccess': 'Saved',
  'snackError': 'Couldn\'t save',
  'snackWarning': 'Quota nearly used',
  'snackInfo': 'Synced 2 minutes ago',
  'undo': 'Undo',
  'states': 'States',
  'emptyTitle': 'No leads yet',
  'emptyBody': 'Add your first lead to get started.',
  'addLead': 'Add lead',
  'serverMessage': 'The quotation number is already used.',
  'async': 'SrAsyncView',
  'segmented': 'Segmented',
  'myLeads': 'My leads',
  'pipeline': 'Pipeline',
  'strips': 'Strips and tabs',
  'open': 'Open',
  'paid': 'Paid',
  'progress': 'Progress',
  'toContact': 'To contact',
  'contacted': 'Contacted',
  'interested': 'Interested',
  'items': 'Items',
  'quantity': 'Quantity',
  'review': 'Review',
  'kpis': 'KPIs',
  'calls': 'Calls today',
  'followUps': 'Follow-ups due',
  'visits': 'Visits',
  'yesterday': '8 yesterday',
  'more': '2 more than usual',
  'sameAsUsual': 'Same as usual',
  'notes': 'Notes',
  'noteTint': 'The code fills in by itself when the SMS arrives.',
  'noteGold': 'Your call-to-meeting rate is 28%; team average 21%.',
  'noteErr': 'This number is already a lead.',
  'noteNeutral': 'Last synced at 10:42.',
  'timeline': 'Timeline',
  'tlCall': 'Call · 4 min',
  'tlCallSub': 'Interested in price, asked for a quotation.',
  'tlVisit': 'Visit',
  'tlVisitSub': 'Met the purchase manager.',
  'tlQuote': 'Quotation sent',
  'tlQuoteSub': 'Q-0043 on WhatsApp',
  'today': 'Today 11:05',
  'monday': 'Mon 15:30',
  'sunday': 'Sun 10:00',
  'charts': 'Charts',
  'winRate': 'win rate',
  'lost': 'Lost',
  'textile': 'Textile',
  'power': 'Power',
  'retail': 'Retail',
  'pin': 'Keypad, OTP, PIN',
  'chat': 'Chat bubbles',
  'msg1': 'Everyone, meeting at the office tomorrow 9:30.',
  'msg2': 'Okay bhai',
  'msg3': 'Delta Power site photo',
  'karim': 'Karim',
  'misc': 'Language, file viewer, coming soon',
  'fileError': 'File viewer (error)',
  'comingSoon': 'Coming soon screen',
  'quotes': 'Quotations',
  'plan': 'Growth plan',
  'taka': '৳',
  'mirpur': 'Mirpur 10',
  'gulshan': 'Gulshan 1',
  'tejgaon': 'Tejgaon',
  'uttara': 'Uttara',
  'company': 'Company',
  'pdfName': 'Q-0043.pdf',
  'pdfSize': '120 KB',
  'pdfUrl': 'https://example.com/Q-0043.pdf',
  'badImage': 'https://invalid.example/a.jpg',
  'boom': 'boom',
  'mLoading': 'Loading',
  'mError': 'Error',
  'mEmpty': 'Empty',
  'mData': 'Data',
  'datePicker': 'Date and time picker',
  'p1': 'Karim Hossain',
  'p2': 'Rafiqul Islam',
  'p3': 'Nusrat Jahan',
  'p4': 'Tanvir Ahmed',
  'p5': 'Sadia Rahman',
  'owner': 'Owner',
  'lead': 'Team lead',
  'member': 'Member',
};

String _s(String key) => _t[key] ?? key;

class _DemoFailure implements SrDisplayableFailure {
  const _DemoFailure(this.statusCode, [this.message = '']);

  @override
  final int statusCode;

  @override
  final String message;
}

/// A debug page that shows every design-system widget in its states.
class SrGalleryScreen extends StatefulWidget {
  const SrGalleryScreen({super.key});

  @override
  State<SrGalleryScreen> createState() => _SrGalleryScreenState();
}

class _SrGalleryScreenState extends State<SrGalleryScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '01711');
  final _amount = TextEditingController();
  final _note = TextEditingController();

  int _tab = 0;
  bool _bangla = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      const _Buttons(),
      const _Controls(),
      const _Cards(),
      const _Rows(),
      const _Avatars(),
      const _Tags(),
      _Fields(name: _name, phone: _phone, amount: _amount, note: _note),
      const _Pickers(),
      const _Dialogs(),
      const _States(),
      const _AsyncDemo(),
      const _Selectors(),
      const _Progress(),
      const _Kpis(),
      const _Notes(),
      const _Timeline(),
      const _Charts(),
      const _PinDemo(),
      const _Chat(),
      _Misc(
        bangla: _bangla,
        onLanguage: (value) => setState(() => _bangla = value),
      ),
    ];

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: _s('title'),
          subtitle: _s('subtitle'),
          actions: [
            SrIconButton(icon: Icons.search_rounded, onTap: () {}),
            SrIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              onTap: () {},
            ),
          ],
        ),
        bottomBar: SrTabBar(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
          onAdd: () => showSrInfo(context, _s('snackInfo')),
          items: [
            SrTabItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: context.l10n.navHome,
            ),
            SrTabItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: context.l10n.navLeads,
              badge: 3,
            ),
            SrTabItem(
              icon: Icons.check_box_outlined,
              activeIcon: Icons.check_box_rounded,
              label: context.l10n.navTasks,
              badge: 0,
            ),
            SrTabItem(icon: Icons.menu_rounded, label: context.l10n.navMore),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            32,
          ),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 28),
          itemBuilder: (_, i) => sections[i],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.titleKey, this.children);

  final String titleKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(title: _s(titleKey)),
        for (final child in children) ...[const SizedBox(height: 10), child],
      ],
    );
  }
}

class _Wrap extends StatelessWidget {
  const _Wrap(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return _Section('buttons', [
      SrButton(label: _s('primary'), expand: true, onPressed: () {}),
      _Wrap([
        SrButton(
          label: _s('secondary'),
          icon: Icons.person_add_alt_rounded,
          variant: SrButtonVariant.secondary,
          onPressed: () {},
        ),
        SrButton(
          label: _s('ghost'),
          variant: SrButtonVariant.ghost,
          onPressed: () {},
        ),
        SrButton(
          label: _s('danger'),
          variant: SrButtonVariant.danger,
          onPressed: () {},
        ),
        SrButton(
          label: _s('dark'),
          variant: SrButtonVariant.dark,
          icon: Icons.place_outlined,
          onPressed: () {},
        ),
        SrButton(
          label: _s('small'),
          size: SrButtonSize.sm,
          icon: Icons.call_outlined,
          onPressed: () {},
        ),
        SrButton(label: _s('loading'), loading: true, onPressed: () {}),
        SrButton(label: _s('disabled')),
      ]),
      SrButton(
        label: _s('large'),
        size: SrButtonSize.lg,
        expand: true,
        onPressed: () {},
      ),
    ]);
  }
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  bool _switch = true;
  bool _check = false;

  @override
  Widget build(BuildContext context) {
    return _Section('controls', [
      _Wrap([
        SrIconButton(icon: Icons.arrow_back_rounded, onTap: () {}),
        SrIconButton(icon: Icons.tune_rounded, badge: true, onTap: () {}),
        SrIconButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: 12,
          onTap: () {},
        ),
        SrIconButton(
          icon: Icons.more_vert_rounded,
          compact: true,
          onTap: () {},
        ),
      ]),
      SrCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_s('switchLabel'), style: _rowStyle(context)),
                ),
                SrSwitch(
                  value: _switch,
                  onChanged: (v) => setState(() => _switch = v),
                ),
                const SizedBox(width: 12),
                const SrSwitch(value: false, onChanged: null),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SrCheckbox(
                  value: _check,
                  onChanged: (v) => setState(() => _check = v),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_s('checkLabel'), style: _rowStyle(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }
}

TextStyle _rowStyle(BuildContext context) =>
    AppText.rowTitle(SrColors.of(context).ink);

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    return _Section('cards', [
      SrCard(
        onTap: () {},
        child: Text(_s('plainCard'), style: _rowStyle(context)),
      ),
      SrCard(
        tone: SrCardTone.tint,
        child: Text(_s('tintCard'), style: _rowStyle(context)),
      ),
      SrCard(
        tone: SrCardTone.gold,
        child: Text(_s('goldCard'), style: _rowStyle(context)),
      ),
      SrCard(
        tone: SrCardTone.dashed,
        onTap: () {},
        child: Text(_s('dashedCard'), style: _rowStyle(context)),
      ),
    ]);
  }
}

class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    return _Section('rows', [
      SrRowGroup(
        title: _s('todayCalls'),
        onSeeAll: () {},
        rows: [
          SrListRow(
            leading: SrAvatar(name: _s('karimTextiles')),
            title: _s('karimTextiles'),
            subtitle: _s('karimSub'),
            trailing: SrRowTrailing(
              value: fmt.moneyCompact(240000),
              meta: fmt.time(DateTime(2026, 10, 4, 11)),
            ),
            onTap: () {},
          ),
          SrListRow(
            leading: const SrAvatar(
              icon: Icons.bolt_rounded,
              tone: SrAvatarTone.accent,
            ),
            title: _s('deltaPower'),
            subtitle: _s('deltaSub'),
            trailing: SrTag(_s('pending'), tone: SrTone.warn),
            onTap: () {},
          ),
          SrListRow(
            leading: SrAvatar(name: _s('meghna'), square: true),
            title: _s('meghna'),
            subtitle: _s('meghnaSub'),
            chevron: true,
            onTap: () {},
          ),
        ],
      ),
      SrCard(
        padding: EdgeInsets.zero,
        child: SrListRow(
          leading: SrAvatar(name: _s('rafiq'), tone: SrAvatarTone.gold),
          title: _s('rafiq'),
          subtitle: _s('rafiqSub'),
          divider: true,
          chevron: true,
          onTap: () {},
        ),
      ),
    ]);
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars();

  @override
  Widget build(BuildContext context) {
    return _Section('avatars', [
      _Wrap([
        SrAvatar(name: _s('rafiq')),
        SrAvatar(name: _s('karimTextiles'), tone: SrAvatarTone.accent),
        SrAvatar(name: _s('deltaPower'), tone: SrAvatarTone.gold),
        SrAvatar(name: _s('meghna'), tone: SrAvatarTone.danger),
        SrAvatar(name: _s('rafiq'), tone: SrAvatarTone.dark),
        SrAvatar(name: _s('karim'), square: true),
        const SrAvatar(
          icon: Icons.storefront_outlined,
          tone: SrAvatarTone.accent,
        ),
        SrAvatar(name: _s('karim'), size: 56),
        SrAvatar(name: _s('karim'), imageUrl: _s('badImage')),
      ]),
    ]);
  }
}

class _Tags extends StatefulWidget {
  const _Tags();

  @override
  State<_Tags> createState() => _TagsState();
}

class _TagsState extends State<_Tags> {
  int _index = 0;
  final Set<int> _picked = {1};

  @override
  Widget build(BuildContext context) {
    final chips = [
      SrChipItem(_s('all'), count: 12),
      SrChipItem(_s('dueToday'), count: 3),
      SrChipItem(_s('overdue'), count: 2, tone: SrTone.err),
      SrChipItem(_s('stalled'), count: 1),
      SrChipItem(_s('hot'), count: 4),
    ];
    final tags = [_s('textile'), _s('power'), _s('retail')];

    return _Section('tags', [
      _Wrap([
        SrTag(_s('neutralTag')),
        SrTag(_s('won'), tone: SrTone.ok),
        SrTag(_s('pending'), tone: SrTone.warn),
        SrTag(_s('overdue'), tone: SrTone.err, dot: true),
        SrTag(
          _s('hot'),
          tone: SrTone.accent,
          icon: Icons.local_fire_department_outlined,
        ),
        SrTag(_s('darkTag'), tone: SrTone.dark),
        SrTag(_s('plan'), tone: SrTone.gold),
        SrStagePill(label: _s('stage'), onTap: () {}),
        const SrBadge(count: 5),
        const SrBadge(),
        const SrBadge(count: 120, tone: SrTone.accent),
      ]),
      SrChipRow(
        chips: chips,
        index: _index,
        padding: EdgeInsets.zero,
        onChanged: (i) => setState(() => _index = i),
      ),
      _Wrap([
        for (var i = 0; i < tags.length; i++)
          SrChip(
            label: tags[i],
            selected: _picked.contains(i),
            icon: _picked.contains(i) ? Icons.check_rounded : null,
            onTap: () => setState(() {
              if (!_picked.remove(i)) _picked.add(i);
            }),
          ),
        SrChip(label: _s('overdue'), tone: SrTone.err, count: 2, onTap: () {}),
      ]),
    ]);
  }
}

class _Fields extends StatelessWidget {
  const _Fields({
    required this.name,
    required this.phone,
    required this.amount,
    required this.note,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController amount;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    return _Section('fields', [
      SrTextField(
        controller: name,
        label: _s('name'),
        hint: _s('nameHint'),
        prefixIcon: Icons.storefront_outlined,
      ),
      SrTextField(
        controller: phone,
        label: _s('phone'),
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.call_outlined,
        error: _s('phoneError'),
      ),
      SrTextField(
        controller: amount,
        label: _s('amount'),
        optional: true,
        keyboardType: TextInputType.number,
        suffixText: _s('taka'),
      ),
      SrTextField(
        controller: note,
        label: _s('note'),
        hint: _s('noteHint'),
        multiline: true,
      ),
      SrDropdownField(
        label: _s('area'),
        placeholder: _s('areaHint'),
        icon: Icons.place_outlined,
        onTap: () {},
      ),
      SrDropdownField(label: _s('area'), value: _s('mirpur'), onTap: () {}),
      SrDropdownField(
        label: _s('area'),
        value: _s('gulshan'),
        enabled: false,
        onTap: () {},
      ),
    ]);
  }
}

final List<SrLookupOption> _people = [
  SrLookupOption(id: '1', name: _s('p1'), subtitle: _s('owner')),
  SrLookupOption(id: '2', name: _s('p2'), subtitle: _s('lead')),
  SrLookupOption(id: '3', name: _s('p3'), subtitle: _s('member')),
  SrLookupOption(id: '4', name: _s('p4'), subtitle: _s('member')),
  SrLookupOption(id: '5', name: _s('p5'), subtitle: _s('member')),
];

class _Pickers extends StatefulWidget {
  const _Pickers();

  @override
  State<_Pickers> createState() => _PickersState();
}

class _PickersState extends State<_Pickers> {
  String? _single = '2';
  List<String> _multi = const ['1', '3'];

  Future<List<String>> _search(String term, int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (page > 3) return const [];
    return [
      for (var i = 0; i < 20; i++)
        '${term.isEmpty ? _s('company') : term} ${(page - 1) * 20 + i + 1}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _Section('pickers', [
      SrLookupPicker(
        title: _s('assignee'),
        label: _s('lookup'),
        options: _people,
        selected: _single,
        withAvatar: true,
        onChanged: (id) => setState(() => _single = id),
      ),
      SrLookupMultiPicker(
        title: _s('tags2'),
        label: _s('lookupMulti'),
        options: _people,
        selected: _multi,
        onChanged: (ids) => setState(() => _multi = ids),
      ),
      _Wrap([
        SrButton(
          label: _s('single'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrSheet<String>(
            context: context,
            builder: (_) => SrOptionSheet<String>(
              title: _s('area'),
              options: [
                _s('mirpur'),
                _s('gulshan'),
                _s('tejgaon'),
                _s('uttara'),
              ],
              labelOf: (o) => o,
              isSelected: (o) => o == _s('tejgaon'),
            ),
          ),
        ),
        SrButton(
          label: _s('search'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrSheet<String>(
            context: context,
            builder: (_) => SrSearchSheet<String>(
              title: _s('karimTextiles'),
              search: _search,
              labelOf: (o) => o,
              isSelected: (_) => false,
            ),
          ),
        ),
        SrButton(
          label: _s('multi'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrSheet<List<String>>(
            context: context,
            builder: (_) => SrMultiOptionSheet<String>(
              title: _s('tags2'),
              options: [_s('textile'), _s('power'), _s('retail')],
              labelOf: (o) => o,
              isSelected: (o) => o == _s('power'),
            ),
          ),
        ),
        SrButton(
          label: _s('sheet'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrSheet<void>(
            context: context,
            builder: (_) => SrSheet(
              title: _s('sheet'),
              subtitle: _s('subtitle'),
              child: Text(_s('sheetBody'), style: _rowStyle(context)),
            ),
          ),
        ),
        SrButton(
          label: _s('confirm'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.danger,
          onPressed: () => showSrConfirm(
            context,
            title: _s('confirmTitle'),
            message: _s('confirmBody'),
            confirmLabel: _s('danger'),
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
        ),
        SrButton(
          label: _s('loader'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrLoader<void>(
            context,
            Future<void>.delayed(const Duration(seconds: 1)),
          ),
        ),
      ]),
    ]);
  }
}

class _Dialogs extends StatelessWidget {
  const _Dialogs();

  @override
  Widget build(BuildContext context) {
    return _Section('dialogs', [
      _Wrap([
        SrButton(
          label: _s('alert'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => SrAlertDialog(
              icon: Icons.location_off_outlined,
              title: _s('alertTitle'),
              message: _s('alertBody'),
              actionLabel: dialogContext.l10n.commonOk,
              onAction: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ),
        SrButton(
          label: _s('success'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => showSrSuccessDialog(
            context: context,
            title: _s('successTitle'),
            message: _s('successBody'),
          ),
        ),
        SrButton(
          label: _s('noResponse'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () =>
              showSrNoResponseDialog(context: context, onRetry: () async {}),
        ),
      ]),
      _Wrap([
        SrButton(
          label: _s('snackSuccess'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.ghost,
          onPressed: () => showSrSuccess(context, _s('successBody')),
        ),
        SrButton(
          label: _s('snackError'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.ghost,
          onPressed: () => showSrError(
            context,
            _s('serverMessage'),
            title: _s('snackError'),
          ),
        ),
        SrButton(
          label: _s('snackWarning'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.ghost,
          onPressed: () => showSrWarning(context, _s('snackWarning')),
        ),
        SrButton(
          label: _s('snackInfo'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.ghost,
          onPressed: () => showSrSnack(
            context,
            _s('snackInfo'),
            action: SrSnackAction(label: _s('undo'), onPressed: () {}),
          ),
        ),
      ]),
    ]);
  }
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) {
    return _Section('states', [
      SrCard(
        child: SrEmptyState(
          title: _s('emptyTitle'),
          message: _s('emptyBody'),
          icon: Icons.people_outline_rounded,
          actionLabel: _s('addLead'),
          onAction: () {},
        ),
      ),
      SrCard(
        child: SrErrorState(error: const _DemoFailure(0), onRetry: () {}),
      ),
      const SrCard(child: SrErrorState(error: _DemoFailure(403))),
      const SrCard(child: SrErrorState(error: _DemoFailure(404))),
      SrCard(
        child: SrErrorState(
          error: _DemoFailure(409, _s('serverMessage')),
          onRetry: () {},
        ),
      ),
      SrCard(
        child: SrErrorState(error: const _DemoFailure(402), onUpgrade: () {}),
      ),
      SrErrorState(
        error: StateError(_s('boom')),
        compact: true,
        onRetry: () {},
      ),
      const SrCard(child: SrNoAccess()),
      SrCard(
        tone: SrCardTone.gold,
        child: SrPlanLocked(onAction: () {}),
      ),
      const SrSkeletonList(
        count: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
      const SrSkeletonCard(),
    ]);
  }
}

class _AsyncDemo extends StatefulWidget {
  const _AsyncDemo();

  @override
  State<_AsyncDemo> createState() => _AsyncDemoState();
}

class _AsyncDemoState extends State<_AsyncDemo> {
  int _mode = 0;

  AsyncValue<List<String>> get _value => switch (_mode) {
    0 => const AsyncLoading(),
    1 => const AsyncError(_DemoFailure(0), StackTrace.empty),
    2 => const AsyncData([]),
    _ => AsyncData([_s('karimTextiles'), _s('deltaPower'), _s('meghna')]),
  };

  @override
  Widget build(BuildContext context) {
    return _Section('async', [
      SrSegmented(
        compact: true,
        index: _mode,
        onChanged: (i) => setState(() => _mode = i),
        segments: [
          SrSegment(_s('mLoading')),
          SrSegment(_s('mError')),
          SrSegment(_s('mEmpty')),
          SrSegment(_s('mData')),
        ],
      ),
      SizedBox(
        height: 300,
        child: SrAsyncView<List<String>>(
          value: _value,
          onRetry: () => setState(() => _mode = 3),
          isEmpty: (items) => items.isEmpty,
          data: (context, items) => SrRowGroup(
            rows: [
              for (final item in items)
                SrListRow(
                  leading: SrAvatar(name: item),
                  title: item,
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _Selectors extends StatefulWidget {
  const _Selectors();

  @override
  State<_Selectors> createState() => _SelectorsState();
}

class _SelectorsState extends State<_Selectors> {
  int _segment = 0;
  int _day = 2;
  int _month = 9;
  int _status = 0;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final start = DateTime(2026, 10, 2);
    final days = [
      for (var i = 0; i < 7; i++)
        SrDay(
          number: fmt.number(start.add(Duration(days: i)).day),
          label: fmt.weekdayDate(start.add(Duration(days: i))).split(',').first,
          dot: i.isEven,
        ),
    ];
    final months = [
      for (var m = 1; m <= 12; m++)
        fmt.monthYear(DateTime(2026, m)).split(' ').first,
    ];

    return _Section('strips', [
      SrSegmented(
        segments: [
          SrSegment(_s('myLeads'), count: 12),
          SrSegment(_s('pipeline')),
        ],
        index: _segment,
        onChanged: (i) => setState(() => _segment = i),
      ),
      SrDayStrip(
        days: days,
        index: _day,
        onChanged: (i) => setState(() => _day = i),
      ),
      SrMonthStrip(
        months: months,
        index: _month,
        year: fmt.digits('2026'),
        padding: EdgeInsets.zero,
        onYearTap: () {},
        onChanged: (i) => setState(() => _month = i),
      ),
      SrStatusTabs(
        index: _status,
        onChanged: (i) => setState(() => _status = i),
        tabs: [
          SrStatusTab(
            label: _s('open'),
            count: fmt.number(8),
            amount: fmt.moneyCompact(1860000),
          ),
          SrStatusTab(
            label: _s('overdue'),
            count: fmt.number(2),
            amount: fmt.money(42000),
          ),
          SrStatusTab(label: _s('paid'), count: fmt.number(14)),
        ],
      ),
    ]);
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return _Section('progress', [
      const SrProgressBar(value: 0.62),
      SrProgressBar(value: 0.9, color: c.gold),
      SrSegmentBar(
        segments: 4,
        filled: 3,
        current: 2,
        labels: [_s('toContact'), _s('contacted'), _s('interested'), _s('won')],
      ),
      Row(
        children: [
          const SrRing(value: 0.65),
          const SizedBox(width: 16),
          SrRing(value: 0.3, size: 64, thickness: 10, color: c.gold),
          const SizedBox(width: 16),
          SrRing(
            value: 1,
            size: 64,
            thickness: 10,
            child: Icon(Icons.check_rounded, color: c.accent),
          ),
        ],
      ),
      SrSteps(steps: [_s('items'), _s('quantity'), _s('review')], current: 1),
    ]);
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    return _Section('kpis', [
      SrStatGrid(
        tiles: [
          SrKpiTile(
            label: _s('calls'),
            value: fmt.number(5),
            delta: _s('yesterday'),
            deltaUp: false,
            onTap: () {},
          ),
          SrKpiTile(
            label: _s('followUps'),
            value: fmt.number(7),
            delta: _s('more'),
            deltaUp: true,
            upIsGood: false,
          ),
          SrKpiTile(
            label: _s('visits'),
            value: fmt.number(3),
            delta: _s('sameAsUsual'),
          ),
        ],
      ),
      SrStatGrid(
        columns: 2,
        tiles: [
          SrKpiTile(
            label: _s('amount'),
            value: fmt.moneyCompact(1860000),
            big: true,
            tone: SrCardTone.tint,
          ),
          SrKpiTile(
            label: _s('winRate'),
            value: fmt.percent(31),
            delta: fmt.percent(4),
            deltaUp: true,
            big: true,
          ),
        ],
      ),
    ]);
  }
}

class _Notes extends StatelessWidget {
  const _Notes();

  @override
  Widget build(BuildContext context) {
    return _Section('notes', [
      SrNote(message: _s('noteTint')),
      SrNote(message: _s('noteGold'), tone: SrNoteTone.gold),
      SrNote(
        message: _s('noteErr'),
        tone: SrNoteTone.err,
        title: _s('snackError'),
        action: SrButton(
          label: _s('open'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.ghost,
          onPressed: () {},
        ),
      ),
      SrNote(message: _s('noteNeutral'), tone: SrNoteTone.neutral),
    ]);
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return _Section('timeline', [
      SrCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            SrTimelineItem(
              icon: Icons.call_outlined,
              title: _s('tlCall'),
              time: _s('today'),
              subtitle: _s('tlCallSub'),
            ),
            SrTimelineItem(
              icon: Icons.place_outlined,
              iconColor: c.accent,
              title: _s('tlVisit'),
              time: _s('monday'),
              subtitle: _s('tlVisitSub'),
              child: const SrBubbleMedia(
                icon: Icons.photo_outlined,
                height: 60,
              ),
            ),
            SrTimelineItem(
              icon: Icons.description_outlined,
              title: _s('tlQuote'),
              time: _s('sunday'),
              subtitle: _s('tlQuoteSub'),
              last: true,
            ),
          ],
        ),
      ),
    ]);
  }
}

class _Charts extends StatelessWidget {
  const _Charts();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final palette = srChartColors(c);
    final outcome = [
      SrSeries(label: _s('won'), value: 4, color: c.accent),
      SrSeries(label: _s('lost'), value: 9, color: c.danger),
      SrSeries(label: _s('open'), value: 12, color: c.track),
    ];
    final sectors = [
      SrSeries(label: _s('textile'), value: 42, color: palette[0]),
      SrSeries(label: _s('power'), value: 27, color: palette[1]),
      SrSeries(label: _s('retail'), value: 18, color: palette[3]),
    ];
    const weeks = <double>[40, 55, 35, 60, 70, 65, 90, 80];

    return _Section('charts', [
      SrCard(
        child: Row(
          children: [
            SrDonut(
              series: outcome,
              center: SrDonutCenter(
                value: fmt.percent(31),
                label: _s('winRate'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: SrLegend(series: outcome)),
          ],
        ),
      ),
      SrCard(
        child: Row(
          children: [
            SrDonut(series: sectors, size: 80, thickness: 12, gapDegrees: 3),
            const SizedBox(width: 14),
            Expanded(
              child: SrLegend(
                series: sectors,
                valueOf: (s) => fmt.percent(s.value),
              ),
            ),
          ],
        ),
      ),
      SrCard(
        child: Column(
          children: [
            for (final s in sectors) ...[
              SrBarRow(
                label: s.label,
                value: s.value * 10000,
                max: 420000,
                valueLabel: fmt.moneyCompact(s.value * 10000),
                color: s.color,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      SrCard(
        child: SrColumnChart(
          series: [
            for (var i = 0; i < weeks.length; i++)
              SrSeries(label: fmt.number(i + 1), value: weeks[i], dim: i < 5),
          ],
        ),
      ),
      SrCard(
        child: SrColumnChart(showValues: true, height: 60, series: sectors),
      ),
      SrCard(
        child: SrLineChart(
          values: weeks,
          labels: [fmt.number(1), fmt.number(4), fmt.number(8)],
        ),
      ),
    ]);
  }
}

class _PinDemo extends StatefulWidget {
  const _PinDemo();

  @override
  State<_PinDemo> createState() => _PinDemoState();
}

class _PinDemoState extends State<_PinDemo> {
  String _code = '1234';

  @override
  Widget build(BuildContext context) {
    return _Section('pin', [
      SrOtpBoxes(value: _code),
      const SrOtpBoxes(value: '12', obscure: true, error: true),
      SrPinDots(filled: _code.length.clamp(0, 4)),
      const SrPinDots(filled: 4, error: true),
      SrKeypad(
        onDigit: (d) {
          if (_code.length < 6) setState(() => _code += '$d');
        },
        onBackspace: () {
          if (_code.isEmpty) return;
          setState(() => _code = _code.substring(0, _code.length - 1));
        },
      ),
    ]);
  }
}

class _Chat extends StatelessWidget {
  const _Chat();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    return _Section('chat', [
      SrChatBubble(
        text: _s('msg1'),
        sender: _s('karim'),
        time: fmt.time(DateTime(2026, 10, 4, 9, 5)),
      ),
      SrChatBubble(
        text: _s('msg2'),
        mine: true,
        time: fmt.time(DateTime(2026, 10, 4, 9, 7)),
        trailing: Icon(Icons.done_all_rounded, size: 14, color: c.accent),
      ),
      SrChatBubble(
        text: _s('msg3'),
        time: fmt.time(DateTime(2026, 10, 4, 9, 40)),
        media: const SrBubbleMedia(),
      ),
    ]);
  }
}

class _Misc extends StatelessWidget {
  const _Misc({required this.bangla, required this.onLanguage});

  final bool bangla;
  final ValueChanged<bool> onLanguage;

  @override
  Widget build(BuildContext context) {
    return _Section('misc', [
      _Wrap([
        SrLanguageToggle(isBangla: bangla, onChanged: onLanguage),
        const _DeepStrip(),
      ]),
      _Wrap([
        SrButton(
          label: _s('fileError'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SrFileViewer(
                name: _s('pdfName'),
                kind: srFileKindOf(_s('pdfName')),
                meta: _s('pdfSize'),
                webUrl: _s('pdfUrl'),
                load: () => Future.error(const _DemoFailure(0)),
              ),
            ),
          ),
        ),
        SrButton(
          label: _s('comingSoon'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SrComingSoonScreen(title: _s('quotes')),
            ),
          ),
        ),
      ]),
      SrDeferred(
        height: 40,
        child: SrButton(
          label: _s('datePicker'),
          size: SrButtonSize.sm,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: () => unawaited(
            showSrDatePicker(
              context: context,
              initial: DateTime(2026, 10, 4, 11),
              withTime: true,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _DeepStrip extends StatelessWidget {
  const _DeepStrip();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.deep,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SrLanguageToggle(isBangla: false, onDark: true, onChanged: (_) {}),
          const SizedBox(width: 8),
          SrIconButton(icon: Icons.search_rounded, onDark: true, onTap: () {}),
          const SizedBox(width: 8),
          SrIconButton(
            icon: Icons.notifications_none_rounded,
            onDark: true,
            badge: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
