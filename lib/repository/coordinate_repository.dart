import 'dart:async';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpx/gpx.dart';

abstract class CoordinateRepository {
  Future<List<LatLng>> getCoordinates(String filePath);
}

class CoordinateRepositoryImpl implements CoordinateRepository {

  @override
  Future<List<LatLng>> getCoordinates(String filePath) async {
    var xmlStr = await File(filePath).readAsString();
    return _xmlToLatLng(xmlStr);
  }

  List<LatLng> _xmlToLatLng(String xmlStr) {
    var gpx = GpxReader().fromString(xmlStr);
    List<LatLng> coordinates = [];

    for (var trk in gpx.trks) {
      for (var seg in trk.trksegs) {
        for (var pt in seg.trkpts) {
          coordinates.add(LatLng(pt.lat!, pt.lon!));
        }
      }
    }
    return coordinates;
  }
}