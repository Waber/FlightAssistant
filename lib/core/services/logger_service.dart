import 'package:flutter/foundation.dart';

class LoggerService {
  void log(String message) {
    debugPrint('[FlightAssistant] $message');
  }
}

