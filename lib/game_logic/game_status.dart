import 'package:shared_preferences/shared_preferences.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
/* Singleton class that contains the game data of the user*/

class GameStatus {
  static final GameStatus _gameStatus = GameStatus._privateConstructor();
  final controller = Get.find<RequirementStateController>();
  bool pointsChanged = false;

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
  }

  //Get points for display
  Future<String> getPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int playerPoints = (prefs.getInt('playerPoints') ?? 0);
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


}