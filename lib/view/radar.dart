/// This file contains the necessary functionality for the PandeVITA
/// radar. The radar implementation is heavily based on
/// https://medium.com/@d.panaite92/building-a-radar-chart-with-flutter-and-custom-painter-384c005002f9
import 'dart:async';
import 'dart:math';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../communication/http_communication.dart';
import '../game_logic/game_logic.dart';
import '../game_logic/game_status.dart';

import 'package:location/location.dart';

class Radar extends StatefulWidget {
  @override
  RadarState createState() => RadarState();
}

class RadarState extends State<Radar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  LocationData? currentLocation;
  final httpClient = PandeVITAHttpClient();
  final Location locationService = Location();

  final GameStatus gameStatus = GameStatus();
  Timer? timer;

  final statusController = Get.find<RequirementStateController>();

  //bool _permission = false;
  String? _serviceError = '';
  late AnimationController _controller;

  //User location for drawing the radar
  LatLng userLocation = LatLng(0, 0);

  StreamSubscription<LocationData>? locationSubscription;

  //Virus locations for drawing the radar
  List<LatLng> virusLocations = [];
  List<LatLng> maskLocations = [];
  List<LatLng> vaccinationLocations = [];

  List<LatLng> collectedMasks = [];
  List<LatLng> collectedVaccines = [];

  int initStateCounter = 0;

  //Customize these
  final int infectionDistance = 1;
  final int maskDistance = 5;
  final int vaccinationDistance = 5;

  //Control variables
  int ticksNearStaticVirus = 0;
  int refreshCounter = 0;

  int dataUpdateTimestamp = 0;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    getVirusPointsList();
    getMaskPointsList();
    getVaccinationPointsList();
    super.initState();
    initStateCounter++;
    debugPrint("initStateCounter $initStateCounter");
    initLocationService();
  }

  @override
  void dispose() {
    _controller.dispose();
    locationSubscription?.cancel();
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('AppLifecycleState radar = $state');
    if (state == AppLifecycleState.resumed) {
      if (locationSubscription != null) {
        if (locationSubscription!.isPaused) {
          locationSubscription?.resume();
        }
      } if (timer != null) {
        if (!timer!.isActive) {
          timer = Timer.periodic(
              const Duration(seconds: 10), (Timer t) => radarLogicTick());
        }
      } else {
        timer = Timer.periodic(
            const Duration(seconds: 10), (Timer t) => radarLogicTick());
      }
    } else if (state == AppLifecycleState.paused) {
      locationSubscription?.cancel();
      timer?.cancel();
    }
  }

  ///When the user collects a mask
  void onMaskCollected(LatLng coordinate) async {
    String coordinateString = coordinate.latitude.toString() + ", " + coordinate.longitude.toString();
    bool newMask = await gameStatus.checkMask(coordinateString);
    if (newMask) {
      collectedMasks.add(coordinate);
      maskLocations.remove(coordinate);
      var snackBar = const SnackBar(
        content: Text("You collected a mask and got 20 immunity for a day"),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  ///When the user collects a vaccine
  void onVaccineCollected(LatLng coordinate) async {
    String coordinateString = coordinate.latitude.toString() + ", " + coordinate.longitude.toString();
    bool newVaccine = await gameStatus.checkVaccination(coordinateString);
    if (newVaccine) {
      collectedVaccines.add(coordinate);
      vaccinationLocations.remove(coordinate);
      var snackBar = const SnackBar(
        content: Text("You collected a vaccine and got 50 immunity for two days"),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: RadarPainter(userLocation, virusLocations, maskLocations,
                  vaccinationLocations),
            );
          }),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: const [
            SizedBox(width: 10),
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.green,
            ),
            SizedBox(width: 5),
            Text("You", style: TextStyle(color: Colors.white, fontSize: 15))
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: const [
            SizedBox(width: 10),
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
            ),
            SizedBox(width: 5),
            Text("Stationary virus",
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: const [
            SizedBox(width: 10),
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.lightBlueAccent,
            ),
            SizedBox(width: 5),
            Text("Mask", style: TextStyle(color: Colors.white, fontSize: 15)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: const [
            SizedBox(width: 10),
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.limeAccent,
            ),
            SizedBox(width: 5),
            Text("Vaccine",
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ]),
          const SizedBox(height: 3)
        ],
      )
    ]);
  }

  /// Initialize the location service for tracking the user.
  void initLocationService() async {
    LocationData? location;
    bool serviceEnabled;
    // bool serviceRequestResult;
    try {
      serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          debugPrint("SERVICE NOT ENABLED RETURN LOCATION");
          return;
        }
      }

      PermissionStatus permissionGranted;

      permissionGranted = await locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          debugPrint("PERMISSION RETURN LOCATION");
          return;
        }
      }
      await locationService.changeSettings(
          accuracy: LocationAccuracy.high, interval: 3000, distanceFilter: 5);

      debugPrint("ALL GOOD LOCATION");

      location = await locationService.getLocation();
      var bk = locationService.isBackgroundModeEnabled();
      debugPrint('locationisbackgroundmodeenabled $bk');
      debugPrint('currentlocation is $location');
      currentLocation = location;
      locationSubscription =
          locationService.onLocationChanged.listen((LocationData result) async {
        debugPrint("newlocation ${result.latitude}");
        if (mounted) {
          setState(() {
            currentLocation = result;
            userLocation =
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
          });
          /*var snackBar = SnackBar(
            content: Text("New location: " + userLocation.toString()),
            duration: const Duration(seconds: 1),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);*/
        }
      });
      timer = Timer.periodic(
          const Duration(seconds: 10), (Timer t) => radarLogicTick());
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
    }
  }

  /// Get the stationary virus locations from the platform.
  Future<bool> getVirusPointsList() async {
    List virusPoints = await httpClient.getVirusPoints();
    if (virusPoints.isEmpty) {
      debugPrint("VIRUS: EMPTY");
      return false;
    } else {
      debugPrint("VIRUS: $virusPoints");
      //Add the virus points to the list supplied to the CustomPainter
      for (Map virusPoint in virusPoints) {
        try {
          var coordinate = virusPoint['coordinate'];
          var splitted = coordinate.split(", ");
          LatLng latLngTemp =
              LatLng(double.parse(splitted[0]), double.parse(splitted[1]));
          virusLocations.add(latLngTemp);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      return true;
    }
  }

  /**
      Get the mask points to display them on the radar
   */
  Future<bool> getMaskPointsList() async {
    List maskPoints = await httpClient.getMaskPoints();
    if (maskPoints.isEmpty) {
      debugPrint("Mask: EMPTY");
      return false;
    } else {
      debugPrint("Mask: $maskPoints");
      for (String maskPoint in maskPoints) {
        try {
          var splitted = maskPoint.split(", ");
          LatLng latLngTemp =
              LatLng(double.parse(splitted[0]), double.parse(splitted[1]));
          maskLocations.add(latLngTemp);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      //Get already collected masks from local memory

      List<String> collectedMasksStrings = await gameStatus.getCollectedMasks();
      for (String coordinateString in collectedMasksStrings) {
        var splitted = coordinateString.split(", ");
        LatLng latLngTemp =
        LatLng(double.parse(splitted[0]), double.parse(splitted[1]));
        collectedMasks.add(latLngTemp);
      }
      for (LatLng coordinate in collectedMasks) {
        if (maskLocations.contains(coordinate)) {
          maskLocations.remove(coordinate);
        }
      }
      return true;
    }
  }

  /**
   *Get the vaccination points to display them on the radar
   */
  Future<bool> getVaccinationPointsList() async {
    List vaccinationPoints = await httpClient.getVaccinationPoints();
    if (vaccinationPoints.isEmpty) {
      debugPrint("Vaccination: EMPTY");
      return false;
    } else {
      debugPrint("Vaccination: $vaccinationPoints");
      for (String vaccinationPoint in vaccinationPoints) {
        try {
          var splitted = vaccinationPoint.split(", ");
          LatLng latLngTemp =
              LatLng(double.parse(splitted[0]), double.parse(splitted[1]));
          vaccinationLocations.add(latLngTemp);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      return true;
    }
  }

  ///Radar logic tick. Runs every 10 seconds when radar is active.
  void radarLogicTick() {
    debugPrint("radarLogicTick");
    const Distance distance = Distance();
    //Virus coordinate logic
    int ticksNearStaticVirusLast = ticksNearStaticVirus;
    for (LatLng virusCoordinate in virusLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, virusCoordinate);

      //Player infected if too close to a static virus point for a minute
      if (distanceFromUser < infectionDistance) {
        ticksNearStaticVirus += 1;
        var snackBar = SnackBar(
          content: Text("Ticks near static virus $ticksNearStaticVirus"),
          duration: const Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        if (ticksNearStaticVirus > 6) {
          statusController.staticVirusNearby();
          ticksNearStaticVirus = 0;
        }
      }
      //If not near a static virus anymore
      if (ticksNearStaticVirusLast == ticksNearStaticVirus) {
        ticksNearStaticVirus = 0;
      }
    }
    //Vaccination coordinate logic
    for (LatLng vaccinationCoordinate in vaccinationLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, vaccinationCoordinate);

      //Logic when getting vaccinated
      if (distanceFromUser < vaccinationDistance) {
        onVaccineCollected(vaccinationCoordinate);
      }
    }

    //Mask coordinate logic
    for (LatLng maskCoordinate in maskLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, maskCoordinate);

      //Logic when getting a mask
      if (distanceFromUser < maskDistance) {
        onMaskCollected(maskCoordinate);
      }


    }
    refreshCounter++;
    //Get updated data from the API every 10 minutes
    if (refreshCounter > 60) {
      refreshCounter = 0;
      getMostRecentData();
      var snackBar = const SnackBar(
        content: Text("New virus, mask and vaccine locations collected"),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    debugPrint("radarLogicTick end");
  }

  //Get most recent data from the API
  getMostRecentData() async {
    //Do not spam the server
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    if (timestamp - dataUpdateTimestamp < 300000) {
      return;
    }
    dataUpdateTimestamp = timestamp;
    await getMaskPointsList();
    await getVirusPointsList();
    await getVaccinationPointsList();
    setState(() {});
  }

}



/// Draws the radar and the virus points near enough the user to be
/// displayed on the radar.
class RadarPainter extends CustomPainter {

  var fps = 0.0;
  List<int> frameTimes = [];
  int lastFrameTimestamp = 0;
  int combinedFrameTimes = 0;


  //Customize this value to change the range of the radar (in meters)
  final int radarRange = 300;





  //Constructor
  RadarPainter(this.userLocation, this.virusLocations, this.maskLocations,
      this.vaccinationLocations);

  //For calculating distance between two coordinates
  final Distance distance = Distance();

  LatLng userLocation;
  List<LatLng> virusLocations;
  List<LatLng> maskLocations;
  List<LatLng> vaccinationLocations;



  var outlinePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..isAntiAlias = true;

  var ticksPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..isAntiAlias = true;

  var virusPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  var playerPaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  var maskPaint = Paint()
    ..color = Colors.lightBlueAccent
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  var vaccinationPaint = Paint()
    ..color = Colors.limeAccent
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {


    var centerX = size.width / 2.0;
    var centerY = size.height / 2.0;
    var centerOffset = Offset(centerX, centerY);
    var radius = centerX * 0.8;

    //The ratio between the range of the radar and the size of the drawn radar
    var metersRatio = radarRange / radius;

    canvas.drawCircle(centerOffset, radius, outlinePaint);

    var ticks = [100, 200, 300];
    var tickDistance = radius / (ticks.length);
    const double tickLabelFontSize = 12;

    ticks.sublist(0, ticks.length - 1).asMap().forEach((index, tick) {
      var tickRadius = tickDistance * (index + 1);

      canvas.drawCircle(centerOffset, tickRadius, ticksPaint);

      TextPainter(
        text: TextSpan(
          text: tick.toString(),
          style:
              const TextStyle(color: Colors.white, fontSize: tickLabelFontSize),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(
            canvas, Offset(centerX, centerY - tickRadius - tickLabelFontSize));
    });

    var features = ["N", "E", "S", "W"];
    var angle = (2 * pi) / features.length;
    const double featureLabelFontSize = 16;
    const double featureLabelFontWidth = 12;

    features.asMap().forEach((index, feature) {
      var xAngle = cos(angle * index - pi / 2);
      var yAngle = sin(angle * index - pi / 2);

      var featureOffset =
          Offset(centerX + radius * xAngle, centerY + radius * yAngle);

      canvas.drawLine(centerOffset, featureOffset, ticksPaint);

      var labelYOffset = yAngle < 0 ? -featureLabelFontSize : 0;
      var labelXOffset = xAngle < 0 ? -featureLabelFontWidth * 1.3 : 0;

      TextPainter(
        text: TextSpan(
          text: feature,
          style: const TextStyle(
              color: Colors.white, fontSize: featureLabelFontSize),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(
            canvas,
            Offset(featureOffset.dx + labelXOffset,
                featureOffset.dy + labelYOffset));
    });

    canvas.drawCircle(centerOffset, 10, playerPaint);

    //Virus coordinate logic
    for (LatLng virusCoordinate in virusLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, virusCoordinate);
      //If the virus point is further away than the range of the radar
      if (distanceFromUser > radarRange) {
        continue;
      }

      //Direction from the user location to the virus point
      double direction =
          (distance.bearing(userLocation, virusCoordinate) - 90) * (pi / 180.0);

      //Distance in the y direction
      double yMeterDistance = sin(direction) * distanceFromUser;
      //Distance in the x direction
      double xMeterDistance = cos(direction) * distanceFromUser;

      var coordinateOffset = Offset(centerX + (xMeterDistance) / metersRatio,
          centerY + (yMeterDistance) / metersRatio);

      canvas.drawCircle(coordinateOffset, 8, virusPaint);
    }

    //Vaccination coordinate logic
    for (LatLng vaccinationCoordinate in vaccinationLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, vaccinationCoordinate);

      //If the vaccination point is further away than the range of the radar
      if (distanceFromUser > radarRange) {
        continue;
      }

      //Direction from the user location to the vaccination point
      double direction =
          (distance.bearing(userLocation, vaccinationCoordinate) - 90) *
              (pi / 180.0);

      //Distance in the y direction
      double yMeterDistance = sin(direction) * distanceFromUser;
      //Distance in the x direction
      double xMeterDistance = cos(direction) * distanceFromUser;

      var coordinateOffset = Offset(centerX + (xMeterDistance) / metersRatio,
          centerY + (yMeterDistance) / metersRatio);

      canvas.drawCircle(coordinateOffset, 8, vaccinationPaint);
    }

    //Mask coordinate logic
    for (LatLng maskCoordinate in maskLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, maskCoordinate);

      //If the mask point is further away than the range of the radar
      if (distanceFromUser > radarRange) {
        continue;
      }

      //Direction from the user location to the mask point
      double direction =
          (distance.bearing(userLocation, maskCoordinate) - 90) * (pi / 180.0);

      //Distance in the y direction
      double yMeterDistance = sin(direction) * distanceFromUser;
      //Distance in the x direction
      double xMeterDistance = cos(direction) * distanceFromUser;

      var coordinateOffset = Offset(centerX + (xMeterDistance) / metersRatio,
          centerY + (yMeterDistance) / metersRatio);

      canvas.drawCircle(coordinateOffset, 8, maskPaint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return true;
  }

}
