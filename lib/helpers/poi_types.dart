import 'package:mobile/models/poi_category.dart';
import 'package:mobile/models/poi_type.dart';

class POITypes {
  final _poiTypes = <String, POIType>{};

  static final POITypes _instance = POITypes._privateConstructor();

  static POITypes get instance => _instance;

  POITypes._privateConstructor() {
    var food = POICategory("food", this);
    var hotel = POICategory("hotel", this);

    _poiTypes["cafe"] = POIType.withTagValue("cafe", this, food, "amenity", "cafe");
    _poiTypes["bar"] = POIType.withTagValue("bar", this, food, "amenity", "bar");
    _poiTypes["restaurant"] = POIType.withTagValue("restaurant", this, food, "amenity", "restaurant");
    _poiTypes["biergarten"] = POIType.withTagValue("biergarten", this, food, "amenity", "biergarten");
    _poiTypes["fast_food"] = POIType.withTagValue("fast_food", this, food, "amenity", "fast_food");
    _poiTypes["ice_cream"] = POIType.withTagValue("ice_cream", this, food, "amenity", "ice_cream");
    _poiTypes["pub"] = POIType.withTagValue("pub", this, food, "amenity", "pub");

    _poiTypes["hotel"] = POIType.withTagValue("hotel", this, hotel, "tourism", "hotel");
    _poiTypes["motel"] = POIType.withTagValue("motel", this, hotel, "tourism", "motel");
    _poiTypes["hostel"] = POIType.withTagValue("hostel", this, hotel, "tourism", "hostel");
    _poiTypes["apartment"] = POIType.withTagValue("apartment", this, hotel, "tourism", "apartment");
    _poiTypes["guest_house"] = POIType.withTagValue("guest_house", this, hotel, "tourism", "guest_house");
  }

  get poiTypes => Map.unmodifiable(_poiTypes);

}
