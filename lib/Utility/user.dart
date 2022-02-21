/** This file takes care of all the user related things in the application */

import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class User {
  String userId;
  String name;
  String email;
  String password;
  String? token;
  String? renewalToken;

  User({required this.userId, required this.name, required this.email,
    required this.password});

  //TODO: This is wrong, to be fixed
  factory User.fromJson(Map<String, dynamic> responseData) {
    return User(
        userId: responseData['id'],
        name: responseData['name'],
        email: responseData['email'],
        password: responseData['credentials'][0]['value']
    );
  }
}

class UserStorage {
  Future<bool> saveUser(User user) async {
    const storage = FlutterSecureStorage();

    await storage.write(key: "userId", value: user.userId);
    await storage.write(key: "username", value: user.name);
    await storage.write(key: "email", value: user.email);
    await storage.write(key: "password", value: user.password);

    return true;
  }

  Future<User?> getUser() async {
    const storage = FlutterSecureStorage();

    var userId = await storage.read(key: "userId");
    var name = await storage.read(key: "username");
    var email = await storage.read(key: "email");
    var password = await storage.read(key: "password");
    if (userId == null || name == null || email == null || password == null) {
      return null;
    }
    return User(
        userId: userId,
        name: name,
        email: email,
        password: password);

  }

  Future<String> getUserName() async {
    const storage = FlutterSecureStorage();
    String userName = await storage.read(key: "name") as String;
    return userName;
  }

  Future<String> getToken() async {
    const storage = FlutterSecureStorage();
    String token = await storage.read(key: "token") as String;
    return token;
  }

  Future<String> getPassword() async {
    const storage = FlutterSecureStorage();
    String password = await storage.read(key: "password") as String;
    return password;
  }

}

