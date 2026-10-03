import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with the current time every [every], for clocks and
/// worked-time rings.
class FfClockBuilder extends StatefulWidget {
  const FfClockBuilder({
    super.key,
    required this.builder,
    this.every = const Duration(seconds: 30),
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration every;

  @override
  State<FfClockBuilder> createState() => _FfClockBuilderState();
}

class _FfClockBuilderState extends State<FfClockBuilder> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}
