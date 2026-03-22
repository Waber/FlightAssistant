class WaypointSequencingService {
  int resolveNextLegIndex({
    required int currentLegIndex,
    required int legsCount,
    required double distanceToNextNm,
    double arrivalThresholdNm = 0.5,
  }) {
    final isLastLeg = currentLegIndex >= legsCount - 1;
    if (isLastLeg) {
      return currentLegIndex;
    }

    if (distanceToNextNm <= arrivalThresholdNm) {
      return currentLegIndex + 1;
    }

    return currentLegIndex;
  }
}

