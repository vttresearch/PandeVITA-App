import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'controller/requirement_state_controller.dart';
import 'view/home_page.dart';
import 'view/landing_page.dart';
import 'package:get/get.dart';
import 'view/register_page.dart';
import 'view/login_page.dart';

void main() async {
  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  if (isProduction) {
    // analyser does not like empty function body
    // debugPrint = (String message, {int wrapWidth}) {};
    // so i changed it to this:
    debugPrint = (String? message, {int? wrapWidth}) => null;
  }
  //Hive db
 // await Hive.initFlutter();
 // await Hive.openBox("pandevita_box");
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(RequirementStateController());

    final themeData = Theme.of(context);
    final primary = Colors.blue;

    return GetMaterialApp(
        title: 'PandeVITA game application',
     /* theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: primary,
        appBarTheme: themeData.appBarTheme.copyWith(
          brightness: Brightness.light,
          elevation: 0.5,
          color: Colors.white,
          actionsIconTheme: themeData.primaryIconTheme.copyWith(
            color: primary,
          ),
          iconTheme: themeData.primaryIconTheme.copyWith(
            color: primary,
          ),
          textTheme: themeData.primaryTextTheme.copyWith(
            headline6: themeData.textTheme.headline6?.copyWith(
              color: primary,
            ),
          ),
        )
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: primary,
      ),*/
      home: LandingPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/landing': (context) => LandingPage(),
      }
    );
  }
}
