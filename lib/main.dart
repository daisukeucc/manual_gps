import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:geocoding/geocoding.dart';

import 'auth/secrets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final Completer _controller = Completer();
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  late Polyline polyline;
  List<LatLng> tappedPoints = [];
  List<LatLng> boundPoints = [];
  int pointCounter = 0;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    print("INIT_STATE");
    // ファイル共有からのルートセット
    getFile();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription!.cancel();
    super.dispose();
  }

  void _setMarker(List<LatLng> points) {
    markers = {};
    var originLatitude = points.first.latitude;
    var originLongitude = points.first.longitude;
    var destLatitude = points.last.latitude;
    var destLongitude = points.last.longitude;
    _addMarker(LatLng(originLatitude, originLongitude), "origin", BitmapDescriptor.defaultMarker);
    _addMarker(LatLng(destLatitude, destLongitude), "destination", BitmapDescriptor.defaultMarkerWithHue(90));
  }

  Future<void> _setTappedPoint(LatLng point) async {
    _addMarker(LatLng(point.latitude, point.longitude), "point" + pointCounter.toString(), BitmapDescriptor.defaultMarker);
    pointCounter++;
    setState(() {});
    // 初回タップはマーカーセットのみ
    if (tappedPoints.isNotEmpty) {
      List<LatLng> tempPoints = [];
      tempPoints.add(tappedPoints.last);
      tempPoints.add(point);
      _setDirection(tempPoints);
    }
    tappedPoints.add(point);
    // タップした場所の詳細情報取得
    List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
    print(placemarks[0].street);
  }

  void _setLatLngBounds(List<LatLng> points) async {
    // mapController.animateCamera(CameraUpdate.newLatLngBounds(
    //     LatLngBounds(
    //       southwest: LatLng(latLngList.first.latitude, latLngList.first.longitude),
    //       northeast: LatLng(latLngList.last.latitude, latLngList.last.longitude),
    //     ),
    //     30
    // ));
    mapController.animateCamera(CameraUpdate.newLatLngBounds(boundsFromLatLngList(points), 30));
  }

  // Failed assertion: line 77 pos 16: 'southwest.latitude <= northeast.latitude'
  // のエラー回避用メソッド（TODO: 公式で対応されたら修正する）
  LatLngBounds boundsFromLatLngList(List<LatLng> points) {
    assert(points.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in points) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  void _setWayPoint(List<LatLng> points) {
    for (var i = 0; i < points.length; i++) {
      _addMarker(LatLng(points[i].latitude, points[i].longitude), "wpt"+i.toString(), BitmapDescriptor.defaultMarkerWithHue(150));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initPosition,
        // initialCameraPosition: CameraPosition(
        //     target: LatLng(_originLatitude!, _originLongitude!), zoom: 15),
        myLocationEnabled: true,
        tiltGesturesEnabled: true,
        compassEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        onTap: (point) => _setTappedPoint(point),
        // onMapCreated: (GoogleMapController controller) {
        //   _controller.complete(controller);
        // },
        onMapCreated: _onMapCreated,
        markers: Set<Marker>.of(markers.values),
        polylines: Set<Polyline>.of(polylines.values),
        padding: const EdgeInsets.only(top:20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
          onPressed: _returnPosition,
          child: const Icon(Icons.location_on)
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  static const CameraPosition _initPosition = CameraPosition(
    target: LatLng(35.68148019312126, 139.76716771305283),
    zoom: 10,
  );

  Future<void> _goCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // final GoogleMapController controller = await _controller.future;
    CameraPosition _currentPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 17
    );
    mapController.animateCamera(CameraUpdate.newCameraPosition(_currentPosition));
  }

  Future<void> _returnPosition() async {
    _setMarker(boundPoints);
    _setLatLngBounds(boundPoints);
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
            print("SUCCESS: --------------------------");
            response.routes?.forEach((element) {
              element.overviewPath?.forEach((point) {
                polylineCoordinates.add(LatLng(point.latitude, point.longitude));
                // print(point.latitude.toString() + " / " + point.longitude.toString());
              });
            });
          } else {
            // do something with error response
            print("ERROR: $status --------------------------");
          }
        }).then((value) {
      boundPoints = boundPoints + polylineCoordinates;
      _addPolyline(polylineCoordinates);
      _setLatLngBounds(boundPoints);
    });
  }

  void _setPolyLine(String fileData) {

    File(fileData).readAsString().then((String routeStr) {
      var gpxPoints = gpxToLatLng(GpxReader().fromString(routeStr));
      if (gpxPoints.isNotEmpty) {
        _addPolyline(gpxPoints);
        _setMarker(gpxPoints);
        _setLatLngBounds(gpxPoints);
        boundPoints = gpxPoints;
      }
      var wptPoints = gpxToLatLngForWpt(GpxReader().fromString(routeStr));
      if (wptPoints.isNotEmpty) {
        _setWayPoint(wptPoints);
      }
    });
  }

  void _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  void _addPolyline(List<LatLng> points) {
    print("ADD_POLYLINE: --------------------------");
    PolylineId id = PolylineId("poly"+pointCounter.toString());
    pointCounter++;
    polyline = Polyline(polylineId: id, color: Colors.red, points: points, width: 5);
    polylines[id] = polyline;
    setState(() {});
  }

  void getFile() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
          print("FILE: " + value[0].path);
          _setPolyLine(value[0].path);
        }, onError: (err) {
          print("getIntentDataStream error: $err");
          return null;
        });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        print("FILE: " + value[0].path);
        _setPolyLine(value[0].path);
      }
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
          print("TEXT: " + value);
        }, onError: (err) {
          print("getLinkStream error: $err");
        });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      print("TEXT: " + value!);
    });
  }

  List<LatLng> gpxToLatLng(Gpx? gpx) {

    var gpxList = <LatLng>[];

    if (gpx != null) {
      if (gpx.trks.isNotEmpty) {
        for (var i = 0; i < gpx.trks.length; i++) {
          for (var j = 0; j < gpx.trks[i].trksegs.length; j++) {
            for (var k = 0; k < gpx.trks[i].trksegs[j].trkpts.length; k++) {
              var lat = gpx.trks[i].trksegs[j].trkpts[k].lat?.toDouble();
              var lng = gpx.trks[i].trksegs[j].trkpts[k].lon?.toDouble();
              gpxList.add(LatLng(lat!, lng!));
            }
          }
        }
      }
    }
    return gpxList;
  }

  List<LatLng> gpxToLatLngForWpt(Gpx? gpx) {

    var wptList = <LatLng>[];

    if (gpx != null) {
      if (gpx.wpts.isNotEmpty) {
        print(gpx.wpts[0].name);
        for (var i = 0; i < gpx.wpts.length; i++) {
          // print(gpx.wpts[i].lat.toString() + " / " + gpx.wpts[i].lon.toString());
          var lat = gpx.wpts[i].lat?.toDouble();
          var lng = gpx.wpts[i].lon?.toDouble();
          wptList.add(LatLng(lat!, lng!));
        }
      }
    }
    return wptList;
  }

  void stringToGpx(String gpxStr) {

    Gpx gpx = GpxReader().fromString(gpxStr);

    if (gpx.wpts.isNotEmpty) {
      print(gpx.wpts[0].name);
      for (var i = 0; i < gpx.wpts.length; i++) {
        print(gpx.wpts[i].lat.toString() + " / " + gpx.wpts[i].lon.toString());
      }
    } else if (gpx.rtes.isNotEmpty) {
      for (var i = 0; i < gpx.rtes.length; i++) {
        for (var j = 0; j < gpx.rtes[i].rtepts.length; j++) {
          print(gpx.rtes[i].rtepts[j].lat.toString() + " / " + gpx.rtes[i].rtepts[j].lon.toString());
        }
      }
    } else if (gpx.trks.isNotEmpty) {
      for (var i = 0; i < gpx.trks.length; i++) {
        print(gpx.trks[i].name);
        for (var j = 0; j < gpx.trks[i].trksegs.length; j++) {
          for (var k = 0; k < gpx.trks[i].trksegs[j].trkpts.length; k++) {
            print(gpx.trks[i].trksegs[j].trkpts[k].lat.toString() + " / " + gpx.trks[i].trksegs[j].trkpts[k].lon.toString());
          }
        }
      }
    }
  }
}
