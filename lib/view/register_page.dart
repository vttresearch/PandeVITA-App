import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../communication/http_communication.dart';

/** Handles registering user to the platform server. User inputs their username
 * and email and creates a password. Should be one-time only. Based on
 * https://medium.com/@afegbua/flutter-thursday-13-building-a-user-registration-and-login-process-with-provider-and-external-api-1bb87811fd1d
 */

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final PandeVITAHttpClient client = PandeVITAHttpClient();
  var registering = false;
  late String username, password, confirmPassword, email;

  @override
  Widget build(BuildContext context) {
    final usernameField = TextFormField(
        autofocus: false,
        onSaved: (value) => username = value as String,
        validator: (value) => value!.isEmpty ? 'Please enter username' : null,
        decoration: const InputDecoration(
            icon: Icon(Icons.person), labelText: 'Enter username'));

    final emailField = TextFormField(
        autofocus: false,
        onSaved: (value) => email = value as String,
        validator: (value) => value!.isEmpty ? 'Please enter email' : null,
        decoration: const InputDecoration(
            icon: Icon(Icons.person), labelText: 'Enter email'));

    final passwordField = TextFormField(
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onSaved: (value) => password = value as String,
        decoration: const InputDecoration(
            icon: Icon(Icons.lock), labelText: 'Enter password'));

    final confirmPasswordField = TextFormField(
        autofocus: false,
        obscureText: true,
        validator: (value) => value!.isEmpty ? 'Please enter password' : null,
        onSaved: (value) => confirmPassword = value as String,
        decoration: const InputDecoration(
            icon: Icon(Icons.lock), labelText: 'Confirm password'));

    var loading = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        Text(" Registering ... Please wait")
      ],
    );
    //TODO: tee sähköpostikenttä
    doRegister() async {
      final form = formKey.currentState;
      if (form!.validate()) {
        form.save();
        registering = true;
        int success = await client.registerUser(
            username, password, email);
        print("SUCCESS $success");
        registering = false;
        if (success == 0) {
          var snackBar = const SnackBar(
            content: Text("Registration succesful"),
            duration: Duration(seconds: 5),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pushReplacementNamed(context, '/home');
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
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(40.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 215.0),
                  usernameField,
                  const SizedBox(height: 10.0),
                  emailField,
                  const SizedBox(height: 25.0),
                  passwordField,
                  const SizedBox(height: 15.0),
                  confirmPasswordField,
                  const SizedBox(height: 20.0),
                  registering == true
                      ? loading
                      : TextButton(
                          child: const Text("Register"), onPressed: doRegister),
                  const SizedBox(height: 5.0)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
