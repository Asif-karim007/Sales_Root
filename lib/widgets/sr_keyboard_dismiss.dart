import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Hides the keyboard when the user taps outside the focused text field, but
/// not when they scroll.
class SrKeyboardDismiss extends StatefulWidget {
  const SrKeyboardDismiss({super.key, required this.child});

  final Widget child;

  @override
  State<SrKeyboardDismiss> createState() => _SrKeyboardDismissState();
}

class _SrKeyboardDismissState extends State<SrKeyboardDismiss> {
  PointerDownEvent? _down;

  late final Map<Type, Action<Intent>> _actions = {
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) => _down = intent.pointerDownEvent,
    ),
    EditableTextTapUpOutsideIntent:
        CallbackAction<EditableTextTapUpOutsideIntent>(onInvoke: _onTapUp),
  };

  void _onTapUp(EditableTextTapUpOutsideIntent intent) {
    final down = _down;
    final up = intent.pointerUpEvent;
    _down = null;
    if (down == null || down.pointer != up.pointer) return;
    if ((up.position - down.position).distance < kTouchSlop) {
      intent.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) =>
      Actions(actions: _actions, child: widget.child);
}
