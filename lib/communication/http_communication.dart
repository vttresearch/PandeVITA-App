/** This file contains the logic necessary to communicate with the platform
    server*/

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as client;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/retry.dart';
import '../Utility/user.dart';

/**Singleton class that communicates with the platform server*/
class PandeVITAHttpClient {
  static final PandeVITAHttpClient _pandeVITAHttpClient =
      PandeVITAHttpClient._privateConstructor();
  final storage = const FlutterSecureStorage();
  final userStorage = UserStorage();
  final String _url = "https://gateway.pandevita.d.lst.tfo.upm.es";

  // final controller = Get.find<RequirementStateController>();

  //Maybe later
  // final client = RetryClient(http.Client());

  factory PandeVITAHttpClient() {
    return _pandeVITAHttpClient;
  }

  PandeVITAHttpClient._privateConstructor();

  //Get authorization token from the server
  Future<String> getAuthorizationToken() async {
    // String credentials = await loadCredentials();
    // var credentialList = credentials.split(",");
    var currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var accessToken = await storage.read(key: 'access_token');
    var accessTimeStamp = await storage.read(key: 'expires');
    if (accessToken != null && accessTimeStamp != null) {
      if ((currentTimeStamp - int.parse(accessTimeStamp)) < 0) {
        return accessToken;
      }
    }

    User? user = await userStorage.getUser();
    if (user == null) {
      return "error";
    }
    print("username ${user.name}");
    print("password ${user.password}");
    print("getauthorizationtoken");
    var authUrl = Uri.parse(_url + "/auth");
    var authData =
        'client_id=pandevita-dev&grant_type=password&username=${user.name}&password=${user.password}';
    /*var authData = {
      'client_id': 'pandevita-dev',
      'grant_type': 'password',
      'username': user.name,
      'password': user.password
    };*/
    //var body = json.encode(authData);
    var response = await client.post(authUrl,
        body: {
          'client_id': 'pandevita-dev',
          'grant_type': 'password',
          'username': user.name,
          'password': user.password
        },
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded'
        });
    print('auth Response status: ${response.statusCode}');
    //print('auth Response body: ${response.body}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      String accessToken = decodedResponse['access_token'];
      int expires_in = decodedResponse['expires_in'];
      int accessTimeStamp =
          currentTimeStamp + expires_in * 1000;
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'expires', value: accessTimeStamp.toString());
      return accessToken;
    } else {
      return "error";
    }
  }

  Future<String> loadCredentials() async {
    return await rootBundle.loadString('asset_files/test_credentials.txt');
  }

  //Get mask GPS points from the server
  Future<List> getMaskPoints() async {
    print("MASK: GETMASKPOINTS in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return [];
    }
    var maskUrl = Uri.parse(_url + "/masks");
    var response = await client.get(maskUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var maskPoints = decodedResponse[0]["masks"];
      print("MASKPOINTS $maskPoints");
      return maskPoints;
    }
    return [];
  }

  //Get vaccination GPS points from the server
  Future<List> getVaccinationPoints() async {
    print("GETVACCINATIONPOINTS in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return [];
    }
    var vaccinationUrl = Uri.parse(_url + "/vaccination-locations");
    var response = await client.get(vaccinationUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var vaccinationPoints = decodedResponse[0]["locations"];
      print("VACCINATIONPOINTS $vaccinationPoints");
      return vaccinationPoints;
    }
    return [];
  }

  //Get virus points as GPS from server
  Future<List> getVirusPoints() async {
    print("GETVIRUSPOINTS in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return [];
    }
    var virusUrl = Uri.parse(_url + "/viruses");
    var response = await client.get(virusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          print("virusarray not empty $decodedResponse");
          var virusArray = decodedResponse[0]["viruses"][0];
          print("VIRUSARRAY $virusArray");
          return virusArray;
        }
      } catch (error) {
        print("Error in getviruspoints " + error.toString());
       // await storage.delete(key: 'access_token');
      }
    }
    return [];
  }

  //Returns gameStatus as string
  Future<Map> getGameStatus() async {
    print("GETGAMESTATUS in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return {};
    }
    print("ACCESSTOKEN IS $accessToken");
    var gameStatusUrl = Uri.parse(_url + "/game-status");
    var response = await client.get(gameStatusUrl, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          var gameStatus = decodedResponse[0];
          print("GAMESTATUS $gameStatus");
          return gameStatus;
        }
        print("gamestatus was empty");
      } catch (error) {
        print("Error in getGameStatus " + error.toString());
        await storage.delete(key: 'access_token');
      }
    }
    return {};
  }

  Future<Map> getScoreBoard() async {
    print("getScoreBoard() in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return {};
    }
    var gameStatusUrl = Uri.parse(_url + "/scoreboards");
    var response = await client.get(gameStatusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedResponse != []) {
        return decodedResponse[0];
      }
    }
    return {};
  }

  Future<int> registerUser(
      String userName, String password, String email) async {
    var registerUrl = Uri.parse(_url + "/users");
    //Check first that the username is available
    var checkUserNameAvailabilityUrl =
        Uri.parse(_url + "/users?username=" + userName.toLowerCase());
    var response = await client.get(checkUserNameAvailabilityUrl);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    if (decodedResponse["userExists"] == true) {
      print("error registering user: username already exists");
      return 1;
    }
    var registrationData = {
      'username': userName,
      'enabled': 'true',
      'email': email,
      'credentials': [
        {'type': 'password', 'value': password, 'temporary': 'false'}
      ]
    };
    var body = json.encode(registrationData);
    //If the username does not exist, register user
    var response2 = await client.post(registerUrl,
        body: body,
        headers: {'Accept': '*/*', 'Content-Type': 'application/json'});
    print('Response status: ${response2.statusCode}');
    print('Response body: ${response2.body}');
    var decodedResponse2 = jsonDecode(utf8.decode(response2.bodyBytes));
    if (decodedResponse2["created"] == false || response2.statusCode != 200) {
      print("error registering user: something went wrong");
      return 2;
    }

    //Everything went ok, save the user
    var userId = decodedResponse2['user_id'];
    User user =
        User(userId: userId, name: userName, email: email, password: password);
    userStorage.saveUser(user);
    return 0;
  }

  //Create a player on the server side
  Future<int> createPlayer(String playerName) async {
    print("createPlayer in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 3;
    }
    var playerUrl = Uri.parse(_url + "/players");
    var playerData = {
      'playerName': playerName,
      'score': 0,
      'recentContacts': 0,
      'additionalProp1': {}
    };
    var body = json.encode(playerData);
    var response = await client.post(playerUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      return 0;
    } else {
      return 1;
    }
  }

  //Update player stats on the server
  Future<int> updatePlayer(int score, int recentContacts) async {
    print("updatePlayer in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 3;
    }
    var playerName = userStorage.getUserName() as String;
    var playerUrl = Uri.parse(_url + "/players/" + playerName);
    var playerData = {
      'playerName': playerName,
      'score': score,
      'recentContacts': recentContacts,
      'additionalProp1': {}
    };
    var body = json.encode(playerData);
    var response = await client.put(playerUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 204) {
      return 0;
    } else {
      return 1;
    }
  }

  //Update the scoreboard entry of the player
  Future<int> updateScoreboardPlayer(int score) async {
    //First get the scoreboard
    var scoreboard = await getScoreBoard();
    var scoreboardId = scoreboard['id'];
    List playerList = scoreboard['players'];
    var playerName = userStorage.getUserName();
    var playerFoundInScoreboard = false;
    for (Map entry in playerList) {
      if (entry["playerName"] == playerName) {
        entry["score"] = score;
        playerFoundInScoreboard = true;
        break;
      }
    }
    if (!playerFoundInScoreboard) {
      playerList.add({'playerName': playerName, 'score': score});
    }
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 3;
    }
    var scoreboardsUrl =
        Uri.parse(_url + "/scoreboards/" + scoreboardId.toString());
    var scoreBoardData = {'players': playerList};
    var body = json.encode(scoreBoardData);
    var response = await client.patch(scoreboardsUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    if (response.statusCode == 204) {
      return 0;
    }
    return 1;
  }

  Future<List> createTeam(String teamName) async {
    print("createTeam in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return [3, ""];
    }
    var playerName = await userStorage.getUserName();
    var teamsUrl = Uri.parse(_url + "/teams");
    var teamData = {
      'teamName': teamName,
      'teamPlayers': [playerName]
    };
    var body = json.encode(teamData);
    var response = await client.post(teamsUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var teamId = decodedResponse["id"];
      return [0, teamId];
    } else {
      return [1, ""];
    }
  }

  Future<List> getTeams() async {
    print("getTeams() in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return [];
    }
    var teamsUrl = Uri.parse(_url + "/teams");
    var response = await client.get(teamsUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedResponse;
    }
    return [];
  }

  Future<Map> getTeam(String teamId) async {
    print("getTeam() in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return {};
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var response = await client.get(teamUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedResponse;
    }
    return {};
  }

  Future<int> deleteTeam(String teamId) async {
    print("deleteTeam() in http_comm");
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 2;
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var response = await client.delete(teamUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 204) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return 0;
    }
    else if (response.statusCode == 404) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return 2;
    }
    return 1;
  }

  Future<int> addToTeam(String playerName, String teamId) async {
    //First get the team
    var team = await getTeam(teamId);
    var teamPlayers = team['teamPlayers'];
    var playerName = userStorage.getUserName() as String;
    var playerFoundInTeam = false;
    //Check that not already in team
    for (String player in teamPlayers) {
      if (player == playerName) {
        playerFoundInTeam = true;
        break;
      }
    }
    if (!playerFoundInTeam) {
      teamPlayers.add(playerName);
    }
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 3;
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var teamData = {'teamPlayers': teamPlayers};
    var body = json.encode(teamData);
    var response = await client.patch(teamUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    if (response.statusCode == 204) {
      return 0;
    }
    return 1;
  }

  Future<int> removeFromTeam(String playerName, String teamId) async {
    //First get the team
    var team = await getTeam(teamId);
    List teamPlayers = team['teamPlayers'];
    var playerName = userStorage.getUserName() as String;
    var playerFoundInTeam = false;
    //Check that player is in team
    for (String player in teamPlayers) {
      if (player == playerName) {
        playerFoundInTeam = true;
        break;
      }
    }
    if (playerFoundInTeam) {
      teamPlayers.remove(playerName);
    } else {
      return 2;
    }
    var accessToken = await getAuthorizationToken();
    if (accessToken == "error") {
      return 3;
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var teamData = {'teamPlayers': teamPlayers};
    var body = json.encode(teamData);
    var response = await client.patch(teamUrl, body: body, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-type': 'application/json'
    });
    if (response.statusCode == 204) {
      return 0;
    }
    return 1;
  }

  Future<Map> getPlayer() async {
    return {};
  }

  Future<int> postPointLossEvent() async {
    return 0;
  }

  Future<Map> getQuiz() async {
    return {};
  }

  Future<int> removeUser() async {
    return 0;
  }
}
