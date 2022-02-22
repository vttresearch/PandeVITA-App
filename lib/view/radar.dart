/** This file contains the necessary functionality for the PandeVITA
 * radar. The radar implementation is heavily based on
 * https://medium.com/@d.panaite92/building-a-radar-chart-with-flutter-and-custom-painter-384c005002f9
 */
import 'dart:async';
import 'dart:math';


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:latlong2/latlong.dart';
import '../communication/http_communication.dart';

import 'package:location/location.dart';

class Radar extends StatefulWidget {
  @override
  RadarState createState() => RadarState();
}

class RadarState extends State<Radar> with TickerProviderStateMixin {
  LocationData? currentLocation;
  final httpClient = PandeVITAHttpClient();
  final Location locationService = Location();

  bool _permission = false;
  String? _serviceError = '';
  late AnimationController _controller;

  //User location for drawing the radar
  LatLng userLocation = LatLng(0, 0);

  //Virus locations for drawing the radar
  List<LatLng> virusLocations = [];

  int initStateCounter = 0;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..repeat();
    getVirusPointsList();
    super.initState();
    initStateCounter++;
    print("initStateCounter $initStateCounter");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: RadarPainter(userLocation, virusLocations),
          );
        });
  }

  /**
   * Initialize the location service for tracking the user.
   */
  void initLocationService() async {
    await locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await locationService.serviceEnabled();

      if (serviceEnabled) {
        var permission = await locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await locationService.getLocation();
          currentLocation = location;
          locationService.onLocationChanged.listen((LocationData result) async {
            if (mounted) {
              setState(() {
                currentLocation = result;
                userLocation = LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!);
              });
            }
          });
        }
      } else {
        serviceRequestResult = await locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
    }
  }

  /**
   * Get the stationary virus locations from the platform.
   */
  Future<bool> getVirusPointsList() async {
    List virusPoints = await httpClient.getVirusPoints();
    if (virusPoints.isEmpty) {
      print("VIRUS: EMPTY");
      return false;
    } else {
      print("VIRUS: $virusPoints");
      //Add the virus points to the list supplied to the CustomPainter
      for (Map virusPoint in virusPoints) {
        try {
          var coordinate = virusPoint['coordinate'];
          var splitted = coordinate.split(", ");
          LatLng latLngTemp =
          LatLng(double.parse(splitted[0]), double.parse(splitted[1]));
          virusLocations.add(latLngTemp);
        } catch (e) {
          print(e.toString());
        }
      }
      return true;
    }
  }
}

/**
 * Draws the radar and the virus points near enough the user to be
 * displayed on the radar.
 */
class RadarPainter extends CustomPainter {
  //Customize this value to change the range of the radar (in meters)
  final int radarRange = 300;

  //Constructor
  RadarPainter(this.userLocation, this.virusLocations);

  //For calculating distance between two coordinates
  final Distance distance = Distance();

  LatLng userLocation;
  List<LatLng> virusLocations;

  var outlinePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..isAntiAlias = true;

  var ticksPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..isAntiAlias = true;

  var virusPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  var playerPaint = Paint()
    ..color = Colors.blueAccent
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
          const TextStyle(color: Colors.grey, fontSize: tickLabelFontSize),
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
      var labelXOffset =
      xAngle < 0 ? -featureLabelFontWidth * feature.length : 0;

      TextPainter(
        text: TextSpan(
          text: feature,
          style: const TextStyle(
              color: Colors.black, fontSize: featureLabelFontSize),
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

    for (LatLng virusCoordinate in virusLocations) {
      //distance from the user
      double distanceFromUser = distance(userLocation, virusCoordinate);

      //If the virus point is further away than the range of the radar
      if (distanceFromUser > radarRange) {
        continue;
      }
      //Direction from the user location to the virus point
      double direction = (distance.bearing(userLocation, virusCoordinate) -
          90) * (pi / 180.0);

      //Distance in the y direction
      double yMeterDistance = sin(direction)*distanceFromUser;
      //Distance in the x direction
      double xMeterDistance = cos(direction)*distanceFromUser;

      var coordinateOffset = Offset(centerX + (xMeterDistance) / metersRatio,
          centerY + (yMeterDistance) / metersRatio);

      canvas.drawCircle(coordinateOffset, 8, virusPaint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return true;
  }
}
