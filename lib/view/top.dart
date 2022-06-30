import 'package:flutter/material.dart';
import 'package:manual_gps/view/map.dart';
import 'package:manual_gps/repository/coordinate_repository.dart';
import 'package:manual_gps/view_model/map_vew_model.dart';
import 'package:provider/provider.dart';

class TopPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MapViewModel>(
      create: (_) {
        var coordinateRepository = CoordinateRepositoryImpl();
        return MapViewModel(coordinateRepository);
      },
      child: MapPage(),
    );
  }
}