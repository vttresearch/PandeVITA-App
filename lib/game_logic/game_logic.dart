/** This file contains the game logic of the PandeVITA app. **/
import 'dart:async';

import 'game_status.dart';
import 'package:flutter/material.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/beacon_scanner.dart';

class GameLogic {
  Timer? timer;
  Timer? timer2;
  GameStatus? gameStatus;
  BeaconScanner? beaconScanner;
  Map<String, int> scanResults = {};
  int exposureTime = 0;
  int safeTime = 0;
  int aloneTime = 0;
  bool infected = false;

  //Control variables for UI
  bool infected3days = false;
  bool infected2days = false;
  bool infected1day = false;

  var infectedTimestamp = 0;
  var contactsStartedTimestamp = 0;

  var lastGameLogicTimestamp = 0;

  bool _isGameActive = false;

  bool isGameInitiated = false;

  var contactsSinceStarted = Set();

  var staticVirusNearby = false;
  var staticExposureTime = 0;

  var gameActiveControl = 0;

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
        infected3days = true;
        //Bug fix: correct timestamps now not overridden
        if (infectedTimestamp == 0) {
          infectedTimestamp = DateTime
              .now()
              .millisecondsSinceEpoch;
        }
      } else if (flag == false) {
        infectedTimestamp = 0;
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
    timer = Timer.periodic(
        const Duration(seconds: 60), (Timer t) => gameLogicTick());
    DateTime now = DateTime.now();
    DateTime endOfDay = DateTime(now.year, now.month, now.day + 1);
    timer2 = Timer(endOfDay.difference(now), immunityReset);
    _isGameActive = await gameStatus!.isGameActive();


    contactsStartedTimestamp = await gameStatus!.getContactTimestamp();
    if (contactsStartedTimestamp == 0) {
      contactsStartedTimestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      gameStatus!.saveContactTimestamp(contactsStartedTimestamp);
    }
    var playerInfectedTimestamp = await gameStatus!
        .getPlayerInfectedTimestamp();
    debugPrint("playerInfectedTimestamp $playerInfectedTimestamp");
    if (playerInfectedTimestamp != 0) {
      debugPrint("playerinfectedtimestamp is not 0");
      var currentTimestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      //If over 3 days since infection
      if (currentTimestamp - infectedTimestamp >= 259200000) {
        gameStatus!.cureInfectPlayer();
      } else {
        infectedTimestamp = playerInfectedTimestamp;
        controller.playerInfected();
      }
    }
  }

  ///Stops the timers that keep the game logic running
  void stopGame() {
    timer?.cancel();
    timer2?.cancel();
  }

  ///One tick of the game logic. Runs every 60 seconds
  void gameLogicTick() async {
    debugPrint("infected $infected");
    gameActiveControl++;
    //Check whether the game is still active every 30 minutes
    debugPrint("gameActiveControl is $gameActiveControl");
    if (gameActiveControl > 30) {
      gameActiveControl = 0;
      _isGameActive = await gameStatus!.isGameActive();
    }
    if (!_isGameActive) {
      return;
    }
    var timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    var checking = timestamp - lastGameLogicTimestamp;
    debugPrint("time since last game logic tick $checking");
    lastGameLogicTimestamp = timestamp;
    bool infNearby = false;
    //Check surrounding devices

    var contacts = [];

    ///changed to use then instead of await for optimization
    beaconScanner!.scan().then((scanResults) {
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
          //edit this to edit time needed to infect from static virus
          if (staticExposureTime >= 1) {
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
        } //if over 2 days since infection
        else if (timestamp - infectedTimestamp >= 172800000 && infected1day == false) {
          controller.eventBackgroundChanged2days();
          infected1day = true;
          infected2days = false;
        } //if over 1 day since infection
        else if (timestamp - infectedTimestamp >= 86400000 && infected2days == false) {
          controller.eventBackgroundChanged1day();
          infected3days = false;
          infected2days = true;
        }


      }
    });
    //These are gone through regardless of whether player is infected or not
    contactsSinceStarted = contacts.toSet();
    //if over 1 day  since started tracking contacts
    /*  if (timestamp - contactsStartedTimestamp >= 86400000) {
      gameStatus!.updatePlayerStatus(contacts: contactsSinceStarted.length);
      contactsStartedTimestamp = timestamp;
      gameStatus!.saveContactTimestamp(contactsStartedTimestamp);
      contactsSinceStarted.clear();
    }*/
    //Vaccines
    debugPrint("Immunity logic: vaccines");
    List<String> vaccineTimestamps = await gameStatus!.getVaccineTimestamps();
    for (String vaccineTimestamp in vaccineTimestamps) {
      //Vaccine dose grants immunity for two days
      var vaccineTimestampInt = int.parse(vaccineTimestamp);
      if (timestamp - vaccineTimestampInt > 172800000) {
        gameStatus!.vaccineExpired(vaccineTimestamp);
      }
    }
    //Masks
    debugPrint("Immunity logic: masks");
    List<String> maskTimestamps = await gameStatus!.getMaskTimestamps();
    for (String maskTimestamp in maskTimestamps) {
      //A collected mask grants immunity for one day
      var maskTimestampInt = int.parse(maskTimestamp);
      if (timestamp - maskTimestampInt > 86400000) {
        gameStatus!.maskExpired(maskTimestamp);
      }
    }
  }

  ///Remove 40 immunity at the end of each day
  void immunityReset() {
    gameStatus!.modifyImmunity(-40);
    //New timer
    DateTime now = DateTime.now();
    DateTime endOfDay = DateTime(now.year, now.month, now.day + 1);
    timer2 = Timer(endOfDay.difference(now), immunityReset);

  }
}