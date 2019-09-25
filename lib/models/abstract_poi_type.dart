import 'package:mobile/helpers/poi_types.dart';

class AbstractPOIType {
  final String keyName;
  final POITypes registry;

  String lang;

  String _enTranslation;
  String _translation;

  AbstractPOIType(this.keyName, this.registry) {
    _enTranslation = keyName.length > 1 ? keyName[0].toUpperCase() + keyName.substring(1).replaceAll("_", " ") : keyName;
    _translation = _enTranslation;
  }

  String get enTranslation => _enTranslation;

  String get translation => _translation;

  @override
  String toString() {
    return "keyName=$keyName";
  }
}
