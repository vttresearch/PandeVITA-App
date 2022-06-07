/*** This handles the quiz page of the application. The users answer
 * the quizzes to gain additional points in the game. This is heavily based
 * on this tutorial https://www.geeksforgeeks.org/basic-quiz-app-in-flutter-api/
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import 'ui_stats.dart';
import '../communication/http_communication.dart';
import '../Utility/user.dart';
import '../game_logic/game_status.dart';

class QuizPage extends StatefulWidget {
  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  final UserStorage storage = UserStorage();
  final GameStatus gameStatus = GameStatus();

  List currentQuiz = [];
  late String currentQuizId;

  //Control variables
  bool isQuizAvailable = false;
  bool isQuizAlreadyAnswered = false;
  bool isAnsweringQuiz = false;

  Timer? timer;

  //Edit this to control the amount of immunity user gets per right answer
  var immunityPerQuestion = 5;

  var questionIndex = 0;
  var totalScore = 0;

  @override
  void initState() {
    super.initState();
    getQuizFromServer();
    //Get a new quiz every 60 minutes from the platform
    timer = Timer.periodic(
        const Duration(minutes: 60), (Timer t) => getQuizFromServer());
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  ///Answer a question in the quiz
  void answerQuestion(String answer, String correctAnswer) {
    isAnsweringQuiz = true;
    if (answer == correctAnswer) {
      totalScore += immunityPerQuestion;
    }

    // setState(() {
    questionIndex = questionIndex + 1;
    //  });
    debugPrint(questionIndex.toString());
    if (questionIndex < currentQuiz.length) {
      debugPrint('We have more questions!');
    } else {
      //Quiz is over, add immunity
      gameStatus.modifyImmunity(totalScore);
      gameStatus.saveQuizScore(currentQuizId, totalScore);
      debugPrint('No more questions!');
      isAnsweringQuiz = false;
    }

    //Update UI
    setState(() {});
  }

  ///Get the most recent quiz from the server
  void getQuizFromServer() async {
    //Don't update if the user is answering the most current quiz
    if (isAnsweringQuiz) {
      return;
    }
    //Control variables
    isQuizAvailable = false;
    isQuizAlreadyAnswered = false;

    Map quizFromServer = await client.getQuiz();
    if (quizFromServer.isNotEmpty) {
      //Something has gone wrong
      if (quizFromServer.containsKey('error')) {
        //Update UI
        setState(() {});
        return;
      }
      isQuizAvailable = true;
      currentQuizId = quizFromServer['id'];
      //Check if the user has already answered to the quiz
      if (await gameStatus.isQuizAnswered(currentQuizId)) {
        totalScore = await gameStatus.getLastQuizScore();
        //Update UI
        setState(() {
          isQuizAlreadyAnswered = true;
        });
        return;
      }
      //The user has not answered to the quiz yet
      currentQuiz = quizFromServer['quiz'];
      setState(() {});
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    var quizResult = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text("You have answered to the most recent quiz",
            style: settingsTextStyle, overflow: TextOverflow.ellipsis, maxLines: 2),
        Text("You got $totalScore points", style: settingsTextStyle),

            Text("Check this tab later to find a new quiz",
                style: settingsTextStyle)
      ],
    );

    return Column(children: [
      Row(
        children: [
          Text("Quiz", style: settingsTextStyle),
        ],
      ),
      Expanded(
        child: Container(
            decoration: boxDecorationWhiteBorder,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //If a new quiz is available and it has not been answered yet
                if (isQuizAvailable && !isQuizAlreadyAnswered)
                  //Show quiz
                  questionIndex < currentQuiz.length
                      ? Expanded(
                          child: Quiz(
                          answerQuestion: answerQuestion,
                          questionIndex: questionIndex,
                          questions: currentQuiz,
                        ))
                      : Expanded(child: quizResult),
                //If the newest quiz has already been answered
                if (isQuizAvailable && isQuizAlreadyAnswered) quizResult,
                //If no quiz available, default option
                if (!isQuizAvailable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("No quiz currently available",
                          style: settingsTextStyle)
                    ],
                  ),
              ],
            )),
      ),
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
                  //Vaccination
                  const SizedBox(width: 100),
                  Image.asset("images/vaccination_icon.png", width: 50),
                  const SizedBox(width: 20),
                  VaccinationAmount(), //TODO: vaccination status
                ],
              )),
              Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    //Immunity status
                    Image.asset("images/immunity_status_icon.png", width: 50),
                    const SizedBox(width: 20),
                    ImmunityLevel(),
                  ]))
            ],
          )),
    ]);
  }
}

class Quiz extends StatelessWidget {
  final List questions;
  final int questionIndex;
  final Function answerQuestion;

  Quiz({
    required this.questions,
    required this.answerQuestion,
    required this.questionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          questions[questionIndex]['quizItem']['question'] as String,
          maxLines: 3,
          style: quizTextStyle,
          overflow: TextOverflow.ellipsis,
        ),
        //Question
        ...(questions[questionIndex]['quizItem']['answers'] as List)
            .map((answer) {
          return ElevatedButton(
              onPressed: () => answerQuestion(answer,
                  questions[questionIndex]['quizItem']['correctAnswer']),
              child: Text(answer as String, style: quizTextStyle),
              style: ElevatedButton.styleFrom(
                primary: yellowColor,
                padding: const EdgeInsets.only(
                    top: 10.0, bottom: 10.0, right: 8.0, left: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13.0)),
              ));
        }).toList()
      ],
    ); //Column
  }
}
