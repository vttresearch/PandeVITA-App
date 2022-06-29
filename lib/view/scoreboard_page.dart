import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import 'ui_stats.dart';
import 'scoreboard.dart';

/** Page that shows the individual and team based scoreboards */

class ScoreboardPage extends StatefulWidget {
  @override
  ScoreboardPageState createState() => ScoreboardPageState();
}

class ScoreboardPageState extends State<ScoreboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
      Expanded(child: Row(children: [Expanded(child: Scoreboard())])),
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
                        /*const Text("500",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            )),*/
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
    ]));
  }
}
