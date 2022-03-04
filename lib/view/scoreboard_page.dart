import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    return Column(children: [
      Expanded(
        child: Scoreboard(),
      ),
      Expanded(
          child: Row(children: [
        Expanded(
            child: Container(
                //height: 25,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 128, 198),
                    border: Border.all(
                        color: const Color.fromARGB(255, 238, 170, 0),
                        width: 6),
                    borderRadius: BorderRadius.circular(8)),
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
                        const Text("0",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            )), //TODO: vaccination status
                      ],
                    )),
                    Expanded(
                        child: Row(children: [
                      //Immunity status
                      Image.asset("images/immunity_status_icon.png", width: 50),
                      ImmunityLevel(),
                    ]))
                  ],
                )))
      ])),
    ]);
  }
}
