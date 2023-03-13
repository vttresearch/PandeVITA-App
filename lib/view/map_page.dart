/// Map page in the UI of the PandeVITA application

import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'ui_stats.dart';
import 'radar.dart';
import '../Utility/styles.dart';

class TabMap extends StatefulWidget {
  const TabMap({Key? key}) : super(key: key);

  @override
  _TabMapState createState() => _TabMapState();
}

class _TabMapState extends State<TabMap> {
  final controller = Get.find<RequirementStateController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
    Row(
      children: [
    Text("Radar", style: settingsTextStyle)]),
      Expanded(
          child: Row(children: [
        Expanded(
          child: Container(
            decoration: boxDecorationRadar,
            child: Radar(),
          )
        )
      ])),
      const SizedBox(height: 20),
      Container(
          height: 200,
          decoration: boxDecorationYellowBorder,
          child: Column(
            children: [
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //POINTS
                  Image.asset("images/xp_star.png", width: 50),
                  const SizedBox(width: 20),
                  PlayerPoints(),
                  //Vaccination
                  const SizedBox(width: 100),
                  Image.asset("images/vaccination_icon.png", width: 50),
                  const SizedBox(width: 20),
                  VaccinationAmount(),
                ],
              )),
              Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    //Immunity status
                    ImmunityLevel(),
                  ]))
            ],
          )),
    ]);
  }
}
