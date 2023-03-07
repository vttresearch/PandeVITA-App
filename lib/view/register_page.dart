import 'dart:math';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../mixpanel.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:email_validator/email_validator.dart';
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

  String? dropdownValue;
  String? roleSelection;

  String? countryDropdownValue;
  String? countrySelection;

  final formKey = GlobalKey<FormState>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  var registering = false;
  late String username, password, confirmPassword, email;

  bool showInfo = false;
  bool agree = false;
  late final Mixpanel mixpanel;

  Future<String> loadPrivacyPolicy() async {
    return await rootBundle.loadString('asset_files/privacy_policy.md');
  }

  @override
  void initState(){
    super.initState();
    initMixpanel();
  }

  Future<void> initMixpanel() async {
    mixpanel = await Mixpanel.init(token,trackAutomaticEvents: true );
  }

  //Focus nodes could be used to change text field colors on focus change
  /* List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];


  @override
  void initState() {
    focusNodes.forEach((node){
      node.addListener(onFocusChange);
    });
    super.initState();
  }

  void onFocusChange() {
    {
      setState(() {});
    }
  }

  @override
  void dispose() {
    focusNodes.forEach((node){
      node.removeListener(onFocusChange);
      node.dispose();
    });
    debugPrint("registerPage disposed");
    super.dispose();
  }*/

  /**Generate a random string for the email. https://stackoverflow.com/a/61929967*/
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

  @override
  Widget build(BuildContext context) {
    //initMixpanel();
    final usernameField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        onSaved: (value) => username = (value as String).toLowerCase(),
        validator: (value) => value!.isEmpty ? 'Please enter username' : null,
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          border:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          floatingLabelStyle: TextStyle(color: Colors.black),
          icon: Icon(Icons.person, color: Colors.black),
          labelText: 'Username',
        ));

    final emailField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        onSaved: (value) => email = value as String,
        //Validate email
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter email';
          } else {
            if (EmailValidator.validate(value)) {
              return null;
            } else {
              return 'Please enter email';
            }
          }
        },
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          border:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          floatingLabelStyle: TextStyle(color: Colors.black),
          icon: Icon(Icons.email, color: Colors.black),
          labelText: 'Email',
        ));

    final passwordField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onChanged: (value) => password = value as String,
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          border:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          floatingLabelStyle: TextStyle(color: Colors.black),
          icon: Icon(Icons.lock, color: Colors.black),
          labelText: 'Password',
        ));

    final confirmPasswordField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        obscureText: true,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter password again';
          } else {
            if (confirmPassword == password) {
              return null;
            } else {
              return 'Needs to match with password';
            }
          }
        },
        onChanged: (value) => confirmPassword = value as String,
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          border:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          floatingLabelStyle: TextStyle(color: Colors.black),
          icon: Icon(Icons.lock, color: Colors.black),
          labelText: 'Confirm password',
        ));

    //List of possible roles of the user
    List<String> rolesList = [
      "Academy",
      "Industry",
      "Public authority",
      "Other"
    ];
    //List of possible countries of the user
    List<String> countriesList = [
      "Germany",
      "Netherlands",
      "Spain",
      "Turkey",
      "Finland"
    ];

    //Role selection dropdown
    final roleDropDown = DropdownButtonFormField<String>(
        style: const TextStyle(color: Colors.black),
        // focusColor: Colors.black,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
            labelStyle: TextStyle(color: Colors.black),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            )),
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
            }
          });
        },
        hint: Text("Choose your PandeVITA dashboard role",
            style: TextStyle(color: Colors.black)),
        validator: (value) => value == null ? "Required" : null,
        value: dropdownValue);

    //Country selection dropdown
    //Role selection dropdown
    final countryDropDown = DropdownButtonFormField<String>(
        style: const TextStyle(color: Colors.black),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
            labelStyle: TextStyle(color: Colors.black),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            )),
        items: countriesList.map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (newValue != null) {
              countrySelection = newValue;
              countryDropdownValue = newValue;
            }
          });
        },
        hint:
            Text("Choose your country", style: TextStyle(color: Colors.black)),
        validator: (value) => value == null ? "Required" : null,
        value: countryDropdownValue);

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

        setState(() {
          registering = true;
        });
      //  roleSelection = "Other";
        int success = await client.registerUser(
            username, password, email, roleSelection, countrySelection!);
        debugPrint("SUCCESS $success");
        setState(() {
          registering = false;
        });
        if (success == 0) {
          int success = await client.createPlayer(username);
          if (success == 0) {
            var snackBar = const SnackBar(
              content: Text("Registration successful"),
              duration: Duration(seconds: 5),
            );
            //Create a player instance on server

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            mixpanel.track("Registered");
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
        body: Container(
          decoration: backgroundDecoration,
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 40.0),
          height: double.infinity,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20.0),
                  Image.asset(
                    'images/pandevita_logo_large.png',
                    height: 100,
                  ),
                  const SizedBox(height: 10.0),
                  IconButton(
                      icon: Icon(Icons.info_outline,
                          color: Colors.white, size: 25),
                      onPressed: () {
                        showInfo = !showInfo;
                        setState(() {});
                      }),
                  if (showInfo)
                    Center(
                        child: Padding(
                            child: Text(
                                "You must include a valid username. Please, make sure you DO NOT USE YOUR REAL NAME, that it only contains LETTERS and NUMBERS and that there are no white spaces.",
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                  fontSize: 16,
                                )),
                            padding: const EdgeInsets.all(12.0))),
                  usernameField,
                  const SizedBox(height: 10.0),
                  emailField,
                  const SizedBox(height: 10.0),
                  passwordField,
                  const SizedBox(height: 10.0),
                  confirmPasswordField,
                  const SizedBox(height: 10.0),
                  countryDropDown,
                  const SizedBox(height: 10.0),
                  // Text("PandeVITA dashboard role"),
                  // const SizedBox(height: 5.0),
                  roleDropDown,
                //  const SizedBox(height: 10.0),
                  Row(children: [
                    Transform.scale(
                        child: Checkbox(
                          value: agree,
                          onChanged: (value) {
                            setState(() {
                              agree = value ?? false;
                            });
                          },
                          activeColor: Colors.black,
                        ),
                        scale: 1.3),
                    RichText(text: TextSpan(
                      children: [
                        TextSpan(text: "I accept "),
                        TextSpan(text: "privacy policy.",
                        style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          String privacyPolicy = await loadPrivacyPolicy();
                          //Show privacy policy
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              scrollable: true,
                              title: const Text('Scroll to see more'),
                              content: Container(
                                width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height/2,
                                  child: Markdown(
                                data: privacyPolicy
                              )),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, 'Close');
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                        )
                      ]
                    ))
                  ]),

                  registering == true
                      ? loading
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            onPrimary: Colors.grey,
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 25,
                            ),
                          ),
                          onPressed: agree && formKey.currentState!.validate() ? doRegister : null,
                        ),
                  const SizedBox(height: 5.0),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Colors.grey,
                      ),
                      child: Text(
                        "Have an account? Sign in",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: yellowColor,
                          fontSize: 20,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
