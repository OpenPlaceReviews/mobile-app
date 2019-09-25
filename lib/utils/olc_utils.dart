import 'open_location_code.dart' as olc;
import 'open_location_code.dart';

class OLCUtils {
  static final int codeLength = 6;

  /// Encode latitude and longitude in compact {@link OLCUtils#CODE_LENGTH} length string
  /// @param latitude
  /// @param longitude
  /// @return
  static String encode(double latitude, double longitude) {
    return olc
        .encode(latitude, longitude, codeLength: codeLength)
        .substring(0, codeLength);
  }

  /// Decode input in {@link CodeArea} object.
  /// @param code
  /// @return
  static CodeArea decode(String code) {
    while (code.length < 8) {
      code += "00";
    }
    if (code.length < 9) {
      code += "+";
    }
    return olc.decode(code);
  }
}
