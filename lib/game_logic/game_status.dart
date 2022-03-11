import 'package:shared_preferences/shared_preferences.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../communication/http_communication.dart';
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

  GameStatus._privateConstructor();

  //Add or remove points
  void modifyPoints(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int newPlayerPoints = (prefs.getInt('playerPoints') ?? 0) + amount;
    print("New Player Points: $newPlayerPoints");
    await prefs.setInt('playerPoints', newPlayerPoints);
    controller.eventPlayerPointsChanged();
    updatePlayerStatus();
  }

  //Get points for display
  Future<String> getPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int playerPoints = prefs.getInt('playerPoints') ?? 0;
    print("Saved Player Points: $playerPoints");
    return playerPoints.toString();
  }


  //Infect the player
  void infectPlayer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', true);
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

  //Clear infection
  void cureInfectPlayer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playerInfected', false);
    controller.playerCured();
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
    print("ContactTimestamp saved $timestamp");
    await prefs.setString('contactTimestamp', timestamp.toString());
  }

  void updatePlayerStatus({int? contacts}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int score = (prefs.getInt('playerPoints') ?? 0);
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    if (contacts == null) {
      //At least 5 minutes between updates
      if (timestamp - lastUpdatedServer > 300000) {
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
}