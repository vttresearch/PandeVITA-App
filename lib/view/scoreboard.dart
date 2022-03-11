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

  var showIndividualScoreboard = true;

  PandeVITAHttpClient client = PandeVITAHttpClient();

  //2-dimensional list [["playerName", "score"], ["playerName2", "score2"]]
  List individualScoreboard = [
    ["Player name", "Score"]
  ];

  //Timestamp
  var lastUpdatedScoreboard = 0;

  @override
  void initState() {
    getScoreboardFromServer();
    super.initState();
  }

  void getScoreboardFromServer() async {
    var currentTimeStamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    //At least 10 mins between updates to prevent spamming updates
    if ((currentTimeStamp - lastUpdatedScoreboard) < 600000) {
      return;
    }
    lastUpdatedScoreboard = currentTimeStamp;
    Map scoreboardData = await client.getScoreBoard();
    if (scoreboardData.isEmpty) {
      return;
    }
    individualScoreboard.clear();
    for (var item in scoreboardData['players']) {
      individualScoreboard.add(
          [item["playerName"], item["playerScore"].toString()]);
    }
    print("individualscoreboard $individualScoreboard");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationWhiteBorder,
    child: Column(
        children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Scoreboard", style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 25,
            )
            ),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: getScoreboardFromServer,
            color: Colors.white,
            iconSize: 30)
          ]),
      Expanded(
        child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: individualScoreboard.length,
            itemBuilder: (context, i) {
              //if (i.isOdd) return const Divider();
              final index = i;
              if (showingIndividualStats) {
                return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            (index + 1).toString() +
                                '  ' +
                                individualScoreboard[index][0],
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.white, fontSize: 20)),
                        Text(
                                individualScoreboard[index][1],
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.white, fontSize: 20))
                      ]
                    ),

                  trailing: Image.asset('images/xp_star.png', width: 25));
              }
              return const ListTile(title: Text("error"));
            }),
      )
    ]));
  }
}
