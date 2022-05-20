/**This file contains classes to help displaying the correct stats
    to the player in the PandeVITA app UI*/
import 'package:flutter/material.dart';
import '../game_logic/game_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';

class PlayerPoints extends StatefulWidget {
  @override
  PlayerPointsState createState() => PlayerPointsState();
}

class PlayerPointsState extends State<PlayerPoints> {
  final controller = Get.find<RequirementStateController>();
  String pointCounter = "0";
  final GameStatus gameStatus = GameStatus();

  @override
  void initState() {
    super.initState();
    updatePoints();
    controller.playerPointsChangedStream.listen((flag) {
      updatePoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(pointCounter,
        style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 25,
    ));
  }

  //Update points on screen
  void updatePoints() async {
    debugPrint("EVENT: UPDATEPOINTS");
    String points = await gameStatus.getPoints();
    setState(() {
      pointCounter = points;
    });
  }
}

class ImmunityLevel extends StatefulWidget {
  @override
  ImmunityLevelState createState() => ImmunityLevelState();
}

class ImmunityLevelState extends State<ImmunityLevel> {
  final GameStatus gameStatus = GameStatus();
  final controller = Get.find<RequirementStateController>();
  String immunityLevel = "0";

  @override
  void initState() {
    super.initState();
    updateImmunityLevel();
    controller.immunityLevelChangedStream.listen((flag) {
      updateImmunityLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(immunityLevel,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,

        ));
  }

  void updateImmunityLevel() async {
    debugPrint("EVENT: IMMUNITY UPDATED");
    String newImmunity = await gameStatus.getImmunity();
    setState(() {
      immunityLevel = newImmunity;
    });
  }


}

class VaccinationAmount extends StatefulWidget {
  @override
  VaccinationAmountState createState() => VaccinationAmountState();
}

class VaccinationAmountState extends State<VaccinationAmount> {
  final GameStatus gameStatus = GameStatus();
  final controller = Get.find<RequirementStateController>();
  String vaccinationAmount = "0";

  @override
  void initState() {
    super.initState();
    updateVaccinationAmount();
    controller.vaccinationAmountChangedStream.listen((flag) {
      updateVaccinationAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(vaccinationAmount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,

        ));
  }

  void updateVaccinationAmount() async {
    debugPrint("EVENT: Vaccination amount UPDATED");
    List<String> vaccines = await gameStatus.getVaccineTimestamps();
    setState(() {
      vaccinationAmount = vaccines.length.toString();
    });
  }


}