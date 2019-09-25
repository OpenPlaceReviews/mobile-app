import 'abstract_poi_type.dart';
import 'poi_category.dart';

class POIType extends AbstractPOIType {
  final POICategory category;

  String osmTag;
  String osmValue;

  POIType(keyName, registry, this.category) : super(keyName, registry);

  POIType.withTagValue(
      keyName, registry, this.category, this.osmTag, this.osmValue)
      : super(keyName, registry);

  @override
  String toString() {
    return super.toString() + ", tag=$osmTag, value=$osmValue, category($category)";
  }
}
