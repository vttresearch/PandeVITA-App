/**This file contains classes for the map functionality of the PandeVITA
 * application. This uses flutter_osm_plugin. */
import 'package:flutter/material.dart';
import '../game_logic/game_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../communication/http_communication.dart';

class GameMap extends StatefulWidget {
  @override
  GameMapState createState() => GameMapState();
}

class GameMapState extends State<GameMap> with AutomaticKeepAliveClientMixin {
  final controller = Get.find<RequirementStateController>();
  String pointCounter = "0";
  final GameStatus gameStatus = GameStatus();
  late MapController mapController;
  List<GeoPoint> maskPointsList = [];
  final httpClient = PandeVITAHttpClient();

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition: true,
    );
    zoomIn();
    displayMaskPointsOnMap();
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

  void displayMaskPointsOnMap() async {
    if (maskPointsList.isEmpty) {
      print("MASK: asking masks from server");
      if (await getMaskPointsList()) {
        for (GeoPoint maskPoint in maskPointsList) {
          await mapController.addMarker(maskPoint, markerIcon:
          MarkerIcon(image: AssetImage('images/mask_icon.png')));
        }
      }
    }

  }

  //Get the mask points to display them on the map
  Future<bool> getMaskPointsList() async {
    print("MASK: asking 2");
    List maskPoints = await httpClient.getMaskPoints();
    if (maskPoints.isEmpty) {
      print("Mask: EMPTY");
      return false;
    } else {
      print("Mask: $maskPoints");
      for (String maskPoint in maskPoints) {
        try {
          var splitted = maskPoint.split(", ");
          GeoPoint geoPointTemp = GeoPoint(
              latitude: double.parse(splitted[0]),
              longitude: double.parse(splitted[1]));
          maskPointsList.add(geoPointTemp);
        } catch (e) {
          print(e.toString());
        }
      }
      return true;
    }
  }
}
