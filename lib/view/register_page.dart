import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../communication/http_communication.dart';
import '../Utility/styles.dart';

/** Handles registering user to the platform server. User inputs their username
 * and email and creates a password. Should be one-time only. Based on
 * https://medium.com/@afegbua/flutter-thursday-13-building-a-user-registration-and-login-process-with-provider-and-external-api-1bb87811fd1d
 */

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {

  var chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random random = Random();

  String dropdownValue = "Do not choose";
  String roleSelection = "Do not choose";

  final formKey = GlobalKey<FormState>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  var registering = false;
  late String username, password, confirmPassword, email;

  /**Generate a random string for the email. https://stackoverflow.com/a/61929967*/
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

  @override
  Widget build(BuildContext context) {
    final usernameField = TextFormField(
        autofocus: false,
        onSaved: (value) => username = value as String,
        validator: (value) => value!.isEmpty ? 'Please enter username' : null,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          focusColor: Colors.white,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ), floatingLabelStyle: TextStyle(color: Colors.white),
            icon: Icon(Icons.person), labelText: 'Enter username'));

    final emailField = TextFormField(
        autofocus: false,
        onSaved: (value) => email = value as String,
        validator: (value) => value!.isEmpty ? 'Please enter email' : null,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ), floatingLabelStyle: TextStyle(color: Colors.white),
            icon: Icon(Icons.person), labelText: 'Enter email'));

    final passwordField = TextFormField(
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onSaved: (value) => password = value as String,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ), floatingLabelStyle: TextStyle(color: Colors.white),
            icon: Icon(Icons.lock), labelText: 'Enter password'));

    final confirmPasswordField = TextFormField(
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onSaved: (value) => confirmPassword = value as String,
        cursorColor: Colors.white,
        decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ), floatingLabelStyle: TextStyle(color: Colors.white),
            icon: Icon(Icons.lock), labelText: 'Confirm password'));

    //List of possible roles of the user
    List<String> rolesList = ["Do not choose", "Academy", "Industry", "Public authority", "Other"];

    //Role selection dropdown
    final roleDropDown = DropdownButton<String>(
        dropdownColor: Colors.white,
        items: rolesList.map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (newValue != null) {
              roleSelection = newValue;
              dropdownValue = newValue;
            } else {
              roleSelection = "Do not choose";
            }
          });
        },
        value: dropdownValue);

    var loading = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        Text(" Registering ... Please wait")
      ],
    );

    doRegister() async {
      final form = formKey.currentState;
      if (form!.validate()) {
        form.save();
        email = getRandomString(16);
        setState(() {
          registering = true;
        });
        int success = await client.registerUser(
            username, password, email, roleSelection);
        debugPrint("SUCCESS $success");
        setState(() {registering = false;});
        if (success == 0) {
          int success = await client.createPlayer(username);
          if (success == 0) {
            var snackBar = const SnackBar(
              content: Text("Registration succesful"),
              duration: Duration(seconds: 5),
            );
            //Create a player instance on server

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.pushReplacementNamed(context, '/home');
          }

        } else if (success == 1) {
          var snackBar = const SnackBar(
            content: Text("Username is not available"),
            duration: Duration(seconds: 5),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          var snackBar = const SnackBar(
            content: Text("Registration Failed"),
            duration: Duration(seconds: 10),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        var snackBar = const SnackBar(
          content: Text("Complete the registration form"),
          duration: Duration(seconds: 10),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundBlue,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(40.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),
                  Image.asset('images/pandevita_logo_large.png', height: 200, ),
                  const SizedBox(height: 20.0),
                  usernameField,
                  const SizedBox(height: 10.0),
                  emailField,
                  const SizedBox(height: 10.0),
                  passwordField,
                  const SizedBox(height: 10.0),
                  confirmPasswordField,
                  const SizedBox(height: 10.0),
                  Text("Choose a PandeVITA dashboard role (optional)"),
                  const SizedBox(height: 5.0),
                  roleDropDown,
                  const SizedBox(height: 20.0),
                  registering == true
                      ? loading
                      : OutlinedButton(
                          child: const Text("Register", style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 25,
                          ),), onPressed: doRegister,
                  ),
                  const SizedBox(height: 5.0),
                  OutlinedButton(
                    child: const Text("Have an account? Sign in", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),), onPressed: () {Navigator.pushReplacementNamed(context, '/login');}
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
