import 'package:flutter/material.dart';

/** Utility file for styling up the UI.*/

var backgroundBlue = const Color.fromARGB(255, 36, 128, 198);
var yellowColor = const Color.fromARGB(255, 238, 170, 0);
var whiteColor = const Color.fromARGB(255, 255, 255, 255);

var boxDecorationYellowBorder = BoxDecoration(
    //  color: const Color.fromARGB(255, 36, 128, 198),
    border: Border.all(color: const Color.fromARGB(255, 238, 170, 0), width: 2),
    borderRadius: BorderRadius.circular(8));

var boxDecorationWhiteBorder = BoxDecoration(
    // color: const Color.fromARGB(255, 36, 128, 198),
    border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
    borderRadius: BorderRadius.circular(8));

var boxDecorationRadar = BoxDecoration(
    color: const Color.fromARGB(255, 0, 72, 126),
    border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
    borderRadius: BorderRadius.circular(8));

var backgroundDecoration = const BoxDecoration(
  gradient: LinearGradient(
      colors: [Color.fromARGB(255, 36, 128, 198), Color.fromARGB(255, 91, 197, 224)],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp),
);

var settingsTextStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20);

var settingsTextStyleTeamAct = const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17);

var settingsTextStyleAlt = const TextStyle(
    // fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: 20);

var backgroundDecorationInfected3days = const BoxDecoration(
  gradient: LinearGradient(
      colors: [Color.fromARGB(255, 212, 24, 0), Color.fromARGB(255, 216, 116, 101)],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp),
);

var backgroundDecorationInfected2days = const BoxDecoration(
  gradient: LinearGradient(
      colors: [Color.fromARGB(255, 212, 96, 0), Color.fromARGB(255, 216, 167, 101)],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp),
);

var backgroundDecorationInfected1days = const BoxDecoration(
  gradient: LinearGradient(
      colors: [Color.fromARGB(255, 0, 212, 117), Color.fromARGB(255, 101, 216, 166)],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      stops: [0.0, 1.0],
      tileMode: TileMode.clamp),
);

var quizTextStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18);

var storyTitleStyle = TextStyle(fontWeight: FontWeight.bold, color: yellowColor, fontSize: 25);

var storyTextStyle = const TextStyle(
    //fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: 14);
