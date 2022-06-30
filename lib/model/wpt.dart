import 'package:gpx/gpx.dart';

class WptModel extends Wpt {

  double? lat;
  double? lon;
  double? ele;
  String? name;
  String? desc;

  WptModel({
    this.lat = 0.0,
    this.lon = 0.0,
    this.ele,
    this.name,
    this.desc,
  });

  // Map型に変換
  Map toJson() => {
    'lat': lat,
    'lon': lon,
    'ele': ele,
    'name': name,
    'desc': desc,
  };

  /// JSONオブジェクトを代入
  WptModel.fromJson(Map json)
      : lat = json['lat'],
        lon = json['lon'],
        ele = json['ele'],
        name = json['name'],
        desc = json['desc'];
}