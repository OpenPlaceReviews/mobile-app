import 'package:intl/intl.dart';

class OPRFormatter {
  static String formatDistance(double meters, {bool forceTrailingZeros = true}) {
    String format1 = forceTrailingZeros ? "0.0 " : "0.# ";
    String format2 = forceTrailingZeros ? "0.00 " : "0.## ";
    double mainUnitInMeters = 1000.0;
    var mainUnitStr = "km";
    if (meters >= 100 * mainUnitInMeters) {
      return "${(meters / mainUnitInMeters + 0.5).round()} $mainUnitStr";
    } else if (meters > 9.99 * mainUnitInMeters) {
      return NumberFormat("$format1 $mainUnitStr").format(meters / mainUnitInMeters);
    } else if (meters > 0.999 * mainUnitInMeters) {
      return NumberFormat("$format2 $mainUnitStr").format(meters / mainUnitInMeters);
    } else {
      return "${(meters + 0.5).round()} m";
    }
  }
}
