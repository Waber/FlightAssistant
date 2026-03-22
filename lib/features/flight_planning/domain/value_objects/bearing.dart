import 'package:flight_assistant/core/utils/angle_utils.dart';

class Bearing {
  Bearing(double degrees) : value = AngleUtils.normalizeDegrees(degrees);

  final double value;
}

