/**The landing page checks whether the user has registered to the
 * game or not
 */

import 'package:flutter/material.dart';
import '../Utility/user.dart';
import 'home_page.dart';
import 'register_page.dart';

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //Check if the user has registered or not
    Future<User?> getUserData() => UserStorage().getUser();

    return MaterialApp(
      title: 'PandeVITA game application',
      home: FutureBuilder(
        future: getUserData(),
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