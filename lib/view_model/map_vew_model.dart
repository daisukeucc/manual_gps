import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manual_gps/repository/coordinate_repository.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '/auth/secrets.dart';

class MapViewModel extends ChangeNotifier {

  final CoordinateRepository _repository;
  StreamSubscription? _intentDataStreamSubscription;
  Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  final List<LatLng> _tappedPoints = [];
  final List<LatLng> _boundPoints = [];
  late Polyline _polyline;
  int _pointCounter = 0;

  Map<MarkerId, Marker> get markers => _markers;
  Map<PolylineId, Polyline> get polylines => _polylines;
  List<LatLng> get tappedPoints => _tappedPoints;
  List<LatLng> get boundPoints => _boundPoints;

  MapViewModel(this._repository) {
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> file) async {
          if (file.isNotEmpty) {
            var points = await _repository.getCoordinates(file[0].path);
            _boundPoints.addAll(points);
            _addPolyline(points);
            _setMarker(points);
          }
          log('$runtimeType#getMediaStream: $file', name: 'SUCCESS');
        }, onError: (err) {
          log('$runtimeType#getMediaStream: $err', name: 'ERROR');
        });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> file) async {
      if (file.isNotEmpty) {
        var points = await _repository.getCoordinates(file[0].path);
        _boundPoints.addAll(points);
        _addPolyline(points);
        _setMarker(points);
      }
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
          log('$runtimeType#getTextStream: $value', name: 'SUCCESS');
        }, onError: (err) {
          log('$runtimeType#getTextStream: $err', name: 'ERROR');
        });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        log('$runtimeType#getInitialText: $value', name: 'SUCCESS');
      }
    });
  }

  void _addPolyline(List<LatLng> points) {
    PolylineId id = PolylineId("poly"+_pointCounter.toString());
    _pointCounter++;
    _polyline = Polyline(polylineId: id, color: Colors.red, points: points, width: 5);
    _polylines[id] = _polyline;
    notifyListeners();
    log('$runtimeType#_addPolyline', name: 'DEBUG');
  }

  void _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: position);
    _markers[markerId] = marker;
    notifyListeners();
  }

  void _setMarker(List<LatLng> points) {
    _markers = {};
    var originLatitude = points.first.latitude;
    var originLongitude = points.first.longitude;
    var destLatitude = points.last.latitude;
    var destLongitude = points.last.longitude;
    _addMarker(LatLng(originLatitude, originLongitude), "origin", BitmapDescriptor.defaultMarker);
    _addMarker(LatLng(destLatitude, destLongitude), "destination", BitmapDescriptor.defaultMarkerWithHue(90));
    notifyListeners();
  }

  void _setWayPoint(List<LatLng> points) {
    for (var i = 0; i < points.length; i++) {
      _addMarker(LatLng(points[i].latitude, points[i].longitude), "wpt"+i.toString(), BitmapDescriptor.defaultMarkerWithHue(150));
    }
  }

  Future<void> setTappedPoint(LatLng point) async {
    _addMarker(LatLng(point.latitude, point.longitude), "point" + _pointCounter.toString(), BitmapDescriptor.defaultMarker);
    _pointCounter++;
    // 初回タップはマーカーセットのみ
    if (_tappedPoints.isNotEmpty) {
      List<LatLng> tempPoints = [];
      tempPoints.add(_tappedPoints.last);
      tempPoints.add(point);
      _setDirection(tempPoints);
    }
    _tappedPoints.add(point);

    // タップした場所の詳細情報取得
    // List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
    // print(placemarks[0].street);
  }

  void _setDirection(List<LatLng> points) {

    DirectionsService.init(google_map_api_key);

    final directinosService = DirectionsService();

    var startLat = points.first.latitude;
    var startLng = points.first.longitude;
    var destLat = points.last.latitude;
    var destLng = points.last.longitude;

    var request = DirectionsRequest(
      origin: '$startLat, $startLng',
      destination: '$destLat, $destLng',
      travelMode: TravelMode.walking,
    );

    List<LatLng> polylineCoordinates = [];

    directinosService.route(request,
            (DirectionsResult response, DirectionsStatus? status) {
          if (status == DirectionsStatus.ok) {
            // do something with successful response
            response.routes?.forEach((element) {
              element.overviewPath?.forEach((point) {
                polylineCoordinates.add(LatLng(point.latitude, point.longitude));
                // print(point.latitude.toString() + " / " + point.longitude.toString());
              });
            });
            log('$runtimeType#route: $status', name: 'SUCCESS');
          } else {
            // do something with error response
            log('$runtimeType#route: $status', name: 'ERROR');
          }
        }).then((value) {
      // boundPoints = boundPoints + polylineCoordinates;
      _addPolyline(polylineCoordinates);
      // _setLatLngBounds(boundPoints);
    });
  }

  Future<void> returnPosition() async {
    // _setMarker(boundPoints);
    // _setLatLngBounds(boundPoints);
  }

  @override
  void dispose() {
    super.dispose();
    _intentDataStreamSubscription?.cancel();
    log('$runtimeType#dispose', name: 'DEBUG');
  }
}