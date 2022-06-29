/** This file contains the logic necessary to communicate with the platform
    server*/

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as client;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/retry.dart';
import 'package:synchronized/synchronized.dart';
import '../Utility/user.dart';


/**Singleton class that communicates with the platform server*/
class PandeVITAHttpClient {
  static final PandeVITAHttpClient _pandeVITAHttpClient =
  PandeVITAHttpClient._privateConstructor();
  final storage = const FlutterSecureStorage();
  final userStorage = UserStorage();
  final String _url = "https://gateway.pandevita.d.lst.tfo.upm.es";

  final lock = Lock();

  // final controller = Get.find<RequirementStateController>();

  //Maybe later
  // final client = RetryClient(http.Client());

  factory PandeVITAHttpClient() {
    return _pandeVITAHttpClient;
  }

  PandeVITAHttpClient._privateConstructor();

  //Get authorization token from the server
  Future<String?>  getAuthorizationToken() async {
    // String credentials = await loadCredentials();
    // var credentialList = credentials.split(",");
    var currentTimeStamp = DateTime
        .now()
        .millisecondsSinceEpoch;
    var accessToken = await storage.read(key: 'access_token');
    var accessTimeStamp = await storage.read(key: 'expires');
    if (accessToken != null && accessTimeStamp != null) {
      if ((currentTimeStamp - int.parse(accessTimeStamp)) < 0) {
        return accessToken;
      }
    }

    User? user = await userStorage.getUser();
    if (user == null) {
      return null;
    }
    debugPrint("username ${user.name}");
    debugPrint("password ${user.password}");
    debugPrint("getauthorizationtoken");
    var authUrl = Uri.parse(_url + "/auth");
    var authData =
        'client_id=pandevita-dev&grant_type=password&username=${user
        .name}&password=${user.password}';
    /*var authData = {
      'client_id': 'pandevita-dev',
      'grant_type': 'password',
      'username': user.name,
      'password': user.password
    };*/
    //var body = json.encode(authData);
    try {
      var response = await client.post(authUrl, body: {
        'client_id': 'pandevita-dev',
        'grant_type': 'password',
        'username': user.name,
        'password': user.password
      }, headers: {
        'accept': '*/*',
        'Content-Type': 'application/x-www-form-urlencoded'
      });
      debugPrint('auth Response status: ${response.statusCode}');
      //debugPrint('auth Response body: ${response.body}');
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String accessToken = decodedResponse['access_token'];
        int expires_in = decodedResponse['expires_in'];
        int accessTimeStamp = currentTimeStamp + expires_in * 1000;
        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'expires', value: accessTimeStamp.toString());
        return accessToken;
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  Future<String> loadCredentials() async {
    return await rootBundle.loadString('asset_files/test_credentials.txt');
  }

  //Get mask GPS points from the server
  Future<List> getMaskPoints() async {
    debugPrint("MASK: GETMASKPOINTS in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return [];
    }
    var maskUrl = Uri.parse(_url + "/masks");
    var response = await client.get(maskUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          debugPrint("maskarray not empty $decodedResponse");
          var maskArray = decodedResponse[0]["masks"];
          debugPrint("maskArray $maskArray");
          return maskArray;
        }
      } catch (error) {
        debugPrint("Error in getviruspoints " + error.toString());
        // await storage.delete(key: 'access_token');
      }
    }
    return [];
  }

  //TODO: FIX
  //Get vaccination GPS points from the server
  Future<List> getVaccinationPoints() async {
    debugPrint("GETVACCINATIONPOINTS in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return [];
    }
    var vaccinationUrl = Uri.parse(_url + "/vaccination-locations");
    var response = await client.get(vaccinationUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          debugPrint("vaccinationarray not empty $decodedResponse");
          var vaccinationArray = decodedResponse[0]["locations"];
          debugPrint("vaccinationArray $vaccinationArray");
          return vaccinationArray;
        }
      } catch (error) {
        debugPrint("Error in getvaccinationpoints " + error.toString());
        // await storage.delete(key: 'access_token');
      }
    }
    return [];
  }

  //Get virus points as GPS from server
  Future<List> getVirusPoints() async {
    debugPrint("GETVIRUSPOINTS in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return [];
    }
    var virusUrl = Uri.parse(_url + "/viruses");
    var response = await client.get(virusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          debugPrint("virusarray not empty $decodedResponse");
          var virusArray = decodedResponse[0]["viruses"][0];
          debugPrint("VIRUSARRAY $virusArray");
          return virusArray;
        }
      } catch (error) {
        debugPrint("Error in getviruspoints " + error.toString());
        // await storage.delete(key: 'access_token');
      }
    }
    return [];
  }

  //Returns gameStatus as string
  Future<Map> getGameStatus() async {
    debugPrint("GETGAMESTATUS in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return {};
    }
    debugPrint("ACCESSTOKEN IS $accessToken");
    var gameStatusUrl = Uri.parse(_url + "/game-status");
    var response = await client.get(gameStatusUrl, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          var gameStatus = decodedResponse[0];
          debugPrint("GAMESTATUS $gameStatus");
          return gameStatus;
        }
        debugPrint("gamestatus was empty");
      } catch (error) {
        debugPrint("Error in getGameStatus " + error.toString());
        await storage.delete(key: 'access_token');
      }
    }
    return {};
  }

  Future<Map> getScoreBoard() async {
    debugPrint("getScoreBoard() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return {};
    }
    var gameStatusUrl = Uri.parse(_url + "/scoreboards");
    var response = await client.get(gameStatusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        if (decodedResponse.isNotEmpty) {
          var scoreboard = decodedResponse[0];
          debugPrint("SCOREBOARD $scoreboard");
          return scoreboard;
        }
        debugPrint("scoreboard was empty");
      } catch (error) {
        debugPrint("Error in getScoreboard " + error.toString());
        await storage.delete(key: 'access_token');
      }
    }
    return {};
  }

  //TODO: handle user id
  Future<int> registerUser(String userName, String password, String email,
      String? roleSelection) async {
    try {
      var registerUrl = Uri.parse(_url + "/users");
      //Check first that the username is available
      var checkUserNameAvailabilityUrl =
      Uri.parse(_url + "/users?username=" + userName.toLowerCase());
      var response = await client.get(checkUserNameAvailabilityUrl);
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedResponse["userExists"] == true) {
        debugPrint("error registering user: username already exists");
        return 1;
      }
      String? selectedRole;

      switch (roleSelection) {
        case "Do not choose":
          break;
        case "Academy":
          selectedRole = "dashboard_academy";
          break;
        case "Industry":
          selectedRole = "dashboard_industry";
          break;
        case "Public authority":
          selectedRole = "dashboard_public_authority";
          break;
        case "Other":
          selectedRole = "dashboard_other";
          break;
      }

      var registrationData = {
        'username': userName,
        'enabled': 'true',
        'email': email,
        'credentials': [
          {'type': 'password', 'value': password, 'temporary': 'false'}
        ]
      };
      if (selectedRole != null) {
        registrationData['role'] = selectedRole;
        debugPrint(registrationData.toString());
      }
      var body = json.encode(registrationData);
      //If the username does not exist, register user
      var response2 = await client.post(registerUrl,
          body: body,
          headers: {'Accept': '*/*', 'Content-Type': 'application/json'});
      debugPrint('Response status: ${response2.statusCode}');
      debugPrint('Response body: ${response2.body}');
      var decodedResponse2 = jsonDecode(utf8.decode(response2.bodyBytes));
      if (decodedResponse2["created"] == false || response2.statusCode != 201) {
        debugPrint("error registering user: something went wrong");
        return 2;
      }


      //Everything went ok, save the user
      var userId = decodedResponse2['user_id'];
      User user =
      User(userId: userId, name: userName, email: email, password: password);
      userStorage.saveUser(user);
      return 0;
    } catch (error) {
      debugPrint("registerUser error $error");
      return 3;
    }
  }

  //Create a player on the server side
  Future<int> createPlayer(String playerName) async {
    debugPrint("createPlayer in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
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
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      return 0;
    } else {
      return 1;
    }
  }

  //Update player stats on the server
  Future<int> updatePlayer(int score, {int? recentContacts}) async {
    if (recentContacts == null) {
      debugPrint("updatePlayer in http_comm");
      var accessToken = await lock.synchronized(getAuthorizationToken);
      if (accessToken == null) {
        return 3;
      }
      var playerName = await userStorage.getUserName();
      debugPrint("playername is $playerName");
      var playerUrl = Uri.parse(_url + "/players/" + playerName);
      var playerData = {'playerName': playerName, 'score': score};
      var body = json.encode(playerData);
      var response = await client.patch(playerUrl, body: body, headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      });
      debugPrint('Response body: + ${response.body}');
      debugPrint('Response code: + ${response.statusCode}');
      if (response.statusCode == 204) {
        return 0;
      } else {
        return 1;
      }
    } else {
      debugPrint("updatePlayer in http_comm, recentcontacts $recentContacts");
      var accessToken = await lock.synchronized(getAuthorizationToken);
      if (accessToken == null) {
        return 3;
      }
      var playerName = await userStorage.getUserName();
      var playerUrl = Uri.parse(_url + "/players/" + playerName);
      var playerData = {'score': score, 'recentContacts': recentContacts};
      var body = json.encode(playerData);
      var response = await client.patch(playerUrl, body: body, headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      });
      debugPrint('Response body: + ${response.body}');
      debugPrint('Response code: + ${response.statusCode}');
      if (response.statusCode == 204) {
        return 0;
      } else {
        return 1;
      }
    }
  }

  //Update the scoreboard entry of the player
  Future<int> updateScoreboardPlayer(int score) async {
    //First get the scoreboard
    var scoreboard = await getScoreBoard();
    //No scoreboard yet, create it
    if (scoreboard.isEmpty) {
      var playerName = await userStorage.getUserName();
      Map initScoreboard = {
        'players': [
          {'playerName': playerName, 'score': score}
        ],
        'additionalProp1': {}
      };
      var body = json.encode(initScoreboard);
      var accessToken = await lock.synchronized(getAuthorizationToken);
      if (accessToken == null) {
        return 3;
      }
      var scoreboardsUrl = Uri.parse(_url + "/scoreboards");
      var response = await client.post(scoreboardsUrl, body: body, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-type': 'application/json'
      });
      if (response.statusCode == 200) {
        return 0;
      }
      return 1;
    }
    var scoreboardId = scoreboard['id'];
    List playerList = scoreboard['players'];
    var playerName = await userStorage.getUserName();
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
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
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
    debugPrint("createTeam in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
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
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var teamId = decodedResponse["id"];
      return [0, teamId];
    } else {
      return [1, ""];
    }
  }

  Future<List> getTeams() async {
    debugPrint("getTeams() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return [];
    }
    var teamsUrl = Uri.parse(_url + "/teams");
    var response = await client.get(teamsUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedResponse;
    }
    return [];
  }

  Future<Map> getTeam(String teamId) async {
    debugPrint("getTeam() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return {};
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var response = await client.get(teamUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint("players team response decoded succsefully");
      return decodedResponse;
    }
    if (response.statusCode == 404) {
      return {'notfound_error': 'notFound'};
    }
    return {};
  }

  Future<int> deleteTeam(String teamId) async {
    debugPrint("deleteTeam() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return 2;
    }
    var teamUrl = Uri.parse(_url + "/teams/" + teamId);
    var response = await client.delete(teamUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 204) {
      // var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return 0;
    } else if (response.statusCode == 404) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return 2;
    }
    return 1;
  }

  Future<int> addToTeam(String playerName, String teamId) async {
    //First get the team
    var team = await getTeam(teamId);
    var teamPlayers = team['teamPlayers'];
    var playerName = await userStorage.getUserName();
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
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
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
    var playerName = await userStorage.getUserName();
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
      return 0;
    }
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
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


  /**
   * Get a quiz from the server
   */
  Future<Map> getQuiz() async {
    debugPrint("getQuiz() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return {'error': 'authTokenError'};
    }
    var quizUrl = Uri.parse(_url + "/quizzes");
    var response = await client.get(quizUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint("quiz response decoded succsefully");
      return decodedResponse[0];
    }
    if (response.statusCode == 404) {
      return {'error': 'notFound'};
    }
    return {'error': 'other'};
  }

  ///Remove user data from the server. Irreversible. Returns 0, if deletion
  ///successful.
  Future<int> removeUser() async {
    //Delete player instance
    debugPrint("deleting player in removeUser in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return 3;
    }
    var playerName = await userStorage.getUserName();
    debugPrint("playername is $playerName");
    var playerUrl = Uri.parse(_url + "/players/" + playerName);
    var response = await client.delete(playerUrl, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode != 204 && response.statusCode != 404) {
      return 1;
    }
    //Delete scoreboard instance of player
    //First get the scoreboard
    var scoreboard = await getScoreBoard();
    //No scoreboard yet, create it
    if (scoreboard.isNotEmpty) {
      var scoreboardId = scoreboard['id'];
      List playerList = scoreboard['players'];
      var playerName = await userStorage.getUserName();
      for (Map entry in playerList) {
        if (entry["playerName"] == playerName) {
          playerList.remove(entry);
          break;
        }
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
      if (response.statusCode != 204) {
        return 2;
      }
    }
    //Remove user from team, if user is in one
    var teamId = await userStorage.getTeamId();
    if (teamId != null) {
      removeFromTeam(playerName, teamId);
    }
    //Delete the user
    var userId = await userStorage.getUserId();
    var usersUrl =
    Uri.parse(_url + "/users/" + userId);
    var deletionResponse = await client.delete(usersUrl, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (deletionResponse.statusCode != 204) {
      return 1;
    }
    return 0;
  }
}
