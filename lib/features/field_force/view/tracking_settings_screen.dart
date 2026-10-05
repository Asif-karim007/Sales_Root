import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_toggle_row.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #130 trackingsettings: the owner's check-in radius, location update
/// interval and check-in selfie.
class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  TrackingSettings? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(trackingSettingsProvider.notifier).save(draft);
      if (!mounted) return;
      showSrSuccess(context, l10n.ffSettingsSaved);
      context.pop();
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(trackingSettingsProvider);
    final draft = _draft ?? settings.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffSettingsTitle,
        actions: const [FfLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.commonSave,
        expand: true,
        loading: _saving,
        onPressed: _draft == null || _saving ? null : _save,
      ),
      body: FieldForceGate(
        module: AppModule.liveTracking,
        right: ModuleRight.edit,
        child: switch (settings) {
          AsyncValue(hasValue: true) when draft != null => _SettingsForm(
            settings: draft,
            onChanged: (next) => setState(() => _draft = next),
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(trackingSettingsProvider),
          ),
          _ => const SrSkeletonList(count: 6),
        },
      ),
    );
  }
}

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({required this.settings, required this.onChanged});

  final TrackingSettings settings;
  final ValueChanged<TrackingSettings> onChanged;

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) labelOf,
    required TrackingSettings Function(T) apply,
  }) async {
    final picked = await showSrSheet<T>(
      context: context,
      builder: (_) => SrOptionSheet<T>(
        title: title,
        options: options,
        labelOf: labelOf,
        isSelected: (o) => o == current,
      ),
    );
    if (picked != null) onChanged(apply(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    String update(int seconds) => seconds == 0
        ? l10n.ffUpdateOff
        : l10n.ffUpdateEvery(fmt.number(seconds ~/ 60));

    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              SrDropdownField(
                label: l10n.ffRadius,
                value: context.ffDistance(settings.geofenceMetres),
                onTap: () => _pick<int>(
                  context,
                  title: l10n.ffRadius,
                  options: TrackingSettings.radiusChoices,
                  current: settings.geofenceMetres,
                  labelOf: context.ffDistance,
                  apply: (v) => settings.copyWith(geofenceMetres: v),
                ),
              ),
              const SizedBox(height: 10),
              SrDropdownField(
                label: l10n.ffUpdateInterval,
                value: update(settings.trackIntervalSeconds),
                onTap: () => _pick<int>(
                  context,
                  title: l10n.ffUpdateInterval,
                  options: TrackingSettings.intervalChoices,
                  current: settings.trackIntervalSeconds,
                  labelOf: update,
                  apply: (v) => settings.copyWith(trackIntervalSeconds: v),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FfToggleRow(
            title: l10n.ffSelfieOnCheckIn,
            subtitle: l10n.ffSelfieOnCheckInHint,
            value: settings.selfieOnCheckIn,
            divider: false,
            onChanged: (v) => onChanged(settings.copyWith(selfieOnCheckIn: v)),
          ),
        ),
        const SizedBox(height: 12),
        SrNote(message: l10n.ffSettingsNotify),
      ],
    );
  }
}
