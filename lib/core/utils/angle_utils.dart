class AngleUtils {
  static double normalizeDegrees(double angle) {
    final normalized = angle % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}

