import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Holds an exactly [width] × [height] gap for one frame and builds [child]
/// in the next, so a list card's buttons are not built in the same frame as
/// the rest of the card. [child] must have that size, or the card would
/// change height a frame after it appears.
class SrDeferred extends StatefulWidget {
  const SrDeferred({
    super.key,
    this.width,
    required this.height,
    required this.child,
  });

  final double? width;
  final double height;
  final Widget child;

  @override
  State<SrDeferred> createState() => _SrDeferredState();
}

class _SrDeferredState extends State<SrDeferred> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => _ready
      ? widget.child
      : SizedBox(width: widget.width, height: widget.height);
}
