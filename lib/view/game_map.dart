/**This file contains classes for the map functionality of the PandeVITA
 * application. This uses flutter_osm_plugin. */
import 'package:flutter/material.dart';
import '../game_logic/game_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class GameMap extends StatefulWidget {
  @override
  GameMapState createState() => GameMapState();
}

class GameMapState extends State<GameMap> with AutomaticKeepAliveClientMixin {
  final controller = Get.find<RequirementStateController>();
  String pointCounter = "0";
  final GameStatus gameStatus = GameStatus();
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition: true,
    );
    zoomIn();
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    return OSMFlutter(
      controller: mapController,
      markerOption: MarkerOption(
        defaultMarker: MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 56,
          ),
        ),
      ),
      trackMyPosition: true,
      initZoom: 17,
      maxZoomLevel: 18,
      minZoomLevel: 13,
      showContributorBadgeForOSM: true,
    );
  }

  @override
  bool get wantKeepAlive => true;

  void zoomIn() async {
    await mapController.setZoom(zoomLevel: 25);
  }
}
