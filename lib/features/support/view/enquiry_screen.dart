import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/providers/support_form_providers.dart';
import 'package:salesroot/features/support/view/widget/support_done_sheet.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #118 a custom software, website, ERP or demo enquiry to Nexzen.
class EnquiryScreen extends ConsumerStatefulWidget {
  const EnquiryScreen({super.key, this.kind});

  final EnquiryKind? kind;

  @override
  ConsumerState<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends ConsumerState<EnquiryScreen> {
  late EnquiryKind? _kind = widget.kind;
  final _company = TextEditingController();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _details = TextEditingController();
  CallWindow _window = CallWindow.midday;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider).value;
    final workspace = ref.read(currentWorkspaceProvider);
    _name.text = session?.name ?? '';
    _mobile.text = session?.phone ?? '';
    if (workspace != null && workspace.kind == WorkspaceKind.team) {
      _company.text = workspace.name;
    }
  }

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    _mobile.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickWindow() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<CallWindow>(
      context: context,
      builder: (_) => SrOptionSheet<CallWindow>(
        title: l10n.supportEnquiryTime,
        options: CallWindow.values,
        labelOf: l10n.callWindow,
        isSelected: (window) => window == _window,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _window = picked);
  }

  EnquiryInput get _input => EnquiryInput(
    kind: _kind,
    company: _company.text,
    name: _name.text,
    mobile: _mobile.text,
    details: _details.text,
    callWindow: _window,
  );

  void _send() {
    final input = _input;
    if (input.errors.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    ref.read(enquirySubmitProvider.notifier).submit(input);
  }

  Future<void> _done() async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    await showSupportDoneSheet(
      context,
      title: l10n.supportEnquiryDoneTitle,
      message: l10n.supportEnquiryDoneBody,
    );
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submit = ref.watch(enquirySubmitProvider);
    final errors = _showErrors ? _input.errors : const <EnquiryField>{};
    ref.listen(enquirySubmitProvider, (_, next) {
      if (next.value == true) {
        _done();
      } else if (next.hasError) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.supportEnquiryTitle,
          actions: const [SupportLanguagePill()],
        ),
        footer: SrButton(
          label: l10n.commonSend,
          expand: true,
          loading: submit.isLoading,
          onPressed: _send,
        ),
        body: ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            SrFieldLabel(l10n.supportEnquiryNeed),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final kind in EnquiryKind.values)
                  SrChip(
                    label: l10n.enquiryKind(kind),
                    selected: kind == _kind,
                    onTap: () => setState(() => _kind = kind),
                  ),
              ],
            ),
            if (errors.contains(EnquiryField.kind)) ...[
              const SizedBox(height: 6),
              SrNote(
                tone: SrNoteTone.err,
                message: l10n.supportEnquiryPickKind,
              ),
            ],
            const SizedBox(height: 18),
            SrTextField(
              controller: _company,
              label: l10n.supportEnquiryCompany,
              hint: l10n.supportEnquiryCompanyHint,
              error: errors.contains(EnquiryField.company)
                  ? l10n.commonRequired
                  : null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            SrTextField(
              controller: _name,
              label: l10n.supportEnquiryName,
              error: errors.contains(EnquiryField.name)
                  ? l10n.commonRequired
                  : null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            SrTextField(
              controller: _mobile,
              label: l10n.supportEnquiryMobile,
              hint: l10n.supportEnquiryMobileHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
              ],
              error: errors.contains(EnquiryField.mobile)
                  ? l10n.supportEnquiryMobileError
                  : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            SrTextField(
              controller: _details,
              label: l10n.supportEnquiryDetails,
              hint: l10n.supportEnquiryDetailsHint,
              error: errors.contains(EnquiryField.details)
                  ? l10n.commonRequired
                  : null,
              multiline: true,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            SrDropdownField(
              label: l10n.supportEnquiryTime,
              value: l10n.callWindow(_window),
              icon: Icons.schedule_rounded,
              onTap: _pickWindow,
            ),
          ],
        ),
      ),
    );
  }
}
