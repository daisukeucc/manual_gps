import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manual_gps/view_model/map_vew_model.dart';
import 'package:provider/provider.dart';

class MapPage extends StatelessWidget {

  static const CameraPosition _initPosition = CameraPosition(
    target: LatLng(35.68148019312126, 139.76716771305283),
    zoom: 15,
  );

  @override
  Widget build(BuildContext context) {
    var viewModel = Provider.of<MapViewModel>(context, listen: true);
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initPosition,
        myLocationEnabled: true,
        tiltGesturesEnabled: true,
        compassEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        onTap: (point) => viewModel.setTappedPoint(point),
        onMapCreated: (controller) {
          print("PROCESS: onMapCreated");
          Future<dynamic>.delayed(const Duration(milliseconds: 500)).then(
                  (dynamic _) {
                    controller.animateCamera(CameraUpdate.newLatLngBounds(boundsFromLatLngList(viewModel.boundPoints), 30));
                  }
          );
        },
        markers: Set<Marker>.of(viewModel.markers.values),
        polylines: Set<Polyline>.of(viewModel.polylines.values),
        padding: const EdgeInsets.only(top:20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
          onPressed: viewModel.returnPosition,
          child: const Icon(Icons.location_on)
      ),
    );
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
}