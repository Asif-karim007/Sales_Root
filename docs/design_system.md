# SalesRoot design system — API reference

Import everything with `import 'package:salesroot/widgets/widgets.dart';`. The visual check is `SrGalleryScreen` (dev menu → Gallery).

## Scaffold and layout
- `SrScaffold({required Widget body, Widget? appBar, Widget? footer, Widget? bottomBar, Widget? floatingAction, Color? backgroundColor, bool safeArea = true, bool resizeToAvoidBottomInset = true})`. It wraps itself in `SrScrollScope`; `footer` goes inside `SrFooter`.
- `SrAppBar({String? title, String? subtitle, Widget? titleWidget, Widget? leading, bool showBack = true, VoidCallback? onBack, List<Widget> actions = const [], Widget? bottom})`
- `SrHeader({required List<Widget> children, bool dark = false, double gap = 12})` (the `.hdr` greeting header) · `SrFooter({required Widget child})` (the `.foot` sticky action bar)
- `SrScrollPhysics`, `SrScrollController`, `SrScrollScope({required Widget child})`, `srRevealBelow(BuildContext)`
- `SrDeferred({double? width, required double height, required Widget child})` builds the child one frame later, in a fixed-size gap. Use it for heavy fixed-size rows.
- `SrKeyboardDismiss({required Widget child})`

## Buttons and controls
- `SrButton({required String label, VoidCallback? onPressed, SrButtonVariant variant = primary, SrButtonSize size = md, IconData? icon, bool loading = false, bool expand = false})`
  - `SrButtonVariant { primary, secondary, ghost, danger, dark }` · `SrButtonSize { sm, md, lg }`
- `SrIconButton({required IconData icon, VoidCallback? onTap, String? tooltip, bool badge = false, int? badgeCount, bool compact = false, bool onDark = false, Color? color})`
- `SrSwitch({required bool value, required ValueChanged<bool>? onChanged})` · `SrCheckbox({same})`. A null `onChanged` means disabled.
- `SrSegment(String label, {int? count})` · `SrSegmented({required List<SrSegment> segments, required int index, required ValueChanged<int> onChanged, bool compact = false})`
- `SrLanguageToggle({required bool isBangla, required ValueChanged<bool> onChanged, bool onDark = false})`
- `SrFab({required VoidCallback onTap, IconData icon = add_rounded, double size = 52, String? tooltip})`

## Cards, rows, avatars, tags
- `SrCard({required Widget child, SrCardTone tone = plain, EdgeInsetsGeometry padding = EdgeInsets.all(14), double radius = 14, VoidCallback? onTap})` · `SrCardTone { plain, tint, gold, dashed }`
- `SrListRow({required String title, String? subtitle, Widget? leading, Widget? trailing, VoidCallback? onTap, VoidCallback? onLongPress, bool chevron = false, bool divider = false, EdgeInsets padding})`
- `SrRowTrailing({String? value, String? meta, Color? valueColor})` · `SrSectionHeader({required String title, String? actionLabel, VoidCallback? onAction, EdgeInsets padding = EdgeInsets.zero})`
- `SrRowGroup({required List<Widget> rows, String? title, VoidCallback? onSeeAll, String? seeAllLabel, double dividerIndent = 16})`
- `SrAvatar({String? name, IconData? icon, String? imageUrl, double size = 38, SrAvatarTone tone = neutral, bool square = false})`
  - `SrAvatarTone { neutral, accent, gold, danger, dark }` · `SrAvatar.initialsOf(String)`
- `SrTone { neutral, accent, ok, warn, err, gold, info, dark }` with `.foreground(SrColors)` / `.background(SrColors)`
- `SrTag(String label, {SrTone tone = neutral, IconData? icon, bool dot = false})` · `SrStagePill({required String label, VoidCallback? onTap, SrTone tone = accent})` · `SrBadge({int? count, SrTone tone = err})` (a null count draws a dot)
- `SrChip({required String label, bool selected = false, VoidCallback? onTap, int? count, SrTone tone = neutral, IconData? icon})`
- `SrChipItem(String label, {int? count, SrTone tone = neutral})` · `SrChipRow({required List<SrChipItem> chips, required int index, required ValueChanged<int> onChanged, EdgeInsets padding = h20})`
- `SrNote({required String message, SrNoteTone tone = tint, IconData? icon, String? title, Widget? action})` · `SrNoteTone { tint, gold, err, neutral }`
- `SrTimelineItem({required IconData icon, required String title, String? time, String? subtitle, Widget? child, Color? iconColor, bool last = false, VoidCallback? onTap})`
- `SrChatBubble({required String text, String? time, bool mine = false, String? sender, Widget? media, Widget? trailing, VoidCallback? onLongPress})` · `SrBubbleMedia({IconData icon, Widget? child, double width = 220, double height = 90, VoidCallback? onTap})`

## Forms and pickers
- `SrTextField({required TextEditingController controller, FocusNode? focusNode, String? label, bool optional = false, String? hint, String? helper, String? error, IconData? prefixIcon, Widget? prefix, Widget? suffix, String? suffixText, bool obscure = false, bool multiline = false, int? maxLength, TextInputType? keyboardType, TextInputAction? textInputAction, TextCapitalization textCapitalization = none, List<TextInputFormatter>? inputFormatters, List<String>? autofillHints, bool autofocus = false, bool enabled = true, bool readOnly = false, VoidCallback? onTap, ValueChanged<String>? onChanged, ValueChanged<String>? onSubmitted})`
- `SrDropdownField({required VoidCallback? onTap, String? value, String? label, bool optional = false, String? placeholder, IconData? icon, String? error, bool enabled = true, IconData trailingIcon})` · `SrFieldLabel(String text, {bool optional = false})`
- `SrPickerField({required VoidCallback onTap, String? value, String? placeholder, IconData? icon, String? label, String? error, bool enabled = true})`
- `SrOptionSheet<T>({required String title, required List<T> options, required String Function(T) labelOf, required bool Function(T) isSelected, String? searchHint, String? Function(T)? subtitleOf, bool withAvatar = false, String? Function(T)? imageOf})`. It pops with a `T`.
- `SrMultiOptionSheet<T>({same as SrOptionSheet})`. It pops with a `List<T>`.
- `SrSearchSheet<T>({required String title, required Future<List<T>> Function(String term, int page) search, required labelOf, required isSelected, int pageSize = 20, searchHint, subtitleOf, withAvatar, imageOf})`
- `SrLookupOption({required int id, required String name, String? subtitle, String? imageUrl})`
  - `SrLookupPicker({required String title, required List<SrLookupOption> options, required int? selected, required ValueChanged<int> onChanged, String? label, String? placeholder, IconData? icon, String? error, bool withAvatar = false})`
  - `SrLookupMultiPicker({...same, required List<int> selected, required ValueChanged<List<int>> onChanged})`
- `Future<DateTime?> showSrDatePicker({required BuildContext context, required DateTime initial, bool withTime = false, DateTime? first, DateTime? last})`
- `SrKeypad({required ValueChanged<int> onDigit, required VoidCallback onBackspace, Widget? extraKey, bool enabled = true})` · `SrOtpBoxes({required String value, int length = 6, bool obscure = false, bool error = false})` · `SrPinDots({required int filled, int length = 4, bool error = false})`

## Sheets, dialogs, snackbars
- `Future<T?> showSrSheet<T>({required BuildContext context, required WidgetBuilder builder, bool isScrollControlled = true, bool isDismissible = true, bool useRootNavigator = true})`
- `SrSheet({required Widget child, String? title, String? subtitle, Widget? trailing, bool showClose = true, EdgeInsets padding})`
- `SrConfirmSheet({required String title, required String message, required String primaryLabel, required VoidCallback onPrimary, String? dangerLabel, VoidCallback? onDanger, String? cancelLabel, IconData icon, SrTone tone = accent, bool destructive = false, List<SrSheetBullet> bullets = const []})` · `SrSheetBullet({required IconData icon, required String text})`
- `Future<bool> showSrConfirm(BuildContext, {required String title, required String message, required String confirmLabel, String? cancelLabel, IconData icon, bool destructive = false})`
- `Future<T> showSrLoader<T>(BuildContext, Future<T> work)`
- `SrAlertDialog({required IconData icon, required String title, required String message, required String actionLabel, required VoidCallback onAction, SrTone tone = warn, IconData? actionIcon, Widget? detail})`
- `showSrSuccessDialog({required BuildContext context, required String title, required String message, String? actionLabel, VoidCallback? onConfirm})` · `showSrNoResponseDialog({required BuildContext context, required Future<void> Function() onRetry})`
- `showSrSnack(BuildContext, String message, {String? title, SrSnackTone tone = info, Duration duration = 3s, SrSnackAction? action})`
  - `showSrSuccess/showSrError/showSrWarning/showSrInfo(BuildContext, String message, {String? title})`
  - `SrSnackAction({required String label, required VoidCallback onPressed})`

## States
- `SrAsyncView<T>({required AsyncValue<T> value, required Widget Function(BuildContext, T) data, WidgetBuilder? loading, VoidCallback? onRetry, VoidCallback? onUpgrade, bool Function(T)? isEmpty, WidgetBuilder? empty})`
- `SrEmptyState({String? title, String? message, IconData icon = inbox_outlined, String? actionLabel, VoidCallback? onAction})`
- `SrErrorState({required Object error, VoidCallback? onRetry, VoidCallback? onUpgrade, bool compact = false})`. It maps `ApiFailure`: 0 is offline, 402 renders `SrPlanLocked`, 403 forbidden, 404 not found.
- `SrNoAccess({String? actionLabel, VoidCallback? onAction})` · `SrPlanLocked({VoidCallback? onAction, String? title, String? message})`
- `SrSkeletonBox({double? width, double? widthFactor, required double height, double radius = 6})` · `SrSkeletonRow({double titleFactor = 0.62})` · `SrSkeletonCard()` · `SrSkeletonList({int count = 6, bool cards = false, bool shrinkWrap = false, EdgeInsets padding})`
- `SrComingSoonScreen({required String title})`

## Strips, progress, KPIs, charts
- `SrYearPill`, `SrMonthStrip({required List<String> months, required int index, required ValueChanged<int> onChanged, String? year, VoidCallback? onYearTap})`, `SrDay({required String number, required String label, bool dot = false})`, `SrDayStrip({required List<SrDay> days, required int index, required ValueChanged<int> onChanged})`, `SrStatusTab({required String label, String? count, String? amount})`, `SrStatusTabs({required List<SrStatusTab> tabs, required int index, required ValueChanged<int> onChanged})`
- `SrTabItem({required IconData icon, required String label, IconData? activeIcon, int? badge})` · `SrTabBar({required List<SrTabItem> items, required int index, required ValueChanged<int> onChanged, VoidCallback? onAdd})` · `SrTabStack({required int index, required List<Widget> children})`
- `SrProgressBar({required double value, Color? color, double height = 6})` · `SrSegmentBar({required int segments, required int filled, List<String> labels = const [], int? current, Color? color})` · `SrRing({required double value, double size = 46, double thickness = 8, Color? color, String? label, Widget? child})` · `SrSteps({required List<String> steps, required int current})`
- `SrKpiTile({required String label, required String value, String? delta, bool? deltaUp, bool upIsGood = true, bool big = false, VoidCallback? onTap, SrCardTone tone = plain})` · `SrStatGrid({required List<Widget> tiles, int columns = 3, double spacing = 10})`
- `SrSeries({required String label, required double value, Color? color, bool dim = false})` · `srChartColors(SrColors)` · `SrDonut({required List<SrSeries> series, double size = 96, double thickness = 15, Widget? center, double gapDegrees = 0, double? total})` · `SrDonutCenter({required String value, String? label})` · `SrLegend({required List<SrSeries> series, String Function(SrSeries)? valueOf})` · `SrBarRow({required String label, required double value, required double max, String? valueLabel, Color? color})` · `SrColumnChart({required List<SrSeries> series, double height = 80, bool showValues = false, bool showLabels = true})` · `SrLineChart({required List<double> values, List<String> labels = const [], double height = 78, int gridLines = 2, Color? color})`

## Files
- `SrFileKind { image, pdf, other }` · `srFileKindOf(String?)` · `SrFileViewer({required String name, required SrFileKind kind, required Future<Uint8List> Function() load, String? title, String meta = '', String? webUrl})`
