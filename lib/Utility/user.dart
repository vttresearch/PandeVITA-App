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

  factory User.fromJson(Map<String, dynamic> responseData) {
    return User(
        userId: responseData['id'],
        name: responseData['username'],
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
    String userName = await storage.read(key: "username") as String;
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

  Future<int> joinTeam(String teamName, String teamId) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'team', value: teamName);
    await storage.write(key: 'teamId', value: teamId);
    return 0;
  }

  Future<String?> getTeam() async {
    const storage = FlutterSecureStorage();
    String? team = await storage.read(key: 'team');
    return team;
  }

  void createTeam(String teamName, String teamId) async{
    const storage = FlutterSecureStorage();
    await storage.write(key: 'team', value: teamName);
    await storage.write(key: 'teamFounder', value: teamName);
    await storage.write(key: 'teamId', value: teamId);
  }

  Future<int> deleteTeam() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'team');
    await storage.delete(key: 'teamFounder');
    await storage.delete(key: 'teamId');
    return 0;
  }

  Future<bool> isTeamFounder(String teamName) async {
    const storage = FlutterSecureStorage();
    String? foundedTeam = await storage.read(key: 'teamFounder');
    if (foundedTeam != null) {
      if (foundedTeam == teamName) {
        return true;
      }
    }
    return false;
  }

  Future<String?> getTeamId() async {
    const storage = FlutterSecureStorage();
    String? teamId = await storage.read(key: 'teamId');
    return teamId;
  }

}

