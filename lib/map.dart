import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:mobile/opr_context.dart';
import 'package:mobile/utils/location_provider.dart';

import 'map/poi_layer.dart';
import 'map/poi_tile_provider.dart';
import 'themes/opr_theme.dart';
import 'themes/opr_themes.dart';
import 'utils/ui_utils.dart';

class MapPage extends StatefulWidget {
  final CachedPOITileProvider poiTileProvider;
  final LocationProvider locationProvider;

  MapPage(this.poiTileProvider, this.locationProvider);

  @override
  _MapPageState createState() => _MapPageState(this.poiTileProvider, this.locationProvider);
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final initLocation = LatLng(52.371881, 4.898207);
  final initZoom = 12.0;

  OPRContext appCtx;
  final CachedPOITileProvider poiTileProvider;
  final LocationProvider locationProvider;

  static const TextStyle selectedOptionStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2f24bc));
  static const TextStyle unselectedOptionStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

  int selectedIndex = 0;

  Marker myPositionMarker;
  double imageSize;
  MapPosition mapPosition;
  MapController mapController;

  StreamSubscription<LocationData> locationSubscription;

  _MapPageState(this.poiTileProvider, this.locationProvider);

  @override
  void initState() {
    super.initState();
    appCtx = OPRContext.instance;
    imageSize = 34 * window.devicePixelRatio;
    mapController = MapController();

    locationSubscription = locationProvider.locationChangedController.listen(onLocationChanged);
  }

  @override
  void dispose() {
    locationSubscription.cancel();
    super.dispose();
  }

  void onLocationChanged(LocationData location) async {
    var marker = Marker(
      width: imageSize,
      height: imageSize,
      point: LatLng(location.latitude, location.longitude),
      builder: (ctx) => Container(
        child: Image(image: AssetImage("assets/img/map_location_available.png")),
      ),
    );
    if (mounted) {
      setState(() {
        myPositionMarker = marker;
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = Tween<double>(begin: mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(begin: mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)), _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _changeTheme(BuildContext buildContext, OPRThemeKeys key) {
    OPRTheme.instanceOf(buildContext).changeTheme(key);
  }

  void onPositionChanged(MapPosition position, bool hasGesture) {
    mapPosition = position;
  }

  void goToMyLocation() {
    var myLocation = locationProvider.location;
    LatLng location = myLocation != null ? LatLng(myLocation.latitude, myLocation.longitude) : null;
    //location = LatLng(50.4475, 30.5216);

    if (location != null) {
      double zoom = 15.0;
      if (mapPosition != null) {
        if (mapPosition.bounds.contains(location)) {
          zoom = mapPosition.zoom;
        }
      }
      _animatedMapMove(location, zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[];
    if (myPositionMarker != null) {
      markers.add(myPositionMarker);
    }
    var myLocation = locationProvider.location;
    LatLng location = myLocation != null ? LatLng(myLocation.latitude, myLocation.longitude) : null;
    if (location == null) {
      location = LatLng(initLocation.latitude, initLocation.longitude);
    }
    double zoom = initZoom;
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: location,
                  zoom: zoom,
                  maxZoom: 21.0,
                  onPositionChanged: onPositionChanged,
                  plugins: [
                    POILayerPlugin(),
                  ],
                ),
                layers: [
                  TileLayerOptions(urlTemplate: 'https://tile.osmand.net/hd/{z}/{x}/{y}.png'),
                  POILayerPluginOptions(tileProvider: poiTileProvider),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MaterialButton(
                    color: OPRTheme.of(context).mapButtonBackgroundColor,
                    child: UIUtils.getImageIcon(context, "ic_location", color: Theme.of(context).accentColor),
                    onPressed: goToMyLocation,
                    shape: CircleBorder(),
                    minWidth: 48,
                    height: 48,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
