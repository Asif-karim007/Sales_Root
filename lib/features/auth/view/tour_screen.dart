import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/auth_link.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #7: three pages on why SalesRoot, then the feature list.
class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(int count) {
    if (_index == count - 1) {
      context.go(Routes.features);
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (Icons.contacts_outlined, l10n.authTour1Title, l10n.authTour1Body),
      (
        Icons.notifications_active_outlined,
        l10n.authTour2Title,
        l10n.authTour2Body,
      ),
      (Icons.groups_outlined, l10n.authTour3Title, l10n.authTour3Body),
    ];

    return SrScaffold(
      footer: SrButton(
        label: l10n.authTourNext,
        expand: true,
        onPressed: () => _next(pages.length),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const AuthLanguageToggle(),
                const SizedBox(width: 8),
                AuthLink(
                  label: l10n.commonSkip,
                  size: 14,
                  onTap: () => context.go(Routes.features),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (index) => setState(() => _index = index),
              children: [
                for (final (icon, title, body) in pages)
                  _TourPage(icon: icon, title: title, body: body),
              ],
            ),
          ),
          _Dots(count: pages.length, index: _index),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  const _TourPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: c.tint,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(icon, size: 64, color: c.accent),
          ),
          const SizedBox(height: 24),
          AuthIntro(center: true, title: title, lead: Text(body)),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? c.accent : c.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
