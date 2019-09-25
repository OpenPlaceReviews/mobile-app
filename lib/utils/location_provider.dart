import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class LocationProvider {
  StreamSubscription<LocationData> _locationSubscription;

  Location _locationService = new Location();
  bool _permission = false;
  String error;

  LocationData _location;
  StreamController<LocationData> _locationChangedController;

  LocationData get location => _location;

  Stream<LocationData> get locationChangedController => _locationChangedController.stream;

  LocationProvider() : _locationChangedController = StreamController<LocationData>.broadcast() {
    initPlatformState();
  }

  void dispose() {
    _locationChangedController.close();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    await _locationService.changeSettings(accuracy: LocationAccuracy.HIGH, interval: 1000);

    LocationData location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      bool serviceStatus = await _locationService.serviceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await _locationService.requestPermission();
        print("Permission: $_permission");
        if (_permission) {
          location = await _locationService.getLocation();
          startUpdates();
        }
      } else {
        bool serviceStatusResult = await _locationService.requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
      location = null;
    }
    _location = location;
    _locationChangedController.sink.add(location);

  }

  void _subscriptToUpdates() {
    _locationSubscription = _locationService.onLocationChanged().listen((LocationData result) async {
      _location = result;
      _locationChangedController.sink.add(result);
    });
  }

  startUpdates() async {
    if (_permission) {
      if (_locationSubscription != null) {
        _locationSubscription.cancel();
      }
      _subscriptToUpdates();
    } else {
      initPlatformState();
    }
  }

  stopUpdates() async {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
  }
}
