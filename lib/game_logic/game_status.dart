import 'dart:convert';
import 'dart:ffi';

import 'package:latlong2/latlong.dart';
import 'package:pandevita_game/communication/beacon_broadcast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/http_communication.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
/* Singleton class that contains the game data of the user*/

class GameStatus {
  static final GameStatus _gameStatus = GameStatus._privateConstructor();
  final controller = Get.find<RequirementStateController>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  bool pointsChanged = false;
  final storage = const FlutterSecureStorage();

  var lastUpdatedServer = 0;


  factory GameStatus() {
    return _gameStatus;
  }

  GameStatus._privateConstructor() {
    //Used for testing purposes
     removeLastQuiz();
  }


  //Add or remove points
  void modifyPoints(int amount) async {
  /*  SharedPreferences prefs = await SharedPreferences.getInstance();
    int newPlayerPoints = (prefs.getInt('playerPoints') ?? 0) + amount;
    debugPrint("New Player Points: $newPlayerPoints");
    await prefs.setInt('playerPoints', newPlayerPoints);
    controller.eventPlayerPointsChanged();
    updatePlayerStatus();*/
    String currentPlayerPoints = await storage.read(key: 'playerPoints') ?? "0";
    int newPlayerPoints = int.parse(currentPlayerPoints) + amount;
    await storage.write(key: "playerPoints", value: newPlayerPoints.toString());
    debugPrint("New Player Points: $newPlayerPoints");
    controller.eventPlayerPointsChanged();
    updatePlayerStatus();
  }

  //Get points for display
  Future<String> getPoints() async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    int playerPoints = prefs.getInt('playerPoints') ?? 0;
    debugPrint("Saved Player Points: $playerPoints");
    return playerPoints.toString();*/
    String playerPoints = await storage.read(key: 'playerPoints') ?? "0";
    debugPrint("Saved Player Points: $playerPoints");
    return playerPoints;
  }


  ///Infect the player
  void infectPlayer() async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', true);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString('playerInfectedTimestamp', timestamp.toString());
    int score = prefs.getInt('playerPoints') ?? 0;
    client.updatePlayer(score, status: 1);
    controller.playerInfected();*/
    await storage.write(key: 'playerInfected', value: 'true');
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    await storage.write(key: 'playerInfectedTimestamp', value: timestamp.toString());
    String score = await storage.read(key: 'playerPoints') ?? "0";
    int points = int.parse(score);
    client.updatePlayer(points, status: 1);
    controller.playerInfected();
  }

  Future<String> getProximityUUID() async {
  /*  SharedPreferences prefs = await SharedPreferences.getInstance();
    bool infectionStatus = (prefs.getBool('playerInfected') ?? false);
    String proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AEC';
    if (infectionStatus) {
      proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AED';
    }
    return proximityUUID;*/
    String infectionStatus = await storage.read(key: 'playerInfected') ?? "false";
    String proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AEC';
    if (infectionStatus == "true") {
      proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AED';
    }
    return proximityUUID;
  }

  ///Clear infection
  void cureInfectPlayer() async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', false);
    await prefs.setString('playerInfectedTimestamp', '0');
    int score = prefs.getInt("playerPoints") ?? 0;
    client.updatePlayer(score, status: 0);
    controller.playerCured();*/
    await storage.write(key: 'playerInfected', value: 'false');
    await storage.write(key: 'playerInfectedTimestamp', value: '0');
    String score = await storage.read(key: "playerPoints") ?? "0";
    int points = int.parse(score);
    client.updatePlayer(points, status: 0);
    controller.playerCured();
  }

  Future<int> getPlayerInfectedTimestamp() async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint("getplayerinfectedtimestamp got here");
    var timestamp = (prefs.getString('playerInfectedTimestamp') ?? '0');
    debugPrint("getplayerinfectedtimestamp @timestamp");
    return int.parse(timestamp);*/
    String timestamp = await storage.read(key: 'playerInfectedTimestamp') ?? '0';
    return int.parse(timestamp);
  }

  //Check whether player gets infected or not
  void checkInfection(int damage) async {
 /*   SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0);
    bool infectedStatus = (prefs.getBool('playerInfected') ?? false);
    if (!infectedStatus) {
      if (immunity < damage) {
        infectPlayer();
      }
      modifyImmunity(0 - damage);
      modifyPoints(-12);
    }*/
    String immunityString = (await storage.read(key: 'playerImmunity') ?? '0');
    int immunity = int.parse(immunityString);
    String infectedStatus = (await storage.read(key: 'playerInfected') ?? 'false');
    if (infectedStatus == "false") {
      if (immunity < damage) {
        infectPlayer();
      }
      modifyImmunity(0 - damage);
      modifyPoints(-12);
    }
  }

  //Modify player's immunity level (0-100)
  void modifyImmunity(int amount) async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0) + amount;
    if (immunity > 100) {
      immunity = 100;
    } else if (immunity < 0) {
      immunity = 0;
    }
    await prefs.setInt('playerImmunity', immunity);
    controller.eventImmunityLevelChanged();*/
    String immunityString = (await storage.read(key: 'playerImmunity') ?? '0');
    int immunity = int.parse(immunityString) + amount;
    if (immunity > 100) {
      immunity = 100;
    } else if (immunity < 0) {
      immunity = 0;
    }
    await storage.write(key: 'playerImmunity', value: immunity.toString());
    controller.eventImmunityLevelChanged();
  }

  Future<String> getImmunity() async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    int immunity = (prefs.getInt('playerImmunity') ?? 0);*/
    String immunity = (await storage.read(key: 'playerImmunity') ?? '0');
    return immunity;
  }

  Future<bool> isGameActive() async {
    Map gameActiveStatus = await client.getGameStatus();
    if (gameActiveStatus.isEmpty) {
      return false;
    }
    try {
      int level = gameActiveStatus["level"];
      String status = gameActiveStatus["status"];
      if (status == "active") {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      debugPrint("Error in isGameActive() in GameStatus: $error");
      return false;
    }

  }

  Future<int> getContactTimestamp() async {
  /*  SharedPreferences prefs = await SharedPreferences.getInstance();
    String contactTimestamp = (prefs.getString('contactTimestamp') ?? "0");*/
    String contactTimestamp = await storage.read(key: 'contactTimestamp') ?? '0';
    return int.parse(contactTimestamp);
  }

  void saveContactTimestamp(int timestamp) async {
  //  SharedPreferences prefs = await SharedPreferences.getInstance();
    debugPrint("ContactTimestamp saved $timestamp");
   // await prefs.setString('contactTimestamp', timestamp.toString());
    await storage.write(key: 'contactTimestamp', value: timestamp.toString());
  }

  void updatePlayerStatus({int? contacts}) async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //  int score = (prefs.getInt('playerPoints') ?? 0);
    String points = await storage.read(key: 'playerPoints') ?? '0';
    int score = int.parse(points);
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
   // SharedPreferences prefs = await SharedPreferences.getInstance();
    String answeredQuizzesList = await storage.read(key: 'quizzes') ?? "[]";
    List answeredQuizzes = jsonDecode(answeredQuizzesList);
   // List<String> answeredQuizzes = (prefs.getStringList('quizzes') ?? []);
    answeredQuizzes.add(quizId);
   // await prefs.setStringList('quizzes', answeredQuizzes);
   // await prefs.setInt('lastQuizScore', score);
    await storage.write(key: 'quizzes', value: jsonEncode(answeredQuizzes));
    await storage.write(key:'lastQuizScore', value: score.toString());
  }

/**
 * Check if the quiz is already answered. Returns true, if quiz is already
 * answered, false, if not.
 */
  Future<bool> isQuizAnswered(String quizId) async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //  List<String> answeredQuizzes = (prefs.getStringList('quizzes') ?? []);
    String answeredQuizzesList = await storage.read(key: 'quizzes') ?? "[]";
    List answeredQuizzes = jsonDecode(answeredQuizzesList);
    if (answeredQuizzes.contains(quizId)) {
      return true;
    }
    return false;
  }

  /**
   * Get the score of the last quiz answered.
   */
  Future<int> getLastQuizScore() async {
  //  SharedPreferences prefs = await SharedPreferences.getInstance();
   // int lastScore = (prefs.getInt('lastQuizScore') ?? 0);
    String lastScore = await storage.read(key: 'lastQuizScore') ?? '0';
    return int.parse(lastScore);
  }

  /**For testing purposes*/
  void removeLastQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('lastQuizScore');
    prefs.remove('quizzes');
    prefs.remove('answered_questions');
   // prefs.remove('collectedVaccines');
    //prefs.remove('collectedMasks');
  }

  void answeredQuizQuestion(String quizId) async {
   /* SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> answeredQuestions = (prefs.getStringList('answered_questions') ?? []);
    answeredQuestions.add(quizId);
    await prefs.setStringList('answered_questions', answeredQuestions);
    int score = int.parse(await getPoints());*/
    String answeredQuestionsList = (await storage.read(key: 'answered_questions') ?? "[]");
    List answeredQuestions = jsonDecode(answeredQuestionsList);
    answeredQuestions.add(quizId);
    await storage.write(key: 'answered_questions', value: jsonEncode(answeredQuestions));
  }

  Future<bool> isQuizQuestionAnswered(String questionId) async {
 /*   SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> answeredQuestions = (prefs.getStringList('answered_questions') ?? []);*/
    String answeredQuestionsList = (await storage.read(key: 'answered_questions') ?? "[]");
    List answeredQuestions = jsonDecode(answeredQuestionsList);
    if (answeredQuestions.contains(questionId)) {
      return true;
    }
    return false;
  }


  Future<void> deleteAllData() async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
   // await prefs.clear();
    await storage.deleteAll();
  }

  //not used currently
  Future<bool> checkVaccination(String vaccinationId) async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //  List<String> collectedVaccines = (prefs.getStringList('collectedVaccines') ?? []);
    String collectedVaccinesList = await storage.read(key: 'collectedVaccines') ?? "[]";
    List collectedVaccines = jsonDecode(collectedVaccinesList);
    if (collectedVaccines.contains(vaccinationId)) {
      return false;
    }
    collectedVaccines.add(vaccinationId);
  //  await prefs.setStringList('collectedVaccines', collectedVaccines);
    await storage.write(key: 'collectedVaccines', value: jsonEncode(collectedVaccines));
    modifyImmunity(50);
    //Set timestamp
  //  List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    String vaccineTimestampsList = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    List vaccineTimestamps = jsonDecode(vaccineTimestampsList);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    vaccineTimestamps.add(timestamp.toString());
  //  await prefs.setStringList('vaccineTimestamps', vaccineTimestamps);
    await storage.write(key: 'vaccineTimestamps', value: jsonEncode(vaccineTimestamps));
    controller.eventVaccinationAmountChanged();
    //Update backend
    String score = await getPoints();
    int points = int.parse(score);
    client.updatePlayer(points, collectedVaccineId: vaccinationId);
    //update vaccinations
    client.vaccinationTaken(vaccinationId);
    return true;
  }

  //not used currently
  Future<bool> checkMask(String maskId) async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
   // List<String> collectedMasks = (prefs.getStringList('collectedMasks') ?? []);
    String collectedMasksString = await storage.read(key: 'collectedMasks') ?? '[]';
    List collectedMasks = jsonDecode(collectedMasksString);
    if (collectedMasks.contains(maskId)) {
      return false;
    }
    collectedMasks.add(maskId);
   // await prefs.setStringList('collectedMasks', collectedMasks);
    await storage.write(key: 'collectedMasks', value: jsonEncode(collectedMasks));
    modifyImmunity(20);
    //Set timestamp
   // List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    String maskTimestampsList = await storage.read(key: 'maskTimestamps') ?? '[]';
    List maskTimestamps = jsonDecode(maskTimestampsList);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    maskTimestamps.add(timestamp.toString());
   // await prefs.setStringList('maskTimestamps', maskTimestamps);
    await storage.write(key: 'maskTimestamps', value: jsonEncode(maskTimestamps));
    //Update backend
    String score = await getPoints();
    int points = int.parse(score);
    client.updatePlayer(points, collectedMaskId: maskId);
    //update masks
    client.maskTaken(maskId);
    return true;
  }

  //New function for handling randomly generated masks
  Future<bool> collectMask() async {
    modifyImmunity(20);
    //Set timestamp
    String maskTimestampsList = await storage.read(key: 'maskTimestamps') ?? '[]';
    List maskTimestamps = jsonDecode(maskTimestampsList);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    maskTimestamps.add(timestamp.toString());
    await storage.write(key: 'maskTimestamps', value: jsonEncode(maskTimestamps));
    //Update backend
    String score = await getPoints();
    int points = int.parse(score);
    client.updatePlayer(points, collectedMask: true);
    return true;
  }

  //New function for handling randomly generated vaccines
  Future<bool> collectVaccination() async {
    modifyImmunity(50);
    //Set timestamp
    String vaccineTimestampsList = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    List vaccineTimestamps = jsonDecode(vaccineTimestampsList);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    vaccineTimestamps.add(timestamp.toString());
    await storage.write(key: 'vaccineTimestamps', value: jsonEncode(vaccineTimestamps));
    controller.eventVaccinationAmountChanged();
    //Update backend
    String score = await getPoints();
    int points = int.parse(score);
    client.updatePlayer(points, collectedVaccination: true);
    //update vaccinations
    return true;
  }

  Future<List> getCollectedMasks() async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //  List<String> collectedMasks = (prefs.getStringList('collectedMasks') ?? []);
    String collectedMasks = await storage.read(key: 'collectedMasks') ?? '[]';
    return jsonDecode(collectedMasks);
  }

  Future<List> getMaskTimestamps() async {
//    SharedPreferences prefs = await SharedPreferences.getInstance();
  //  List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    String maskTimestamps = await storage.read(key: 'maskTimestamps') ?? '[]';
    return jsonDecode(maskTimestamps);
  }

  Future<void> maskExpired(String timestamp) async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
    //List<String> maskTimestamps = (prefs.getStringList('maskTimestamps') ?? []);
    String maskTimestampsList = await storage.read(key: 'maskTimestamps') ?? '[]';
    List maskTimestamps = jsonDecode(maskTimestampsList);
    maskTimestamps.remove(timestamp);
   // await prefs.setStringList('maskTimestamps', maskTimestamps);
    await storage.write(key: 'maskTimestamps', value: jsonEncode(maskTimestamps));
  }

  Future<List> getCollectedVaccinations() async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
   // List<String> collectedVaccines = (prefs.getStringList('collectedVaccines') ?? []);
    String collectedVaccines = await storage.read(key: 'collectedVaccines') ?? '[]';
    return jsonDecode(collectedVaccines);
  }

  Future<List> getVaccineTimestamps() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    //List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    String vaccineTimestamps = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    return jsonDecode(vaccineTimestamps);
  }

  Future<void> vaccineExpired(String timestamp) async {
   // SharedPreferences prefs = await SharedPreferences.getInstance();
   // List<String> vaccineTimestamps = (prefs.getStringList('vaccineTimestamps') ?? []);
    String vaccineTimestampsList = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    List vaccineTimestamps = jsonDecode(vaccineTimestampsList);
    vaccineTimestamps.remove(timestamp);
   // await prefs.setStringList('vaccineTimestamps', vaccineTimestamps);
    await storage.write(key: 'vaccineTimestamps',value: jsonEncode(vaccineTimestamps));
    controller.eventVaccinationAmountChanged();
  }

}