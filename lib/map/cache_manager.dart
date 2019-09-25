import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class GeoJsonTileCacheManager extends BaseCacheManager {
  static const key = "geoJsonTileCache";

  static GeoJsonTileCacheManager _instance;

  factory GeoJsonTileCacheManager() {
    if (_instance == null) {
      _instance = new GeoJsonTileCacheManager._();
    }
    return _instance;
  }

  GeoJsonTileCacheManager._() : super(key,
      maxAgeCacheObject: Duration(days: 7),
      maxNrOfCacheObjects: 20,
      fileFetcher: _customHttpGetter);

  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }

  static Future<FileFetcherResponse> _customHttpGetter(String url, {Map<String, String> headers}) async {
    // Do things with headers, the url or whatever.
    return HttpFileFetcherResponse(await http.get(url, headers: headers));
  }
}
