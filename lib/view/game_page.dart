/** The page with the immunity degree plus points**/

import 'package:flutter/material.dart';
import '../game_logic/game_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';

class GamePage extends StatefulWidget {
  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends State<GamePage> with WidgetsBindingObserver {
  String pointCounter = "0";
  GameStatus gameStatus = GameStatus();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PandeVITA Game',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PandeVITA game'),
        ),
        body: Center(
          child: Text(pointCounter)
        ),
      ),
    );
  }

  void _updatePoints() {
    setState(() {
      pointCounter = gameStatus.getPoints() as String;
    });
  }
  
}