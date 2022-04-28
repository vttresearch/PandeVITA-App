/** This file contains the game logic of the PandeVITA app. **/
import 'dart:async';

import 'game_status.dart';
import 'package:flutter/material.dart';
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

  bool isGameInitiated = false;

  var contactsSinceStarted = Set();

  var staticVirusNearby = false;
  var staticExposureTime = 0;

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
    controller.staticVirusNearbyStream.listen((flag) {
      if (flag == true) {
        staticVirusNearby = true;
      } else if (flag == false) {
        staticVirusNearby = false;
      }
    });
  }

  void initGame() async {
    debugPrint("initGame call");
    if (isGameInitiated) {
      debugPrint("isgameinitiated true");
      return;
    }
    isGameInitiated = true;
    gameStatus = GameStatus();
    beaconScanner = BeaconScanner();
    timer = Timer.periodic(const Duration(seconds: 60), (Timer t) => gameLogicTick());
    debugPrint("hello1");
    _isGameActive = await gameStatus!.isGameActive();
    debugPrint("hello2");

    contactsStartedTimestamp = await gameStatus!.getContactTimestamp();
    if (contactsStartedTimestamp == 0) {
      contactsStartedTimestamp = DateTime.now().millisecondsSinceEpoch;
      gameStatus!.saveContactTimestamp(contactsStartedTimestamp);
    }
    var playerInfectedTimestamp = await gameStatus!.getPlayerInfectedTimestamp();
    debugPrint("playerInfectedTimestamp $playerInfectedTimestamp");
    if (playerInfectedTimestamp != 0) {
      debugPrint("playerinfectedtimestamp is not 0");
      var currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      //If over 3 days since infection
      if (currentTimestamp - infectedTimestamp >= 259200000) {
        gameStatus!.cureInfectPlayer();
      } else {
        infectedTimestamp = playerInfectedTimestamp;
        controller.playerInfected();
      }
    }
  }

  void stopGame() {
    timer?.cancel();
  }

  //One tick of the game logic. Runs every 60 seconds
  void gameLogicTick() async {
    debugPrint("infected $infected");
    if (!_isGameActive) {
      return;
    }
    var timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    bool infNearby = false;
    //Check surrounding devices

    var contacts = [];
    scanResults = await beaconScanner!.scan();

    debugPrint(scanResults.toString());

    if (!infected) {
      //Iterate the map
      for (MapEntry<String, int> me in scanResults.entries) {
        //Infected player nearby
        contacts.add(me.key);
        if (me.value == 1) {
          exposureTime += 1;
          debugPrint("INF PLAYER");
          safeTime = 0;
          infNearby = true;
          continue;
        }
      }
      if (!infNearby) {
        exposureTime = 0;
        debugPrint("SAFE");
        safeTime += 1;
      }
      //Point logic
      //If exposure to infected player has been longer than 10 minutes
      if (exposureTime >= 10) {
        gameStatus!.checkInfection(100);
        exposureTime = 0;
      }
      //If the player is near a static virus
      if (staticVirusNearby) {
        staticExposureTime += 1;
        safeTime = 0;
        if (staticExposureTime >= 5) {
          gameStatus!.checkInfection(100);
          staticExposureTime = 0;
          controller.staticVirusNearbyCleared();
        }
      } else {
        staticExposureTime = 0;
      }

      //If no exposure for 5 minutes
      //If player is healthy
      if (safeTime >= 5) {
        gameStatus!.modifyPoints(1);
        safeTime = 0;
        debugPrint("POINTS GAINED");
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
        aloneTime = 0;
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
      gameStatus!.updatePlayerStatus(contacts: contactsSinceStarted.length);
      contactsStartedTimestamp = timestamp;
      gameStatus!.saveContactTimestamp(contactsStartedTimestamp);
      contactsSinceStarted.clear();
    }
  }
}