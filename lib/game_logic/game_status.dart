import 'package:latlong2/latlong.dart';
import 'package:pandevita_game/communication/beacon_broadcast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/http_communication.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
/* Singleton class that contains the game data of the user*/

class GameStatus {
  static final GameStatus _gameStatus = GameStatus._privateConstructor();
  final controller = Get.find<RequirementStateController>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  bool pointsChanged = false;

  var lastUpdatedServer = 0;


  factory GameStatus() {
    return _gameStatus;
  }

  GameStatus._privateConstructor() {
    //Used for testing purposes
  //  removeLastQuiz();
  }


  //Add or remove points
  void modifyPoints(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int newPlayerPoints = (prefs.getInt('playerPoints') ?? 0) + amount;
    debugPrint("New Player Points: $newPlayerPoints");
    await prefs.setInt('playerPoints', newPlayerPoints);
    controller.eventPlayerPointsChanged();
    updatePlayerStatus();
  }

  //Get points for display
  Future<String> getPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int playerPoints = prefs.getInt('playerPoints') ?? 0;
    debugPrint("Saved Player Points: $playerPoints");
    return playerPoints.toString();
  }


  ///Infect the player
  void infectPlayer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', true);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString('playerInfectedTimestamp', timestamp.toString());
    controller.playerInfected();
  }

  Future<String> getProximityUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool infectionStatus = (prefs.getBool('playerInfected') ?? false);
    String proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AEC';
    if (infectionStatus) {
      proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AED';
    }
    return proximityUUID;
  }

  ///Clear infection
  void cureInfectPlayer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', false);
    await prefs.setString('playerInfectedTimestamp', '0');
    controller.playerCured();
  }

  Future<int> getPlayerInfectedTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint("getplayerinfectedtimestamp got here");
    var timestamp = (prefs.getString('playerInfectedTimestamp') ?? '0');
    debugPrint("getplayerinfectedtimestamp @timestamp");
    return int.parse(timestamp);
  }

  //Check whether player gets infected or not
  void checkInfection(int damage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0);
    bool infectedStatus = (prefs.getBool('playerInfected') ?? false);
    if (!infectedStatus) {
      if (immunity < damage) {
        infectPlayer();
      }
      modifyImmunity(0 - damage);
      modifyPoints(-12);
    }

  }

  //Modify player's immunity level (0-100)
  void modifyImmunity(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0) + amount;
    if (immunity > 100) {
      immunity = 100;
    } else if (immunity < 0) {
      immunity = 0;
    }
    await prefs.setInt('playerImmunity', immunity);
    controller.eventImmunityLevelChanged();
  }

  Future<String> getImmunity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0);
    return immunity.toString();
  }

  Future<bool> isGameActive() async {
    Map gameActiveStatus = await client.getGameStatus();
    if (gameActiveStatus.isEmpty) {
      return false;
    }
    int level = gameActiveStatus["level"];
    String status = gameActiveStatus["status"];
    if (status == "active") {
      return true;
    } else {
      return false;
    }
  }

  Future<int> getContactTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactTimestamp = (prefs.getString('contactTimestamp') ?? "0");
    return int.parse(contactTimestamp);
  }

  void saveContactTimestamp(int timestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint("ContactTimestamp saved $timestamp");
    await prefs.setString('contactTimestamp', timestamp.toString());
  }

  void updatePlayerStatus({int? contacts}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int score = (prefs.getInt('playerPoints') ?? 0);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    if (contacts == null) {
      //At least 1 minute between updates
      if (timestamp - lastUpdatedServer > 60000) {
        await client.updatePlayer(score);
        await client.updateScoreboardPlayer(score);
        lastUpdatedServer = timestamp;
      }
    } else {
      await client.updatePlayer(score, recentContacts: contacts);
      await client.updateScoreboardPlayer(score);
      lastUpdatedServer = timestamp;
    }
  }

  /**
   * Save the ID of the answered quiz to the list of answered quizzes
   * and save the score of the last answered quiz
   */
  void  saveQuizScore(String quizId, int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> answeredQuizzes = (prefs.getStringList('quizzes') ?? []);
    answeredQuizzes.add(quizId);
    await prefs.setStringList('quizzes', answeredQuizzes);
    await prefs.setInt('lastQuizScore', score);
  }

/**
 * Check if the quiz is already answered. Returns true, if quiz is already
 * answered, false, if not.
 */
  Future<bool> isQuizAnswered(String quizId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> answeredQuizzes = (prefs.getStringList('quizzes') ?? []);
    if (answeredQuizzes.contains(quizId)) {
      return true;
    }
    return false;
  }

  /**
   * Get the score of the last quiz answered.
   */
  Future<int> getLastQuizScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastScore = (prefs.getInt('lastQuizScore') ?? 0);
    return lastScore;
  }

  /**For testing purposes*/
  void removeLastQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('lastQuizScore');
    prefs.remove('quizzes');
  }

  Future<void> deleteAllData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> checkVaccination(String coordinate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> collectedVaccines = (prefs.getStringList('collectedVaccines') ?? []);
    if (collectedVaccines.contains(coordinate)) {
      return false;
    }
    collectedVaccines.add(coordinate);
    await prefs.setStringList('collectedVaccines', collectedVaccines);
    modifyImmunity(50);
    //Set timestamp
    List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    vaccineTimestamps.add(timestamp.toString());
    await prefs.setStringList('vaccineTimestamps', vaccineTimestamps);
    controller.eventVaccinationAmountChanged();
    return true;
  }

  Future<bool> checkMask(String coordinate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> collectedMasks = (prefs.getStringList('collectedMasks') ?? []);
    if (collectedMasks.contains(coordinate)) {
      return false;
    }
    collectedMasks.add(coordinate);
    await prefs.setStringList('collectedMasks', collectedMasks);
    modifyImmunity(20);
    //Set timestamp
    List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    maskTimestamps.add(timestamp.toString());
    await prefs.setStringList('maskTimestamps', maskTimestamps);
    return true;
  }

  Future<List<String>> getCollectedMasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> collectedMasks = (prefs.getStringList('collectedMasks') ?? []);
    return collectedMasks;
  }

  Future<List<String>> getMaskTimestamps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    return maskTimestamps;
  }

  Future<void> maskExpired(String timestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    maskTimestamps.remove(timestamp);
    await prefs.setStringList('maskTimestamps', maskTimestamps);
  }

  Future<List<String>> getVaccineTimestamps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    return vaccineTimestamps;
  }

  Future<void> vaccineExpired(String timestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    vaccineTimestamps.remove(timestamp);
    await prefs.setStringList('vaccineTimestamps', vaccineTimestamps);
    controller.eventVaccinationAmountChanged();
  }

}