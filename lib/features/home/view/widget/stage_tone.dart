import 'package:salesroot/widgets/widgets.dart';

/// The tag tone for a pipeline stage, from cold to won or lost.
SrTone stageTone(int? stageId) => switch (stageId) {
  3 => SrTone.accent,
  4 => SrTone.gold,
  5 => SrTone.ok,
  6 => SrTone.err,
  _ => SrTone.neutral,
};
