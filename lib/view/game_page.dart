/// The page with the immunity degree plus points

import 'package:flutter/material.dart';
import '../game_logic/game_status.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

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
}