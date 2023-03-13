import 'package:flutter/material.dart';
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
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(RequirementStateController());
    return GetMaterialApp(
        title: 'PandeVITA game application',
      home: const LandingPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/landing': (context) => const LandingPage(),
      }
    );
  }
}
