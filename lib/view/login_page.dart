import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/styles.dart';
import 'register_page.dart';
import '../communication/http_communication.dart';
import '../Utility/user.dart';

/** This page handles the login process. It opens when the user opens
 * the application for the first time. Based heavily on
    https://medium.com/@afegbua/flutter-thursday-13-building-a-user-registration-and-login-process-with-provider-and-external-api-1bb87811fd1d
    https://github.com/shubie/flutter-thursday-login-registration
 */

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  late String username, password;
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  final UserStorage storage = UserStorage();

  TextEditingController _textFieldController = TextEditingController();

  bool loggingIn = false;
  bool showInfo = false;

  String recoverEmail = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final usernameField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        onSaved: (value) => username = value as String,
        validator: (value)   => value!.isEmpty ? 'Please enter username' : null,
        cursorColor: Colors.black,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ), floatingLabelStyle: TextStyle(color: Colors.black),
          icon: Icon(Icons.person, color: Colors.black), labelText: 'Enter username'));

    final passwordField = TextFormField(
        style: TextStyle(color: Colors.black),
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onSaved: (value) => password = value as String,
        cursorColor: Colors.black,
        decoration: InputDecoration(
            labelStyle: TextStyle(color: Colors.black),
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ), floatingLabelStyle: TextStyle(color: Colors.black),
            icon: Icon(Icons.lock, color: Colors.black), labelText: 'Enter password'));

    var loading = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        Text("Logging in ... Please wait")
      ],
    );

    final registerLabel = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextButton(
          child: const Text("Sign up", style: TextStyle(fontWeight: FontWeight.w300)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
        ),
      ],
    );

    doLogin() async {
      final form = formKey.currentState;

      if (form!.validate()) {

        setState(() {
          loggingIn = true;
        });
        form.save();

        //bool succession = true;
        bool succession = await client.tryLogin(username, password);
        setState(() {loggingIn = false;});

        //If login was unsuccessful
        if (succession == false) {
          var snackBar = const SnackBar(
            content: Text("Login failed"),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        //If login was successful
        else {
          var snackBar = const SnackBar(
            content: Text("Login successful"),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pushReplacementNamed(context, '/home');
        }

      } else {
        var snackBar = const SnackBar(
          content: Text("Complete the login form"),
          duration: Duration(seconds: 5),
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
                  const SizedBox(height: 20),
                  Image.asset('images/pandevita_logo_large.png', height: 200, ),
                  const SizedBox(height: 20.0),
                  IconButton(icon: Icon(Icons.info_outline, color: Colors.white, size: 25),
                      onPressed: () {showInfo = !showInfo; setState(() {});}),
                  if (showInfo) Center(
                      child: Padding(
                          child: Text("The PandeVITA account you create is the same for the dashboard and the application."
                              "You can log in with an account created on the dashboard. If you create an account in the application,"
                              "you will be able to use the dashboard with the same account.", style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            fontSize: 16,
                          )),
                          padding: const EdgeInsets.all(12.0))),
                  usernameField,
                  const SizedBox(height: 20.0),
                  passwordField,
                  const SizedBox(height: 20.0),
                  loggingIn == true
                      ? loading
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      onPrimary: Colors.grey,
                    ),
                    child: const Text("Log in", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 25,
                    ),), onPressed: doLogin,
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      onPrimary: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0)
                    ),
                    child: Text("Don't have a PandeVITA account yet? Create an account", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: yellowColor,
                      fontSize: 20,
                    ),), onPressed: () {Navigator.pushReplacementNamed(context, '/register');},
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: Colors.grey,
                        onPrimary: Colors.blueGrey,
                        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0)
                    ),
                    child: Text("Forgot password?", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 20,
                    ),), onPressed: () => showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Recover password'),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text("Enter your email and we'll send you the password reset link."),
                        TextField(
                        onChanged: (value) {
                          recoverEmail = value;
                          setState(() {
                          });
                        },
                        controller: _textFieldController,
                        decoration: const InputDecoration(
                            hintText: "Email"),
                      )]),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'Cancel');
                            _textFieldController.clear();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'Submit');
                            if (EmailValidator.validate(recoverEmail)) {
                              client.sendResetPassword(recoverEmail);
                              var snackBar = const SnackBar(
                                content: Text("Check your email for further instructions."),
                                duration: Duration(seconds: 3),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            } else {
                              var snackBar = const SnackBar(
                              content: Text("Did not enter a valid email"),
                              duration: Duration(seconds: 3),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            }
                            _textFieldController.clear();
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
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