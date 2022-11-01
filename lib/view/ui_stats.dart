/**This file contains classes to help displaying the correct stats
    to the player in the PandeVITA app UI*/
import 'package:flutter/material.dart';
import '../Utility/styles.dart';
import '../game_logic/game_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
  double barValue = 0.0;

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
    return Row(children: [
      SizedBox(
        width: 200,
        child: Stack(
          children: [
            Positioned(
              child: LinearPercentIndicator(
                width: 160.0,
                lineHeight: 14.0,
                percent: barValue,
                animation: false,
                barRadius: Radius.circular(7),
                backgroundColor: Colors.grey,
                progressColor: yellowColor,
              ),
              top: 22,
              left: 30,
            ),
            Image.asset("images/immunity_status_icon.png", width: 50),
            Positioned(
              child: Text(
                "IMMUNITY DEGREE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: yellowColor,
                  fontSize: 11
                )
              ),
              top: 40,
              left: 60,
            )
          ],
        )
      ),
      Text(immunityLevel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 25,
          ))
    ]);
  }

  void updateImmunityLevel() async {
    debugPrint("EVENT: IMMUNITY UPDATED");
    String newImmunity = await gameStatus.getImmunity();
    setState(() {
      immunityLevel = newImmunity;
      barValue = int.parse(newImmunity).toDouble() / 100.0;
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
    List vaccines = await gameStatus.getVaccineTimestamps();
    setState(() {
      vaccinationAmount = vaccines.length.toString();
    });
  }
}
