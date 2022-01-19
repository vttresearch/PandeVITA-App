import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get_connect/http/src/status/http_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';

/** This class handles the scanning for nearby devices.
    Based on the example implementation of flutter_beacon. */
class BeaconScanner {
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<RangingResult>? _streamRanging;


  BeaconScanner() {
    //
  }

  //Called by other classes to perform scan
  Future<Map<String, int>> scan() async {
    print("SCAN STARTED");
    Map<String, int> scanResults = {};
    await flutterBeacon.initializeScanning;
    if (!controller.authorizationStatusOk ||
        !controller.locationServiceEnabled ||
        !controller.bluetoothEnabled) {
      print(
          'RETURNED, authorizationStatusOk=${controller.authorizationStatusOk}, '
              'locationServiceEnabled=${controller.locationServiceEnabled}, '
              'bluetoothEnabled=${controller.bluetoothEnabled}');
      return scanResults;
    }
    final regions = <Region>[
      Region(
        identifier: 'healthy',
        proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AEC',
      ),
      Region(
        identifier: 'virus',
        proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AED',
      ),
    ];

    if (_streamRanging != null) {
      if (_streamRanging!.isPaused) {
        _streamRanging?.resume();
      }
    } else {
      _streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) {
        print("RESULT " + result.toString());
        _regionBeacons[result.region] = result.beacons;
        _beacons.clear();
        _regionBeacons.values.forEach((list) {
          _beacons.addAll(list);
        });
        for (Beacon foundBeacon in _beacons) {
          print(foundBeacon.toString());
          int inf = 0;
          if (foundBeacon.proximityUUID ==
              'CB10023F-A318-3394-4199-A8730C7C1AED') {
            inf = 1;
          }
          scanResults[foundBeacon.minor.toString() +
              foundBeacon.major.toString()] = inf;
        }
      });
    }

    await Future.delayed(const Duration(seconds: 10), () => _streamRanging?.pause());
   // await flutterBeacon.
    print("SCAN STOPPED");


    return scanResults;

  }


}