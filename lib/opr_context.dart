import 'package:mobile/utils/location_provider.dart';

import 'map/poi_tile_provider.dart';

class OPRContext {
  CachedPOITileProvider _poiTileProvider;
  LocationProvider _locationProvider;

  static final OPRContext _instance = OPRContext._privateConstructor();

  static OPRContext get instance => _instance;

  OPRContext._privateConstructor() {
    _poiTileProvider = CachedPOITileProvider();
    _locationProvider = LocationProvider();
  }

  LocationProvider get locationProvider => _locationProvider;

  CachedPOITileProvider get poiTileProvider => _poiTileProvider;

}