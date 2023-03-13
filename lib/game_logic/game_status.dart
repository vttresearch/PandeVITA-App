import 'dart:convert';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import '../mixpanel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/http_communication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

late Mixpanel mixpanel;
Future<void> initMixpanel() async {
  mixpanel = await Mixpanel.init(token,trackAutomaticEvents: true );
}

/// Singleton class that contains the game data of the user
class GameStatus {
  static final GameStatus _gameStatus = GameStatus._privateConstructor();
  final controller = Get.find<RequirementStateController>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  bool pointsChanged = false;
  final storage = const FlutterSecureStorage();
  var lastUpdatedServer = 0;

  factory GameStatus() {
    initMixpanel();
    return _gameStatus;
  }

  GameStatus._privateConstructor() {
    //Used for testing purposes
     removeLastQuiz();
  }

  //Add or remove points
  void modifyPoints(int amount) async {
    String currentPlayerPoints = await storage.read(key: 'playerPoints') ?? "0";
    int newPlayerPoints = int.parse(currentPlayerPoints) + amount;
    await storage.write(key: "playerPoints", value: newPlayerPoints.toString());
    debugPrint("New Player Points: $newPlayerPoints");
    controller.eventPlayerPointsChanged();
    updatePlayerStatus();
  }

  //Get points for display
  Future<String> getPoints() async {
    String playerPoints = await storage.read(key: 'playerPoints') ?? "0";
    debugPrint("Saved Player Points: $playerPoints");
    return playerPoints;
  }

  ///Infect the player
  void infectPlayer() async {
    mixpanel.track('Player infected');
    await storage.write(key: 'playerInfected', value: 'true');
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    await storage.write(key: 'playerInfectedTimestamp', value: timestamp.toString());
    String score = await storage.read(key: 'playerPoints') ?? "0";
    int points = int.parse(score);
    client.updatePlayer(score: points, status: 1);
    controller.playerInfected();
  }

  Future<String> getProximityUUID() async {
    String infectionStatus = await storage.read(key: 'playerInfected') ?? "false";
    String proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AEC';
    if (infectionStatus == "true") {
      proximityUUID = 'CB10023F-A318-3394-4199-A8730C7C1AED';
    }
    return proximityUUID;
  }

  ///Clear infection
  void cureInfectPlayer() async {
    await storage.write(key: 'playerInfected', value: 'false');
    await storage.write(key: 'playerInfectedTimestamp', value: '0');
    String score = await storage.read(key: "playerPoints") ?? "0";
    int points = int.parse(score);
    client.updatePlayer(score: points, status: 0);
    controller.playerCured();
  }

  Future<int> getPlayerInfectedTimestamp() async {
    String timestamp = await storage.read(key: 'playerInfectedTimestamp') ?? '0';
    return int.parse(timestamp);
  }

  //Check whether player gets infected or not
  void checkInfection(int damage) async {
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
    String immunity = (await storage.read(key: 'playerImmunity') ?? '0');
    return immunity;
  }

  Future<bool> isGameActive() async {
    Map gameActiveStatus = await client.getGameStatus();
    if (gameActiveStatus.isEmpty) {
      return false;
    }
    try {
      //int level = gameActiveStatus["level"];
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
    String contactTimestamp = await storage.read(key: 'contactTimestamp') ?? '0';
    return int.parse(contactTimestamp);
  }

  void saveContactTimestamp(int timestamp) async {
    debugPrint("ContactTimestamp saved $timestamp");
    await storage.write(key: 'contactTimestamp', value: timestamp.toString());
  }

  void updatePlayerStatus({int? contacts}) async {
    String points = await storage.read(key: 'playerPoints') ?? '0';
    int score = int.parse(points);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    if (contacts == null) {
      //At least 1 minute between updates
      if (timestamp - lastUpdatedServer > 60000) {
        await client.updatePlayer(score: score);
        await client.updateScoreboardPlayer(score);
        lastUpdatedServer = timestamp;
      }
    } else {
      await client.updatePlayer(score: score, recentContacts: contacts);
      await client.updateScoreboardPlayer(score);
      lastUpdatedServer = timestamp;
    }
  }

  /// Save the ID of the answered quiz to the list of answered quizzes
  /// and save the score of the last answered quiz
  void  saveQuizScore(String quizId, int score) async {
    String answeredQuizzesList = await storage.read(key: 'quizzes') ?? "[]";
    List answeredQuizzes = jsonDecode(answeredQuizzesList);
    answeredQuizzes.add(quizId);
    await storage.write(key: 'quizzes', value: jsonEncode(answeredQuizzes));
    await storage.write(key:'lastQuizScore', value: score.toString());
  }

  /// Check if the quiz is already answered. Returns true, if quiz is already
  /// answered, false, if not.
  Future<bool> isQuizAnswered(String quizId) async {
    String answeredQuizzesList = await storage.read(key: 'quizzes') ?? "[]";
    List answeredQuizzes = jsonDecode(answeredQuizzesList);
    if (answeredQuizzes.contains(quizId)) {
      return true;
    }
    return false;
  }

  /// Get the score of the last quiz answered.
  Future<int> getLastQuizScore() async {
    String lastScore = await storage.read(key: 'lastQuizScore') ?? '0';
    return int.parse(lastScore);
  }

  /// For testing purposes
  void removeLastQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('lastQuizScore');
    prefs.remove('quizzes');
    prefs.remove('answered_questions');
    //prefs.remove('collectedVaccines');
    //prefs.remove('collectedMasks');
  }

  void answeredQuizQuestion(String quizId) async {
    String answeredQuestionsList = (await storage.read(key: 'answered_questions') ?? "[]");
    List answeredQuestions = jsonDecode(answeredQuestionsList);
    answeredQuestions.add(quizId);
    await storage.write(key: 'answered_questions', value: jsonEncode(answeredQuestions));
  }

  Future<bool> isQuizQuestionAnswered(String questionId) async {
    String answeredQuestionsList = (await storage.read(key: 'answered_questions') ?? "[]");
    List answeredQuestions = jsonDecode(answeredQuestionsList);
    if (answeredQuestions.contains(questionId)) {
      return true;
    }
    return false;
  }

  Future<void> deleteAllData() async {
    await storage.deleteAll();
  }

  //not used currently
  Future<bool> checkVaccination(String vaccinationId) async {
    String collectedVaccinesList = await storage.read(key: 'collectedVaccines') ?? "[]";
    List collectedVaccines = jsonDecode(collectedVaccinesList);
    if (collectedVaccines.contains(vaccinationId)) {
      return false;
    }
    collectedVaccines.add(vaccinationId);
    await storage.write(key: 'collectedVaccines', value: jsonEncode(collectedVaccines));
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
    client.updatePlayer(score: points, collectedVaccineId: vaccinationId);
    //update vaccinations
    client.vaccinationTaken(vaccinationId);
    return true;
  }

  //not used currently
  Future<bool> checkMask(String maskId) async {
    String collectedMasksString = await storage.read(key: 'collectedMasks') ?? '[]';
    List collectedMasks = jsonDecode(collectedMasksString);
    if (collectedMasks.contains(maskId)) {
      return false;
    }
    collectedMasks.add(maskId);
    await storage.write(key: 'collectedMasks', value: jsonEncode(collectedMasks));
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
    client.updatePlayer(score: points, collectedMaskId: maskId);
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
    client.updatePlayer(score: points, collectedMask: true);
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
    client.updatePlayer(score: points, collectedVaccination: true);
    //update vaccinations
    return true;
  }

  Future<List> getCollectedMasks() async {
    String collectedMasks = await storage.read(key: 'collectedMasks') ?? '[]';
    return jsonDecode(collectedMasks);
  }

  Future<List> getMaskTimestamps() async {
    String maskTimestamps = await storage.read(key: 'maskTimestamps') ?? '[]';
    return jsonDecode(maskTimestamps);
  }

  Future<void> maskExpired(String timestamp) async {
    String maskTimestampsList = await storage.read(key: 'maskTimestamps') ?? '[]';
    List maskTimestamps = jsonDecode(maskTimestampsList);
    maskTimestamps.remove(timestamp);
    await storage.write(key: 'maskTimestamps', value: jsonEncode(maskTimestamps));
  }

  Future<List> getCollectedVaccinations() async {
    String collectedVaccines = await storage.read(key: 'collectedVaccines') ?? '[]';
    return jsonDecode(collectedVaccines);
  }

  Future<List> getVaccineTimestamps() async {
    String vaccineTimestamps = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    return jsonDecode(vaccineTimestamps);
  }

  Future<void> vaccineExpired(String timestamp) async {
    String vaccineTimestampsList = await storage.read(key: 'vaccineTimestamps') ?? '[]';
    List vaccineTimestamps = jsonDecode(vaccineTimestampsList);
    vaccineTimestamps.remove(timestamp);
    await storage.write(key: 'vaccineTimestamps',value: jsonEncode(vaccineTimestamps));
    controller.eventVaccinationAmountChanged();
  }
}