import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:story_view/story_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../communication/http_communication.dart';
import '../Utility/styles.dart';
import '../controller/requirement_state_controller.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:http/http.dart' as http;
import '../mixpanel.dart';

class PandeVITAStories extends StatelessWidget {

  String topic = "";
  late final Mixpanel mixpanel;

  PandeVITAStories({Key? key, String? topic}) : super(key: key) {
    initMixpanel(topic);
    if (topic != null) {
      this.topic = topic;
    }
  }

  PandeVITAHttpClient httpClient = PandeVITAHttpClient();
  List<StoryItem> storyList = [];


  Future<void> initMixpanel(topic) async {
    mixpanel = await Mixpanel.init(token,trackAutomaticEvents: true );
    mixpanel.track("Clicked on topic $topic");
  }

  /// Get the stories from server side
  Future<List?> getArticlesFromServer() async {
    //If there is a story topic
    List? articlesFromServer;
    if (topic != "") {
      articlesFromServer = await httpClient.getArticles(topic: topic);
    } else {
      articlesFromServer = await httpClient.getArticles();
    }

    if (articlesFromServer == null) {
      return null;
    } else {
      return articlesFromServer;
    }
  }

  Future<List> getLocalStories() async {
    String fileString =
        await rootBundle.loadString('images/exampleStories.json');
    debugPrint("local Stories read");
    final fileBody = jsonDecode(fileString);

    return fileBody['stories'];
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("building pandevita stories");
    return Scaffold(
      body: FutureBuilder<List?>(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null) {
              return const ErrorPage();
            } else {
              return StoryPage(
                articles: snapshot.data,
              );
            }
          }

          if (snapshot.hasError) {
            return const ErrorPage();
          }
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          );
        },
        future: getArticlesFromServer(),
        //future: getLocalStories(),
      ),
    );
  }
}

class StoryPage extends StatefulWidget {
  final List? articles;

  @override
  StoryPageState createState() => StoryPageState();

  StoryPage({this.articles});
}

class StoryPageState extends State<StoryPage> {
  final controller = Get.find<RequirementStateController>();
  final storyController = StoryController();
  List<StoryItem> storyItems = [];
  PandeVITAHttpClient client = PandeVITAHttpClient();

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    try {
      //Reverse the list of articles
      int storyAmount = 0;
      List articlesInReverse = widget.articles!.reversed.toList();
      for (Map article in articlesInReverse) {
        // Create stories of the 5 latest approved articles
        if (article["status"] == "2") {
          storyItems.add(createStoryItem(article, storyAmount));
          //   storyTexts.add(createStoryText(article));
          storyAmount++;
        }
        //Maximum of 5 stories
        if (storyAmount > 4) {
          break;
        }
      }
    } catch (error) {
      debugPrint(
          "error in parsing the stories in story_page:initState(): $error");
    }
  }

  List<String> linkList = [];
  int pos = 0;
  List<String> storyIdList = [];

  /// Create a custom story item. Based on the story_view library views.
  StoryItem createStoryItem(Map article, int index) {
    String caption = article["title_en"];
    bool shown = false;
    String storyText = article["description_en"];
    String articleTopic = article["topic"];
    String imageLocation = "images/news/politics.png";

    String link = article["link"];
    linkList.add(link);
    storyIdList.add(article["id"]);

    //Generate topic image
    switch (articleTopic) {
      case "1":
        imageLocation = "images/news/research.png";
        break;
      case "2":
        imageLocation = "images/news/health.png";
        break;
      case "3":
        imageLocation = "images/news/socioeconomic.png";
        break;
      case "4":
        imageLocation = "images/news/environment.png";
        break;
      case "5":
        imageLocation = "images/news/mobility.png";
        break;
      case "6":
        imageLocation = "images/news/vaccines.png";
        break;
      case "7":
        break;
      case "8":
        imageLocation = "images/news/gender.jpg";
        break;
    }

    return StoryItem(
        Container(
          color: backgroundBlue,
          child: Stack(
            children: <Widget>[
              Image(
                    alignment: Alignment.topLeft,
                    width: double.infinity,
                    height: 200.0,
                    fit: BoxFit.fitWidth,
                    image: AssetImage(imageLocation),
                  ),

              //Use layout builder to position the texts
              //https://stackoverflow.com/a/51704903
              LayoutBuilder(
                  builder: (context, constraints) => Column(
                        children: [
                          SizedBox(
                              height: (constraints.maxHeight -
                                      constraints.minHeight) *
                                  0.3),
                          Center(
                              child: Padding(
                                  child: Text(caption, style: storyTitleStyle),
                                  padding: const EdgeInsets.all(12.0))),
                          SizedBox( height: (constraints.maxHeight -
                              constraints.minHeight) *
                              0.05),
                          Center(
                              child: Padding(
                                  child: Text(storyText, style: storyTextStyle, overflow: TextOverflow.ellipsis, maxLines: 10),
                                  padding: const EdgeInsets.all(12.0))),
                          const Spacer(),
                          const Center(
                              child: Padding(
                                  child: Text("Swipe up to open the article in a browser", style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white
                                  )),
                                  padding: EdgeInsets.all(12.0))),
                          const Spacer(),
                        ],
                      ))
            ],
          ),
        ),
        shown: shown,
        duration: const Duration(seconds: 10));
  }


  String createCaption(Map article) {
    return article["title_en"];
  }

  String createStoryText(Map article) {
    return article["description_en"];
  }

  void openLinkInBrowser(String link) async {
    var uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      final resp = await http.head(uri);
      // if response code for head was not 2**, use with get instead
      if (resp.statusCode ~/ 100 != 2) {
        final resp = await http.get(uri);
      }
      final data = resp.headers;
      if (data['content-type'] == 'application/pdf'){
      Navigator.push(
          context,
          MaterialPageRoute( builder: (context) => PDFViewerCachedFromUrl(url: link, ) ),
      );
      }
      else{
       await launchUrl(uri);
      }
    } else {
      var snackBar = const SnackBar(
        content: Text("Sorry, could not open the article in browser."),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }


  @override
  Widget build(BuildContext context) {
    return StoryView(
      storyItems: storyItems,
      onStoryShow: (s) {
        debugPrint("Showing a story");
        pos = storyItems.indexOf(s);
      },
      onComplete: () {
        Navigator.of(context).pop();
        controller.storyWatched();
        client.storiesWatched(storyIdList);

      },
      onVerticalSwipeComplete: (v) {
        if (v == Direction.down) {
          Navigator.pop(context);
        }
        else if (v == Direction.up) {
          openLinkInBrowser(linkList[pos]);
        }
      },
      progressPosition: ProgressPosition.top,
      repeat: false,
      controller: storyController,
    );
  }
}

class PDFViewerCachedFromUrl extends StatelessWidget {
  const PDFViewerCachedFromUrl({Key? key, required this.url}) : super(key: key);

  final String url;

  @override
  Widget build(BuildContext context) {
    return
      SafeArea(child:
      Scaffold(
        body: const PDF(pageSnap: false, pageFling: false).cachedFromUrl(
          url,
          placeholder: (double progress) => Center(child: Text('$progress %')),
          errorWidget: (dynamic error) => Center(child: Text(error.toString())),
        ),
      )
    );
  }
}


class ErrorPage extends StatelessWidget {
  const ErrorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: const <Widget>[
            Icon(
              Icons.cancel,
              color: Colors.red,
            ),
            SizedBox(
              width: 16,
            ),
            Text("An error occurred while loading stories.")
          ],
        ),
      ),
    );
  }
}
