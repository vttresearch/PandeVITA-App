/** Action page in the UI of the PandeVITA application */

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:pandevita_game/Utility/styles.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../game_logic/game_status.dart';
import 'ui_stats.dart';

class TabAction extends StatefulWidget {
  @override
  _TabActionState createState() => _TabActionState();
}

class _TabActionState extends State<TabAction> {
  final controller = Get.find<RequirementStateController>();
  String _points = "0";

  @override
  void initState() {
    super.initState();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          //height: 25,
            decoration: boxDecorationYellowBorder,
            child:
            Column(
              children: [
                Row(
                  children: [
                    //POINTS
                    Image.asset("images/xp_star.png", width: 50),
                    PlayerPoints(),
                    //Vaccination
                    Image.asset("images/vaccination_icon.png", width: 50),
                    const Text("0"), //TODO: vaccination status
                  ],
                ),
                Row(
                    children: [
                      //Immunity status
                      Image.asset("images/immunity_status_icon.png", width: 50),
                      ImmunityLevel(),
                    ]

                )
              ],
            )



        )
    );
  }
}
