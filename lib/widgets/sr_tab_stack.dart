import 'package:flutter/widgets.dart';

class SrTabStack extends StatefulWidget {
  const SrTabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<SrTabStack> createState() => _SrTabStackState();
}

/// Mirrors `Transition.rightToLeftWithFade`: the incoming tab slides in from
/// the right and fades up while the outgoing one slides off to the left. Both
/// tabs stay laid out so each keeps its scroll position.
class _SrTabStackState extends State<SrTabStack>
    with SingleTickerProviderStateMixin {
  static const _still = AlwaysStoppedAnimation(Offset.zero);
  static const _opaque = AlwaysStoppedAnimation(1.0);

  final Set<int> _visited = {};

  int? _outgoing;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutQuad,
  );

  late final Animation<Offset> _enter = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(_curve);

  late final Animation<Offset> _leave = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1, 0),
  ).animate(_curve);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null) {
      setState(() => _outgoing = null);
    }
  }

  @override
  void didUpdateWidget(SrTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _outgoing = oldWidget.index;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _layer(int i, int? outgoing) {
    final showing = i == widget.index || i == outgoing;

    return KeyedSubtree(
      key: ValueKey(i),
      child: Visibility(
        visible: showing,
        maintainState: true,
        maintainSize: true,
        maintainAnimation: true,
        child: SlideTransition(
          position: i == widget.index
              ? _enter
              : i == outgoing
              ? _leave
              : _still,
          child: FadeTransition(
            opacity: i == widget.index ? _curve : _opaque,
            child: TickerMode(
              enabled: i == widget.index,
              child: RepaintBoundary(
                child: _visited.contains(i)
                    ? widget.children[i]
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _visited.add(widget.index);

    final outgoing = _outgoing;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (i != widget.index && i != outgoing) _layer(i, outgoing),
        if (outgoing != null) _layer(outgoing, outgoing),
        _layer(widget.index, outgoing),
      ],
    );
  }
}
