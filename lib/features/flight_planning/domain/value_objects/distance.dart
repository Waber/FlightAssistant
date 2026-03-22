import 'package:flight_assistant/core/errors/app_exception.dart';

class Distance {
  Distance(double nm) : valueNm = nm {
    if (nm < 0) {
      throw AppException('Distance cannot be negative.');
    }
  }

  final double valueNm;
}

