import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/communication/http_communication.dart';
import '../Utility/styles.dart';

/** Team and individual scoreboards*/

class Scoreboard extends StatefulWidget {
  @override
  ScoreboardState createState() => ScoreboardState();
}

class ScoreboardState extends State<Scoreboard> {
  bool showingIndividualStats = true;

  Timer? timer;

  var showIndividualScoreboard = true;

  PandeVITAHttpClient client = PandeVITAHttpClient();

  List<bool> isSelectedScoreboard = [true, false];

  //2-dimensional list [["playerName", "score"], ["playerName2", "score2"]]
  List individualScoreboard = [
    ["Player name", "Score"]
  ];

  //Map of player scores for utility purposes
  Map<String, int> playerScores = {};

  //Map of team scores for utility purposes
  late Map<String, int> teamScores;

  //2-dimensional list [["teamName", "score"], ["teamName2", "score2"]]
  List teamScoreboard = [
    ["Team name", "Score"]
  ];

  //Timestamp
  var lastUpdatedScoreboard = 0;

  @override
  void initState() {
    super.initState();
    getScoreboardFromServer();
    timer = Timer.periodic(const Duration(minutes: 5), (Timer t) => getScoreboardFromServer());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
       if (timer != null) {
        if (!timer!.isActive) {
          timer = Timer.periodic(const Duration(minutes: 5), (Timer t) => getScoreboardFromServer());
        }
      } else {
        timer = timer = Timer.periodic(const Duration(minutes: 5), (Timer t) => getScoreboardFromServer());
      }
    } else if (state == AppLifecycleState.paused) {
      timer?.cancel();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void getScoreboardFromServer() async {
    var currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    //At least 1 minute between updates to prevent spamming updates
    if ((currentTimeStamp - lastUpdatedScoreboard) < 60000) {
      return;
    }
    lastUpdatedScoreboard = currentTimeStamp;
    Map scoreboardData = await client.getScoreBoard();
    if (scoreboardData.isEmpty) {
      return;
    }
    individualScoreboard.clear();
    for (var item in scoreboardData['players']) {
      individualScoreboard.add([item["playerName"], item["score"]]);
      playerScores[item['playerName']] = item['score'];
    }
    //Sort the individual scoreboard
    individualScoreboard.sort((a, b) => b[1].compareTo(a[1]));
    //Create team scoreboard
    var teams = await client.getTeams();
    var teamsFiltered = teams.where((team) => team["teamPlayers"].length > 3);
    for (var team in teamsFiltered) {
      var teamName = team["teamName"];
      var teamScore = 0;
      for (var player in team["teamPlayers"]) {
        var playerScore = playerScores[player];
        teamScore += playerScore!;
      }
      teamScoreboard.add([teamName, teamScore]);
    }
    teamScoreboard.sort((a, b) => b[1].compareTo(a[1]));
    debugPrint("individualscoreboard $individualScoreboard");
    debugPrint("teamscoreboard $teamScoreboard");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: boxDecorationWhiteBorder,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Scoreboard",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 25,
                )),
            /*IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: getScoreboardFromServer,
                color: Colors.white,
                iconSize: 30)*/
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                children: <Widget>[
                  Row(children: [
                    const SizedBox(width: 5),
                    Image.asset('images/individual_icon.png', width: 20),
                    const SizedBox(width: 5),
                    const Text("INDIVIDUAL"),
                    const SizedBox(width: 5),
                  ]),
                  Row(
                    children: [
                      const SizedBox(width: 5),
                      Image.asset('images/team_icon.png', width: 20),
                      const SizedBox(width: 5),
                      const Text("TEAM"),
                      const SizedBox(width: 5),
                    ],
                  )
                ],
                onPressed: (int index) {
                  setState(() {
                    for (int buttonIndex = 0;
                        buttonIndex < isSelectedScoreboard.length;
                        buttonIndex++) {
                      if (buttonIndex == index) {
                        isSelectedScoreboard[buttonIndex] = true;
                      } else {
                        isSelectedScoreboard[buttonIndex] = false;
                      }
                    }
                  });
                },
                isSelected: isSelectedScoreboard,
                disabledColor: Colors.grey,
                fillColor: Colors.white,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ],
          ),
          isSelectedScoreboard[0] == true
              ?
              //If showing individual scoreboard
              Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      getScoreboardFromServer();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: individualScoreboard.length,
                      itemBuilder: (context, i) {
                        //if (i.isOdd) return const Divider();
                        final index = i;

                        return ListTile(
                            title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      (index + 1).toString() +
                                          '  ' +
                                          individualScoreboard[index][0],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20)),
                                  Text(individualScoreboard[index][1].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20))
                                ]),
                            trailing:
                                Image.asset('images/xp_star.png', width: 25));
                      })),
                  //If showing team scoreboard
                )
              : Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      getScoreboardFromServer();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: teamScoreboard.length,
                      itemBuilder: (context, i) {
                        //if (i.isOdd) return const Divider();
                        final index = i;
                        return ListTile(
                            title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      (index + 1).toString() +
                                          '  ' +
                                          teamScoreboard[index][0],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20)),
                                  Text(teamScoreboard[index][1].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 20))
                                ]),
                            trailing:
                                Image.asset('images/xp_star.png', width: 25));
                      }),
                ))
        ]));
  }
}
