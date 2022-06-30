import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpx/gpx.dart';

class GpxModel extends Gpx{

  LatLng? point;
  bool isWpt;

  GpxModel({
    this.point,
    this.isWpt = false,
  });

  // Map型に変換
  Map toJson() => {
    'lat': wpts[0].lat,
    'lon': point?.longitude,
    // 'ele': ele,
    'name': trks[0].name,
    // 'desc': desc,
  };

  /// JSONオブジェクトを代入
  // WptModel.fromJson(Map json)
  //     : lat = json['lat'],
  //       lon = json['lon'],
  //       ele = json['ele'],
  //       name = json['name'],
  //       desc = json['desc'];
}