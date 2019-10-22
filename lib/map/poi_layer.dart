import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:mobile/map/contextmenu/context_menu.dart';
import 'package:mobile/models/poi.dart';
import 'package:mobile/utils/olc_utils.dart';

import 'poi_tile_provider.dart';

class POILayerPluginOptions extends LayerOptions {
  final POITileProvider tileProvider;

  POILayerPluginOptions({this.tileProvider});
}

class POILayerPlugin implements MapPlugin {
  @override
  Widget createLayer(LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is POILayerPluginOptions) {
      return _POILayer(mapState, stream, options.tileProvider);
    }
    throw Exception('Unknown options type for POILayer'
        'plugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is POILayerPluginOptions;
  }
}

class _POILayer extends StatefulWidget {
  final MapState map;
  final Stream<Null> stream;
  final POITileProvider tileProvider;

  const _POILayer(this.map, this.stream, this.tileProvider);

  @override
  _POILayerState createState() => _POILayerState();
}

class _POILayerState extends State<_POILayer> {
  bool _boundsContainsPOI(CustomPoint<num> pixelPoint) {
    final width = 24;
    final height = 24;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);
    return widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  void _onMarkerTapped(BuildContext context, POI poi) {
    ContextMenu(context, poi).showContextMenu();
  }

  num _normalizedLatitude(num latitude) {
    return latitude < -90.0 ? -90.0 : (90.0 < latitude ? 90.0 : latitude);
  }

  num _normalizedLongitude(num longitude) {
    return (longitude + 180.0) % 360.0 - 180.0;
  }

  void _onTileReady(bool hasData) {
    if (mounted && hasData) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        var markers = <Widget>[];
        var map = widget.map;
        if (map.zoom >= 12) {
          var imageSize = 34 * window.devicePixelRatio;

          var bounds = map.bounds;
          num left;
          num right;
          if (bounds.west < bounds.east) {
            left = (bounds.west * 100.0 / 5.0).floor() * 5 / 100.0;
            right = (bounds.east * 100.0 / 5.0).ceil() * 5 / 100.0;
          } else {
            left = (bounds.east * 100.0 / 5.0).floor() * 5 / 100.0;
            right = (bounds.west * 100.0 / 5.0).ceil() * 5 / 100.0;
          }
          num top;
          num bottom;
          if (bounds.north < bounds.south) {
            top = (bounds.north * 100.0 / 5.0).floor() * 5 / 100.0;
            bottom = (bounds.south * 100.0 / 5.0).ceil() * 5 / 100.0;
          } else {
            top = (bounds.south * 100.0 / 5.0).floor() * 5 / 100.0;
            bottom = (bounds.north * 100.0 / 5.0).ceil() * 5 / 100.0;
          }
          var lat = top;
          while (_normalizedLatitude(lat) <= bottom) {
            var lon = left;
            while (_normalizedLongitude(lon) <= right) {
              var tileId = OLCUtils.encode(_normalizedLatitude(lat), _normalizedLongitude(lon));
              var poiTile = widget.tileProvider.getPOITile(tileId, _onTileReady);
              if (poiTile != null) {
                for (final poi in poiTile.poiList) {
                  try {
                    var pos = map.project(poi.location);
                    if (!_boundsContainsPOI(pos)) {
                      continue;
                    }
                    pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) - map.getPixelOrigin();

                    var pixelPosX = pos.x - imageSize / 2;
                    var pixelPosY = pos.y - imageSize / 2;

                    var mapImgName = poi.getMapImgName();

                    if (map.zoom > 16) {
                      markers.add(
                        Positioned(
                          width: imageSize,
                          height: imageSize,
                          left: pixelPosX,
                          top: pixelPosY,
                          child: Container(
                            child: GestureDetector(
                              onTap: () {
                                _onMarkerTapped(context, poi);
                              },
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: Image(image: AssetImage("assets/map/h_white_orange_poi_shield.png")),
                                  ),
                                  Center(
                                    child: Image(image: AssetImage(mapImgName)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      markers.add(
                        Positioned(
                          width: imageSize,
                          height: imageSize,
                          left: pixelPosX,
                          top: pixelPosY,
                          child: Container(
                            child: GestureDetector(
                              onTap: () {
                                _onMarkerTapped(context, poi);
                              },
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: Image(image: AssetImage("assets/map/map_white_orange_poi_shield_small.png")),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    continue;
                  }
                }
              }
              lon += 0.05;
            }
            lat += 0.05;
          }
        }
        return Container(
          child: Stack(
            children: markers,
          ),
        );
      },
    );
  }
}
