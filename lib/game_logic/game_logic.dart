/** This file contains the game logic of the PandeVITA app. **/
import 'dart:async';
import 'game_status.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/beacon_scanner.dart';

class GameLogic {
  Timer? timer;
  GameStatus? gameStatus;
  BeaconScanner? beaconScanner;
  Map<String, int> scanResults = {};
  int exposureTime = 0;
  int safeTime = 0;
  int aloneTime = 0;
  bool infected = false;
  var infectedTimestamp = 0;
  var contactsStartedTimestamp = 0;

  bool _isGameActive = false;

  var contactsSinceStarted = Set();

  final controller = Get.find<RequirementStateController>();

  static final GameLogic _gameLogic = GameLogic._privateConstructor();

  factory GameLogic() {
    return _gameLogic;
  }

  GameLogic._privateConstructor() {
    //initGame();
    controller.playerInfectedStream.listen((flag) {
      if (flag == true) {
        infected = true;
        infectedTimestamp = DateTime
            .now()
            .millisecondsSinceEpoch;
      } else if (flag == false) {
        infected = false;
      }
    });
  }

  void initGame() async {
    gameStatus = GameStatus();
    beaconScanner = BeaconScanner();
    timer = Timer.periodic(Duration(seconds: 20), (Timer t) => gameLogicTick());
    _isGameActive = await gameStatus!.isGameActive();
  }

  void stopGame() {
    timer?.cancel();
  }

  //One tick of the game logic. Runs every 60 seconds
  void gameLogicTick() async {
    if (!_isGameActive) {
      return;
    }
    var timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    bool infNearby = false;
    //Check surrounding devices
    print("GAMELOGICTICK");
    var contacts = [];
    scanResults = await beaconScanner!.scan();
    print("GAMELOGICTICK 2");
    print(scanResults.toString());
    if (!infected) {
      //Iterate the map
      for (MapEntry<String, int> me in scanResults.entries) {
        //Infected player nearby
        contacts.add(me.key);
        if (me.value == 1) {
          exposureTime += 1;
          print("INF PLAYER");
          safeTime = 0;
          infNearby = true;
          continue;
        }
      }
      if (!infNearby) {
        exposureTime = 0;
        print("SAFE");
        safeTime += 1;
      }
      //Point logic
      //If exposure to infected player has been longer than 10 minutes
      if (exposureTime >= 10) {
        gameStatus!.checkInfection(100);
        exposureTime = 0;
      } //If no exposure for 5 minutes
      //If player is healthy

      if (safeTime >= 5) {
        gameStatus!.modifyPoints(1);
        safeTime = 0;
        print("POINTS GAINED");
      }
    }
    //If player is not healthy, they get points by not being near other
    // players
    if (infected) {
      if (scanResults.isEmpty) {
        aloneTime += 1;
      } else {
        for (MapEntry<String, int> me in scanResults.entries) {
          //Infected player nearby
          contacts.add(me.key);
        }
        aloneTime = 0;
      }
      if (aloneTime >= 10) {
        gameStatus!.modifyPoints(1);
      }

      //If over 3 days since infection
      if (timestamp - infectedTimestamp >= 259200000) {
        gameStatus!.cureInfectPlayer();
      }
    }
    //These are gone through regardless of whether player is infected or not
    contactsSinceStarted = contacts.toSet();
    //if over 1 day  since started tracking contacts
    if (timestamp - contactsStartedTimestamp >= 86400000) {
      //TODO: Send update message to server
      contactsStartedTimestamp = timestamp;
      contactsSinceStarted.clear();
    }
  }
}