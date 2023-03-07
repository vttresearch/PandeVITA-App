import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../Utility/styles.dart';
import '../mixpanel.dart';
import '../communication/http_communication.dart';

/** This page handles the quiz history
 */

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({Key? key}) : super(key: key);

  @override
  QuizHistoryPageState createState() => QuizHistoryPageState();
}

class QuizHistoryPageState extends State<QuizHistoryPage> {
  var chosenQuiz = "0";
  late final Mixpanel mixpanel;
  Future<List?>? quizHistory;
  final PandeVITAHttpClient client = PandeVITAHttpClient();

  @override
  void initState() {
    super.initState();
    initMixpanel();
    //initQuizzes();
    quizHistory = client.getQuizHistory();
  }
  Future<void> initMixpanel() async {
    mixpanel = await Mixpanel.init(token,trackAutomaticEvents: true );
  }
 // Future<void> initQuizzes() async {
 //   quizHistory ??= {'Quizzes': 'Empty'};
 // }
  List<Widget> quizAnswers(questions, i, correct){
    List<Widget> list = [];
    for(var j=0; j<questions.length; j++) {
      list.add( Padding(child: ElevatedButton(
          onPressed: () {},
          child: Text( questions[j]),
          style: ElevatedButton.styleFrom(
            primary: questions[j] == correct ? Colors.green : yellowColor,
            onPrimary: Colors.white,
            padding: const EdgeInsets.only( top: 10.0, bottom: 10.0, right: 8.0, left: 8.0),
            shape: RoundedRectangleBorder( borderRadius: BorderRadius .circular(13.0)),
          )),
          padding: const EdgeInsets.symmetric( vertical: 0.0, horizontal: 10.0)
      ));
  }
    return list;
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: GestureDetector(
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30,),
          onTap: () => Navigator.of(context).pop()),
    ),
    backgroundColor: backgroundBlue,
    body: FutureBuilder<List?>(
      future: quizHistory,
      builder: (BuildContext context, AsyncSnapshot<List?> snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          //answeredMap.add({'id': quizQuestion['id'],
          //  'answer': quizQuestion['id'],
          //  'correctAnswer': '',
            //  'isCorrect': isCorrectAnswer,
            //});
            var questions = snapshot.data;
            final scrollContr = ScrollController();
            children = <Widget>[
              Expanded( child: Scrollbar(
                  controller: ScrollController(),
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView.builder(
                        itemCount: questions?.length,
                        itemBuilder: (context, i) {
                          var question = questions![i]['question'];
                          Map isCorrectIcon = {
                            'icon': Icons.question_mark_rounded,
                            'color': Colors.red
                          };
                          if (questions![i]['isCorrect'] != null) {
                            isCorrectIcon = questions[i]['isCorrect'] == true ?
                            {'icon': Icons.check_circle_rounded, 'color': Colors
                                .green,} :
                            {'icon': Icons.cancel_rounded, 'color': Colors
                                .redAccent,};
                          }
                          return ListTile(
                            //const Icon(Icons.check_circle_rounded, color: Colors.green,),
                            title: Padding(child: ElevatedButton(
                                onPressed: () {
                                  debugPrint(
                                      'Pressed question ${questions[i]}');
                                  chosenQuiz = questions[i]['id'];
                                  setState(() {});
                                },
                                child: Text( question as String, style: quizTextStyle),
                                style: ElevatedButton.styleFrom(
                                  primary: chosenQuiz == questions[i]['id']
                                      ? Colors.orangeAccent//Color.fromARGB(255, 207, 160, 30)
                                      : yellowColor,
                                  onPrimary: Colors.orange,
                                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, right: 8.0, left: 8.0),
                                  shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular( 13.0)),
                                )
                            ),
                                padding: const EdgeInsets.symmetric( vertical: 10.0,) //horizontal: 10.0)
                            ),
                            trailing: Padding(child: Icon(isCorrectIcon['icon'],
                              color: isCorrectIcon['color'], size: 30,),
                              padding: const EdgeInsets.symmetric( vertical: 10.0),),
                            subtitle: chosenQuiz == questions[i]['id'] ?
                              Container(
                                decoration: boxDecorationWhiteBorder,
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  //crossAxisAlignment: CrossAxisAlignment.start,
                                  children: quizAnswers(questions[i]['answers'], i, questions[i]['correctAnswer'])))
                                : null,
                          );
                        })
                  )
                )
              ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              const Icon( Icons.error_outline, color: Colors.red, size: 60, ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              ),
            ];
          } else {
            children = const <Widget>[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Awaiting result...'),
            ),
          ];
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    ),
    );
  }
}
