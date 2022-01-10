/**This class handles the continuous beacon broadcasting needed by the
    application. It is based on the example implementation of flutter_beacon*/
import 'package:flutter/services.dart';
import '../game_logic/game_status.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'dart:math';

class BeaconBroadcastClass {
  final controller = Get.find<RequirementStateController>();
  bool broadcasting = false;
  int? major;
  int? minor;
  bool get broadcastReady =>
      controller.authorizationStatusOk == true &&
          controller.locationServiceEnabled == true &&
          controller.bluetoothEnabled == true;

  GameStatus gameStatus = GameStatus();

  BeaconBroadcastClass() {
    controller.startBroadcastStream.listen((flag) {
      if (flag == true) {
        startBroadcastBeacon();
      } else if (flag == false) {
        if (broadcasting) {
          stopBroadcastBeacon();
        }

      }
    });

    var rng = Random();
    minor = rng.nextInt(65535);
    major = rng.nextInt(65535);

  }

  startBroadcastBeacon() async {
    await flutterBeacon.initializeScanning;
    print("STARTING BROADCAST");
    String proximityUUID = await getProximityUUID();
    print(proximityUUID);
    print(major.toString());
    print(minor.toString());
    await flutterBeacon.startBroadcast(BeaconBroadcast(
      proximityUUID: proximityUUID,
      major: major!,
      minor: minor!,
    ));
    final isBroadcasting = await flutterBeacon.isBroadcasting();
    broadcasting = isBroadcasting;
    print("ISBROADCASTING " + isBroadcasting.toString());

  }

  stopBroadcastBeacon() async {
    await flutterBeacon.stopBroadcast();
  }

  Future<String> getProximityUUID() async {
    print("GOTHERE1");
    String proximityUUID = await gameStatus.getProximityUUID();
    print("GOTHERE");
    return proximityUUID;
}


}