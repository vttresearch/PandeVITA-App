import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import 'package:pandevita_game/communication/http_communication.dart';
import 'ui_stats.dart';
import 'scoreboard.dart';
import 'story_page.dart';

/** Page that shows the individual and team based scoreboards */

class ScoreboardPage extends StatefulWidget {
  @override
  ScoreboardPageState createState() => ScoreboardPageState();
}

class ScoreboardPageState extends State<ScoreboardPage> {
  PandeVITAHttpClient client = PandeVITAHttpClient();

  bool unwatchedNewsStories = false;
  bool unwatchedMobilityStories = false;
  bool unwatchedInfoStories = false;
  Timer? timer;

  //Check whether new stories are available on the server
  checkNewStories() async {
    debugPrint("checkNewStories");
    bool newsStoriesAvailable = await client.checkNewStories("news");
    bool mobilityStoriesAvailable = await client.checkNewStories("mobility");
    bool infoStoriesAvailable = await client.checkNewStories("info");
    unwatchedNewsStories = newsStoriesAvailable;
    unwatchedMobilityStories = mobilityStoriesAvailable;
    unwatchedInfoStories = infoStoriesAvailable;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    checkNewStories();
    //Check whether there are new stories available every 30 minutes from the platform
    timer = Timer.periodic(
        const Duration(minutes: 30), (Timer t) => checkNewStories());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              unwatchedNewsStories == true
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "news")),
                        );
                      },
                      child:
                          Icon(Icons.newspaper, color: yellowColor, size: 50.0),
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.yellow,
                        side: BorderSide(color: yellowColor, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "news")),
                        );
                      },
                      child: const Icon(Icons.newspaper,
                          color: Colors.white, size: 50.0),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    ),
              const Text("News",
                  style: TextStyle(fontSize: 14, color: Colors.white)),
            ]),
            //Travel rules
            Column(children: [
              unwatchedMobilityStories == true
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "mobility")),
                        );
                      },
                      child: Icon(Icons.flight_takeoff,
                          color: yellowColor, size: 50.0),
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.yellow,
                        side: BorderSide(color: yellowColor, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "mobility")),
                        );
                      },
                      child: const Icon(Icons.flight_takeoff,
                          color: Colors.white, size: 50.0),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    ),
              //covid info
              const Text("Travel rules",
                  style: TextStyle(fontSize: 14, color: Colors.white)),
            ]),
            Column(children: [
              unwatchedInfoStories == true
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "info")),
                        );
                      },
                      child: Icon(Icons.coronavirus,
                          color: yellowColor, size: 50.0),
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.yellow,
                        side: BorderSide(color: yellowColor, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  PandeVITAStories(topic: "info")),
                        );
                      },
                      child: const Icon(Icons.coronavirus,
                          color: Colors.white, size: 50.0),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white, width: 5.0),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(10.0),
                        primary: Color.fromARGB(255, 91, 197,
                            224), // <-- Button color// <-- Splash color
                      ),
                    ),
              const Text("Covid19 Info",
                  style: TextStyle(fontSize: 14, color: Colors.white)),
            ])
          ]),
          const SizedBox(height: 5),
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Scoreboard", style: settingsTextStyle)]),
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
