import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/communication/http_communication.dart';

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
  List individualScoreboard = [];

  //Timestamp
  var lastUpdatedScoreboard = 0;

  @override
  void initState() {
    getScoreboardFromServer();
    super.initState();
  }

  void getScoreboardFromServer() async {
    var currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    //At least 10 mins between updates to prevent spamming updates
    if ((currentTimeStamp - lastUpdatedScoreboard) < 600000) {
      return;
    }
    lastUpdatedScoreboard = currentTimeStamp;
    Map scoreboardData = await client.getScoreBoard();
    if (scoreboardData.isEmpty) {
      return;
    }
    for (var item in scoreboardData['players']) {
      individualScoreboard.add([item["playerName"], item["score"].toString()]);
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [
      Expanded(
          child: Row(
              children: [
                const Text("Scoreboard"),
                IconButton(icon: const Icon(Icons.refresh),
                    onPressed: getScoreboardFromServer)
              ]
          )
      ),
      ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();
          final index = i ~/ 2;
          if (showingIndividualStats) {
            return ListTile(
                title: Text(
                    (index + 1).toString() + '  ' +
                        individualScoreboard[index][0] +
                        '       ' +
                        individualScoreboard[index][1],
                    style: const TextStyle(fontSize: 18)));
          }
          return ListTile(title: const Text("error"));
        },
      )
    ]
    );
  }
}
