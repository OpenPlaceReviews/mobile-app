import 'dart:io';

import 'package:geojson/geojson.dart';
import 'package:mobile/map/cache_manager.dart';
import 'package:mobile/models/poi.dart';
import 'package:pedantic/pedantic.dart';

typedef POITileReadyCallback = void Function(bool hasData);

class POITile {
  final String id;
  final GeoJsonFeature feature;
  final POITileReadyCallback onTileReady;

  var poiList = <POI>[];

  POITile(this.id, this.feature, this.onTileReady);
}

abstract class POITileProvider {
  const POITileProvider();

  POITile getPOITile(String tileId, POITileReadyCallback onTileReady);

  void dispose();

  String getTileUrl(String tileId) {
    return "https://r1.openplacereviews.org/api/public/geo?tileid=" +
        tileId;
  }
}

class CachedPOITileProvider extends POITileProvider {

  static final int _maxCacheSize = 30;

  final GeoJsonTileCacheManager _manager;
  Map<String, POITile> _tilesMap;

  CachedPOITileProvider()
      : _manager = GeoJsonTileCacheManager(),
        _tilesMap = <String, POITile>{};

  Future<int> getDiskCacheSize() async {
    var filePath = await _manager.getFilePath();
    var stat = await Directory(filePath).stat();
    return stat.size;
  }

  Future<void> emptyCache() async {
    await _manager.emptyCache();
    _clearTiles(all: true);
  }

  @override
  POITile getPOITile(String tileId, POITileReadyCallback onTileReady) {
    var poiTile = _tilesMap[tileId];
    if (poiTile != null) {
      return poiTile;
    }
    _acquirePOITile(tileId, onTileReady);
    return null;
  }

  _acquirePOITile(String tileId, POITileReadyCallback onTileReady) async {
    var poiTile = POITile(tileId, null, onTileReady);
    _tilesMap[tileId] = poiTile;

    if (_tilesMap.length > _maxCacheSize) {
      _clearTiles();
    }
    final file = await _manager.getSingleFile(getTileUrl(tileId));
    final geojson = GeoJson();
    geojson.processedFeatures.listen((GeoJsonFeature feature) {
      poiTile.poiList.add(POI.fromGeoJson(feature));
    });
    geojson.endSignal.listen((_) {
      geojson.dispose();
      if (poiTile.onTileReady != null) {
        poiTile.onTileReady(poiTile.poiList.isNotEmpty);
      }
    });
    unawaited(geojson.parseFile(file.path));
  }

  _clearTiles({bool all = false}) {
    // remove first tiles (as we think they are older)
    var i = 0;
    var k = all ? 0 : _tilesMap.length / 2;
    _tilesMap.forEach((id, tile) => () {
      if (i >= k) {
        tile.poiList.clear();
        _tilesMap.remove(id);
      }
      i++;
    });
  }

  @override
  void dispose() {
    _clearTiles(all: true);
  }
}
