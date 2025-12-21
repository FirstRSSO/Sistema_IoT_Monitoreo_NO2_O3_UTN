import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapProvider extends ChangeNotifier {
  LatLng? _targetLocation;
  double? _targetZoom;
  bool _shouldAnimate = false;

  LatLng? get targetLocation => _targetLocation;
  double? get targetZoom => _targetZoom;
  bool get shouldAnimate => _shouldAnimate;

  void animateToLocation(LatLng location, {double zoom = 15.0}) {
    _targetLocation = location;
    _targetZoom = zoom;
    _shouldAnimate = true;
    notifyListeners();
  }

  void resetAnimation() {
    _shouldAnimate = false;
    notifyListeners();
  }
}