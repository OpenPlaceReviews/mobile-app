import 'package:geojson/geojson.dart';
import 'package:latlong/latlong.dart';
import 'package:mobile/helpers/poi_types.dart';
import 'package:mobile/models/poi_type.dart';

class POI {
  final num changeset;
  final num id;
  final LatLng location;
  final String osmTag;
  final String osmValue;
  final Map<String, String> tags;
  final String timeStamp;
  final String osmType;
  final int version;

  POIType type;

/*
"changeset": "51319213",
        "id": "3686990217",
        "lat": "45.4679468",
        "lon": "9.1753917",
        "osm_tag": "amenity",
        "osm_value": "ice_cream",
        "tags": "{
                  addr:city         =Milano,
                  addr:country      =IT,
                  addr:housenumber  =2,
                  addr:postcode     =20123,
                  addr:street       =Via Giovanni Boccaccio,
                  amenity           =ice_cream,
                  email             =milano.cadorna@venchi.com,
                  name              =Venchi,
                  opening_hours     =Mo-Th 07:30-20:00; Fr 07:30-22:00; Sa 11:00-22:00; Su 11:30-20:00,
                  operator          =Venchi spa,
                  phone             =+39 02 4812703,
                  ref:vatin         =IT05744670968
                 }",
        "timestamp": "2017-08-21T20:48:08Z",
        "type": "node",
        "version": "2"
*/

  POI(this.changeset, this.id, this.location, this.osmTag, this.osmValue,
      this.tags, this.timeStamp, this.osmType, this.version) {
    type = POITypes.instance.poiTypes[osmValue];
  }

  factory POI.fromGeoJson(GeoJsonFeature geoJsonFeature) {
    var changsetProp = geoJsonFeature.properties["changeset"];
    var idProp = geoJsonFeature.properties["id"];
    var latProp = geoJsonFeature.properties["lat"];
    var lonProp = geoJsonFeature.properties["lon"];
    var osmTagProp = geoJsonFeature.properties["osm_tag"];
    var osmValueProp = geoJsonFeature.properties["osm_value"];
    var tagsProp = geoJsonFeature.properties["tags"];
    var timestampProp = geoJsonFeature.properties["timestamp"];
    var typeProp = geoJsonFeature.properties["type"];
    var versionProp = geoJsonFeature.properties["version"];
    if (changsetProp == null ||
        idProp == null ||
        latProp == null ||
        lonProp == null ||
        osmTagProp == null ||
        osmValueProp == null ||
        timestampProp == null ||
        typeProp == null ||
        versionProp == null) {
      throw 'Cannot parse GeoJsonFeature.';
    }
    num changeset = num.parse(changsetProp);
    num id = num.parse(idProp);
    LatLng location = LatLng(double.parse(latProp), double.parse(lonProp));
    var tags = <String, String>{};
    if (tagsProp != null && tagsProp is Map) {
      tagsProp.forEach((k,v) => tags[k] = v);
    }
    int version = int.parse(versionProp);
    return new POI(changeset, id, location, osmTagProp, osmValueProp, tags,
        timestampProp, typeProp, version);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is POI && id == other.id;

  @override
  int get hashCode => changeset.hashCode ^ id.hashCode;

  String getName() {
    var name = tags["name"];
    if (name == null || name.isEmpty) {
      if (type != null) {
        name = type.translation;
      } else {
        name = "POI";
      }
    }
    return name;
  }

  String getType() {
    var name = getName();
    if (type != null) {
      if (name == type.translation) {
        return type.category != null ? type.category.translation : "";
      } else {
        return type.translation;
      }
    } else {
      return "";
    }
  }

  String getMapImgName() {
    if (type != null) {
      return "assets/map/mm_${type.keyName}.png";
    } else {
      return "assets/map/mm_null.png";
    }
  }

  @override
  String toString() {
    return "id=$id, changeset=$changeset, location=$location, tag=$osmTag, value=$osmValue, timestamp=$timeStamp, osmType=$osmType, version=$version, type($type)";
  }
}
