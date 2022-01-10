/** Map page in the UI of the PandeVITA application */

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../game_logic/game_status.dart';
import 'ui_stats.dart';

class TabMap extends StatefulWidget {
  @override
  _TabMapState createState() => _TabMapState();
}

class _TabMapState extends State<TabMap> {
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
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 128, 198),
              border: Border.all(
                color: const Color.fromARGB(255, 238, 170, 0),
                width: 6
              ),
              borderRadius: BorderRadius.circular(8)
            ),
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
