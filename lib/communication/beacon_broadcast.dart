/**This class handles the continuous beacon broadcasting needed by the
    application. It is based on the example implementation of flutter_beacon.
 Changed to a singleton class.*/
import 'package:flutter/cupertino.dart';
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

  static final BeaconBroadcastClass _beaconBroadcastClass = BeaconBroadcastClass._privateConstructor();

  factory BeaconBroadcastClass() {
    return _beaconBroadcastClass;
  }

  BeaconBroadcastClass._privateConstructor() {
    controller.startBroadcastStream.listen((flag) {
      if (flag == true) {
        startBroadcastBeacon();
      } else if (flag == false) {
        if (broadcasting) {
          stopBroadcastBeacon();
        }

      }
    });
    //Change the broadcast UUID when infected/cured
    controller.playerInfectedStream.listen((flag) {
      resetBroadcastBeacon();
    });

    var rng = Random();
    minor = rng.nextInt(65535);
    major = rng.nextInt(65535);
  }






  startBroadcastBeacon() async {
    await flutterBeacon.initializeScanning;
    debugPrint("STARTING BROADCAST");
    String proximityUUID = await getProximityUUID();
    debugPrint(proximityUUID);
    debugPrint(major.toString());
    debugPrint(minor.toString());
    await flutterBeacon.startBroadcast(BeaconBroadcast(
      proximityUUID: proximityUUID,
      major: major!,
      minor: minor!,
    ));
    final isBroadcasting = await flutterBeacon.isBroadcasting();
    broadcasting = isBroadcasting;
    debugPrint("ISBROADCASTING " + isBroadcasting.toString());

  }

  stopBroadcastBeacon() async {
    debugPrint("stoppingBroadcastBeacon");
    await flutterBeacon.stopBroadcast();
    final isBroadcasting = await flutterBeacon.isBroadcasting();
    broadcasting = isBroadcasting;
    debugPrint("isBroadcasting $isBroadcasting");
  }

  ///For handling the change of infection status
  resetBroadcastBeacon() async {
    debugPrint("resettingBroadcastBeacon");
    await stopBroadcastBeacon();
    startBroadcastBeacon();
  }

  Future<String> getProximityUUID() async {
    debugPrint("GOTHERE1");
    String proximityUUID = await gameStatus.getProximityUUID();
    debugPrint("GOTHERE");
    return proximityUUID;
}


}