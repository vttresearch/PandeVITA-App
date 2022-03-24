/**The landing page checks whether the user has registered to the
 * game or not
 */

import 'package:flutter/material.dart';
import '../Utility/user.dart';
import 'home_page.dart';
import 'register_page.dart';

class LandingPage extends StatefulWidget {

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {

  late Future myFuture;
  int futureCalledTimes = 0;

  @override
  void initState() {
    myFuture = getUserData();

    super.initState();
  }

  Future<User?> getUserData() async {
    futureCalledTimes++;
    //Check if the user has registered or not
    debugPrint("FUTURE CALLED $futureCalledTimes times");
    User? userdata = await UserStorage().getUser();
    return userdata;
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        title: 'PandeVITA game application',
        home: FutureBuilder(
            future: myFuture,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  }
                  //If user has not registered
                  if (snapshot.data == null) {
                    return RegisterPage();
                  } else {
                    return HomePage();
                  }
              }
            }

        ),
        routes: {
          '/home': (context) => HomePage(),
        }
    );
  }
}