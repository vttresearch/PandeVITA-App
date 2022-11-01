import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import 'ui_stats.dart';
import 'scoreboard.dart';
import 'story_page.dart';

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
          const SizedBox(height: 5),
          OutlinedButton(
            onPressed: () {Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PandeVITAStories()),
            );},
            child: const Icon(Icons.newspaper, color: Colors.white, size: 50.0),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white, width: 5.0),
              shape: CircleBorder(),
              padding: EdgeInsets.all(10.0),
              primary: Color.fromARGB(255, 91, 197, 224), // <-- Button color// <-- Splash color
            ),
          ),
          const Text("News", style: TextStyle(fontSize: 14
              , color: Colors.white)),
      const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text("Scoreboard",
                style: settingsTextStyle)
          ]),
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
