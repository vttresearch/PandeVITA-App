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
  bool isQuestionAvailable = false;
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
    timer?.cancel();
    super.dispose();
  }

  ///Answer a question in the quiz
  void answerQuestion(String questionId, String answer, String correctAnswer) {
    isAnsweringQuiz = true;
    bool answerWasCorrect = false;
    if (answer == correctAnswer) {
      totalScore += immunityPerQuestion;
      answerWasCorrect = true;
      var snackBar = const SnackBar(
        content: Text("Correct answer!"),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      var snackBar = SnackBar(
        content: Text("Wrong answer! The correct answer was: " + correctAnswer),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    gameStatus.answeredQuizQuestion(questionId);
    client.updateQuizAnswer(questionId, answerWasCorrect);
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
    isQuestionAvailable = false;
    isQuizAlreadyAnswered = false;

    List? quizFromServer = await client.getQuiz();
    if (quizFromServer == null) {
      setState(() {});
      return;
    }
    isQuizAlreadyAnswered = true;
    if (quizFromServer.isNotEmpty) {
      isQuestionAvailable = true;
      bool newQuestions = false;
      for (Map question in quizFromServer) {
        currentQuizId = question['id'];
        //Do not display already answered questions
        if (await gameStatus.isQuizQuestionAnswered(currentQuizId)) {
          continue;
        }
        newQuestions = true;
        currentQuiz.add(question);
        isAnsweringQuiz = true;
        isQuizAlreadyAnswered = false;
      }
      //Update UI
      setState(() {});
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    var quizResult = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
            child: Text(
                "You have answered to the most recent questions available",
                style: settingsTextStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0)),
        //Text("You got $totalScore immunity points", style: settingsTextStyle),
        Padding(
            child: Text("Check this tab later to find new questions",
                style: settingsTextStyle),
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0))
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
                if (isQuestionAvailable && !isQuizAlreadyAnswered)
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
                if (isQuestionAvailable && isQuizAlreadyAnswered) quizResult,
                //If no quiz available, default option
                if (!isQuestionAvailable)
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

    debugPrint("listview length ${(questions[questionIndex]['answers'] as List).length}");
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            child: Text(
              questions[questionIndex]['question'] as String,
              maxLines: 3,
              style: quizTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0)),
        //Question
        Expanded(child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            controller: ScrollController(),
            child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: (questions[questionIndex]['answers'] as List).length,

            itemBuilder: (context, i) {
              var answer = (questions[questionIndex]['answers'] as List)[i];
              return Padding(child: ElevatedButton(
                      onPressed: () => answerQuestion(
                          questions[questionIndex]['id'],
                          answer,
                          questions[questionIndex]['correctAnswer']),
                      child: Text(answer as String, style: quizTextStyle),
                      style: ElevatedButton.styleFrom(
                        primary: yellowColor,
                        onPrimary: Colors.orange,
                        padding: const EdgeInsets.only(
                            top: 10.0, bottom: 10.0, right: 8.0, left: 8.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.0)),
                      )), padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0));
            })))
      ],
    ); //Column
  }
}
