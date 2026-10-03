import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Starts a fling where the list would already be. Flutter's first ballistic
/// tick lands on the frame after the finger lifts with t = 0, so that frame
/// moved only 10–100% of a drag step; the simulation is advanced by the time
/// the finger has already been off the screen.
class SrScrollPhysics extends ScrollPhysics {
  const SrScrollPhysics({super.parent});

  @override
  SrScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      SrScrollPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    if (simulation == null || simulation is _CatchUpSimulation) {
      return simulation;
    }
    return _CatchUpSimulation(simulation);
  }
}

class _CatchUpSimulation extends Simulation {
  _CatchUpSimulation(this._inner) : super(tolerance: _inner.tolerance);

  static const _maxLead = 1 / 30;

  final Simulation _inner;
  final _sinceLift = Stopwatch()..start();
  double _lead = 0;

  double _shift(double time) {
    if (time == 0) {
      _lead = math.min(_sinceLift.elapsedMicroseconds / 1e6, _maxLead);
    }
    return time + _lead;
  }

  @override
  double x(double time) => _inner.x(_shift(time));

  @override
  double dx(double time) => _inner.dx(_shift(time));

  @override
  bool isDone(double time) => _inner.isDone(_shift(time));
}

/// Uses Flutter's native fractional scroll offsets for both drag and fling.
/// Rounding offsets to physical pixels makes slow movement step between pixels
/// and interferes with the physics simulation near scroll boundaries.
class SrScrollController extends ScrollController {
  SrScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });
}

/// Makes [SrScrollController] the primary controller of everything below it
/// and [SrScrollPhysics] its default physics.
class SrScrollScope extends StatefulWidget {
  const SrScrollScope({super.key, required this.child});

  final Widget child;

  @override
  State<SrScrollScope> createState() => _SrScrollScopeState();
}

class _SrScrollScopeState extends State<SrScrollScope> {
  final _controller = SrScrollController();

  late ScrollBehavior _behavior;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inherited = ScrollConfiguration.of(context);
    _behavior = inherited.copyWith(
      physics: SrScrollPhysics(parent: inherited.getScrollPhysics(context)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: _behavior,
    child: PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    ),
  );
}

/// Once the next frame is laid out, scrolls [context] to the top of its
/// scrollable so whatever just expanded below it comes into view.
void srRevealBelow(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  });
}
