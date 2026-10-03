import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_toggle_row.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/features/field_force/view/widget/visit_captured.dart';
import 'package:salesroot/features/field_force/view/widget/visit_summary.dart';
import 'package:salesroot/features/field_force/view/widget/visit_tiles.dart';
import 'package:salesroot/features/field_force/view/widget/minute_builder.dart';
import 'package:salesroot/features/field_force/view/widget/voice_button.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #124 visitprogress: the running visit — timer, notes, photos, samples —
/// and the check-out with its outcome. A finished visit shows its summary.
class VisitProgressScreen extends ConsumerStatefulWidget {
  const VisitProgressScreen({super.key, required this.visitId});

  final int visitId;

  @override
  ConsumerState<VisitProgressScreen> createState() =>
      _VisitProgressScreenState();
}

class _VisitProgressScreenState extends ConsumerState<VisitProgressScreen> {
  final _note = TextEditingController();
  VisitOutcome? _outcome;
  bool _followUp = true;
  bool _checkingOut = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _checkOut(Visit visit) async {
    final l10n = context.l10n;
    final canTask = ref.read(moduleAccessProvider(AppModule.task)).canAdd;
    setState(() => _checkingOut = true);
    try {
      final ended = await ref
          .read(visitDetailProvider(widget.visitId).notifier)
          .checkOut(outcome: _outcome, note: _note.text);
      if (!mounted) return;
      showSrSuccess(
        context,
        ended.outcome == VisitOutcome.ignored
            ? l10n.ffCheckedOutIgnored
            : l10n.ffCheckedOutVisit,
      );
      final lead = visit.lead;
      if (_followUp && canTask && lead != null) {
        context.pushReplacement(
          Uri(
            path: Routes.taskNew,
            queryParameters: {
              'leadId': '${lead.id}',
              'title': l10n.ffFollowUpTitle(visit.title),
            },
          ).toString(),
        );
      } else {
        context.pop();
      }
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = ref.watch(visitDetailProvider(widget.visitId));
    final visit = detail.value;
    final canTask = ref.watch(
      moduleAccessProvider(AppModule.task).select((a) => a.canAdd),
    );

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffVisitTitle,
        subtitle: visit?.title,
        actions: const [FfLanguageToggle()],
      ),
      footer: switch (visit?.status) {
        VisitStatus.inProgress => SrButton(
          label: l10n.ffCheckOut,
          icon: Icons.logout_rounded,
          expand: true,
          loading: _checkingOut,
          onPressed: visit == null || _checkingOut
              ? null
              : () => _checkOut(visit),
        ),
        VisitStatus.planned => SrButton(
          label: l10n.ffCheckIn,
          icon: Icons.login_rounded,
          expand: true,
          onPressed: () =>
              context.pushReplacement(Routes.visitCheckInFor(widget.visitId)),
        ),
        _ => null,
      },
      body: FieldForceGate(
        module: AppModule.visit,
        child: switch (detail) {
          AsyncValue(:final value?) => _VisitBody(
            visit: value,
            outcome: _outcome,
            note: _note,
            followUp: _followUp && canTask,
            canFollowUp: canTask && value.lead != null,
            onOutcome: (o) =>
                setState(() => _outcome = o == _outcome ? null : o),
            onFollowUp: (v) => setState(() => _followUp = v),
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(visitDetailProvider(widget.visitId)),
          ),
          _ => const SrSkeletonList(count: 4, cards: true),
        },
      ),
    );
  }
}

class _VisitBody extends StatelessWidget {
  const _VisitBody({
    required this.visit,
    required this.outcome,
    required this.note,
    required this.followUp,
    required this.canFollowUp,
    required this.onOutcome,
    required this.onFollowUp,
  });

  final Visit visit;
  final VisitOutcome? outcome;
  final TextEditingController note;
  final bool followUp;
  final bool canFollowUp;
  final ValueChanged<VisitOutcome> onOutcome;
  final ValueChanged<bool> onFollowUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = visit.isOpen;
    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        if (open) _TimerCard(visit: visit) else VisitSummary(visit: visit),
        if (open) ...[
          const SizedBox(height: 16),
          SrSectionHeader(title: l10n.ffDuringVisit),
          const SizedBox(height: 8),
          VisitTiles(visit: visit),
        ],
        VisitCaptured(visit: visit),
        if (open) ...[
          const SizedBox(height: 16),
          SrFieldLabel(l10n.ffOutcome),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final choice in VisitOutcome.choices)
                SrChip(
                  label: outcomeLabel(l10n, choice),
                  selected: choice == outcome,
                  onTap: () => onOutcome(choice),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SrTextField(
            controller: note,
            label: l10n.ffWhatHappened,
            hint: l10n.ffWhatHappenedHint,
            helper: outcome == null ? l10n.ffOutcomeBlankHint : null,
            multiline: true,
            textCapitalization: TextCapitalization.sentences,
            suffix: FfVoiceButton(controller: note),
          ),
          if (canFollowUp) ...[
            const SizedBox(height: 4),
            FfToggleRow(
              title: l10n.ffNextFollowUp,
              subtitle: l10n.ffNextFollowUpHint,
              value: followUp,
              onChanged: onFollowUp,
              divider: false,
            ),
          ],
        ],
      ],
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final started = visit.start?.time;
    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: FfClockBuilder(
        every: const Duration(seconds: 15),
        builder: (context, now) => Column(
          children: [
            Text(l10n.ffVisitInProgress, style: AppText.label(c.ink2)),
            const SizedBox(height: 6),
            Text(
              context.ffClockDuration(
                started == null ? 0 : now.difference(started).inMinutes,
              ),
              style: AppText.metric(c.ink, size: 36),
            ),
            const SizedBox(height: 6),
            Text(
              started == null
                  ? visit.title
                  : l10n.ffCheckedInLine(
                      visit.title,
                      context.fmt.time(started),
                    ),
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink2),
            ),
            if (visit.isFarCheckIn) ...[
              const SizedBox(height: 8),
              SrTag(
                l10n.ffFarFlag(context.ffDistance(visit.checkInDistance ?? 0)),
                tone: SrTone.warn,
                icon: Icons.wrong_location_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
