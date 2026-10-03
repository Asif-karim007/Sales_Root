enum ExperienceLevel {
  easy('Easy'),
  standard('Standard'),
  advanced('Advanced');

  const ExperienceLevel(this.wire);

  final String wire;

  static ExperienceLevel? fromWire(String? value) {
    for (final level in values) {
      if (level.wire == value) return level;
    }
    return null;
  }

  bool atLeast(ExperienceLevel other) => index >= other.index;
}
