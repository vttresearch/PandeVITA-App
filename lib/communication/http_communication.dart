/** This file contains the logic necessary to communicate with the platform
 * Julius Hekkala VTT 2022
 */

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as client;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/retry.dart';
import 'package:synchronized/synchronized.dart';
import '../Utility/user.dart';
import '../game_logic/game_status.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';


/**Singleton class that communicates with the platform server*/
class PandeVITAHttpClient {
  static final PandeVITAHttpClient _pandeVITAHttpClient =
  PandeVITAHttpClient._privateConstructor();
  final storage = const FlutterSecureStorage();
  final userStorage = UserStorage();
  final String _url = "https://pandevita.lst.tfo.upm.es"; // prod
  //final String _url = "https://gateway.pandevita.d.lst.tfo.upm.es";
  final String _urlWithoutHttps = "pandevita.lst.tfo.upm.es"; // prod
  //final String _urlWithoutHttps = "gateway.pandevita.d.lst.tfo.upm.es";

  final controller = Get.find<RequirementStateController>();

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
        //if wrong credentials
      } if (response.statusCode == 401) {
        controller.credentialsExpired();
        return null;
      }
      else {
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
          var maskArray = decodedResponse;
          debugPrint("maskArray $maskArray");
          return maskArray;
        }
      } catch (error) {
        debugPrint("Error in getmaskpoints " + error.toString());
        // await storage.delete(key: 'access_token');
      }
    }
    return [];
  }

  //Update the amount of masks taken
  Future<void> maskTaken(String maskId) async {
    debugPrint("MASK: maskTaken in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return;
    }
    var maskUrl = Uri.parse(_url + "/masks/" + maskId);
    var response = await client.get(maskUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    int amountTaken = decodedResponse["amountTaken"];
    int newAmount = amountTaken + 1;
    var maskData = {"amountTaken": newAmount};
    var body = json.encode(maskData);
    var response2 = await client.patch(maskUrl, body: body, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json'
    });
  }

  //Update the amount of vaccinations taken
  Future<void> vaccinationTaken(String vaccinationId) async {
    debugPrint("vaccination_taken in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return;
    }
    var vaccinationUrl = Uri.parse(_url + "/vaccination-locations/" + vaccinationId);
    var response = await client.get(vaccinationUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    int amountTaken = decodedResponse["amountTaken"];
    int newAmount = amountTaken + 1;
    var vaccinationData = {"amountTaken": newAmount};
    var body = json.encode(vaccinationData);
    var response2 = await client.patch(vaccinationUrl, body: body, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json'
    });
  }

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
          var vaccinationArray = decodedResponse;
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


  Future<int> registerUser(String userName, String password, String email,
      String? roleSelection, String countrySelection) async {
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

      String selectedCountry = "ES";

      switch (countrySelection) {
        case "Netherlands":
          selectedCountry = "NL";
          break;
        case "Germany":
          selectedCountry = "DE";
          break;
        case "Finland":
          selectedCountry = "FI";
          break;
        case "Turkey":
          selectedCountry = "TR";
          break;
      }

      var registrationData = {
        'username': userName,
        'enabled': 'true',
        'email': email,
        'attributes': {
          'country': selectedCountry
        },
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
      User(userId: userId, name: userName, password: password);
      userStorage.saveUser(user);
      return 0;
    } catch (error) {
      debugPrint("registerUser error $error");
      return 3;
    }
  }

  /**
   * Try logging in to the service. Returns true if successful, false if not.
   */
  Future<bool> tryLogin(String userName, String password) async {
    try {
      var registerUrl = Uri.parse(_url + "/users");
      //Check first that the username is real
      var checkUserNameAvailabilityUrl =
      Uri.parse(_url + "/users?username=" + userName.toLowerCase());
      var response = await client.get(checkUserNameAvailabilityUrl);
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      if (decodedResponse["userExists"] == false) {
        debugPrint("error logging in: username does not exist");
        return false;
      }

      //"Log in" by getting the access token
      String? accessToken;
      var currentTimeStamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      var authUrl = Uri.parse(_url + "/auth");
      try {
        var response = await client.post(authUrl, body: {
          'client_id': 'pandevita-dev',
          'grant_type': 'password',
          'username': userName,
          'password': password
        }, headers: {
          'accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded'
        });
        debugPrint('auth Response status: ${response.statusCode}');
        //debugPrint('auth Response body: ${response.body}');
        if (response.statusCode == 200) {
          var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
          accessToken = decodedResponse['access_token'];
          int expires_in = decodedResponse['expires_in'];
          int accessTimeStamp = currentTimeStamp + expires_in * 1000;
          await storage.write(key: 'access_token', value: accessToken);
          await storage.write(key: 'expires', value: accessTimeStamp.toString());
        } else {
          return false;
        }
      } catch (error) {
        return false;
      }
      if (accessToken == null) {
        return false;
      }

      var jwtTokenParts = accessToken.split(".");
      if (jwtTokenParts.length !=3) {
        debugPrint("Invalid access token");
        return false;
      }
      var accessTokenData = jwtTokenParts[1];
      //JWT access token decoding
      String normalizedSource = base64Url.normalize(accessTokenData);
      String jsonToken = utf8.decode(base64Url.decode(normalizedSource));
      Map token = jsonDecode(jsonToken);
      String userId = token["sub"];

      User user = User(userId: userId, name: userName, password: password);
      userStorage.saveUser(user);
      //Get the player data from the server
      Map? playerData = await getPlayer();
      //If unable to retrieve player data
      if (playerData == null) {
        userStorage.deleteUser();
        return false;
      }
      //If the user has registered for the dashboard
      //and starts the application the first time
      if (playerData.containsKey("error")) {
        if (playerData['error'] == 404) {
          createPlayer(userName);
          playerData = {
            'playerName': userName,
            'score': 0,
            'recentContacts': 0,
            'status': 0,
            'collected_masks': [],
            'collected_vaccines': [],
            'ansewredQuizzes': {}
          };
        }
      }
      //Save player data
      GameStatus gameStatus = GameStatus();
      int score = playerData["score"];
      gameStatus.modifyPoints(score);

      List teams = await getTeams();
      debugPrint("gothere");
      if (teams != []) {
        for (var team in teams) {
          var teamName = team["teamName"];
          var teamId = team["id"];
          int index = 0;
          for (var player in team["teamPlayers"]) {
            debugPrint("test $player");
            if (player == userName && index == 0) {
              userStorage.createTeam(teamName, teamId);
              break;
            } else if (player == userName && index != 0) {
              userStorage.joinTeam(teamName, teamId);
              break;
            }
            index++;
          }
        }
      }
      return true;

    } catch (error) {
      debugPrint("tryLogin error $error");
      return false;
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
      'status': 0,
      'collected_masks': [],
      'collected_vaccines': [],
      'ansewredQuizzes': {}
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

  //Future<Map> getAnsweredQuizzes() async {
  //  Map? playerData = await getPlayer();
  //  return playerData!['ansewredQuizzes'];
  //}

  //Update player stats on the server
  Future<int> updatePlayer({int? score, int? recentContacts, int? status, String? collectedMaskId, String? collectedVaccineId, bool collectedMask = false, bool collectedVaccination = false, String? answeredQuestion}) async {
    debugPrint("updatePlayer in http_comm");
    //First get the most current data on the server
    Map? playerData = await getPlayer();
    if (playerData == null) {
      return 5;
    }
    //Update the data
    if (score != null) {
      playerData['score'] = score;
    }

    if (recentContacts != null) {
      playerData['recentContacts'] = recentContacts;
    }
    if (status != null) {
      playerData['status'] = status;
    }
    /*Not used currently
    if (collectedMaskId != null) {
      List collectedMaskArray = playerData['collected_masks'];
     /* collectedMaskArray.add(collectedMaskId);
      playerData['collected_masks'] = collectedMaskArray;*/
      int collectedAmount = int.parse(collectedMaskArray[0]) + 1;
      List collectedList = [collectedAmount.toString()];
      playerData["collected_masks"] = collectedList;
    }*/
    if (collectedMask == true) {
      List collectedMaskArray = playerData['collected_masks'];
      int collectedAmount = 1;
      if (collectedMaskArray.isNotEmpty) {
        collectedAmount = int.parse(collectedMaskArray[0]) + 1;
      }
      List collectedList = [collectedAmount.toString()];
      playerData["collected_masks"] = collectedList;
    }
    /*Not used currently
    if (collectedVaccineId != null) {
      List collectedVaccineArray = playerData['collected_vaccines'];
     /* collectedVaccineArray.add(collectedVaccineId);
      playerData['collected_vaccines'] = collectedVaccineArray;*/
      int collectedAmount = int.parse(collectedVaccineArray[0]) + 1;
      List collectedList = [collectedAmount.toString()];
      playerData["collected_vaccines"] = collectedList;

    }*/
    if (collectedVaccination == true) {
      List collectedVaccineArray = playerData['collected_vaccines'];
      int collectedAmount = 1;
      if (collectedVaccineArray.isNotEmpty) {
        collectedAmount = int.parse(collectedVaccineArray[0]) + 1;
      }
      List collectedList = [collectedAmount.toString()];
      playerData["collected_vaccines"] = collectedList;
    }

    //If the user has answered a quiz question, add quiz question id
    //to the array
    if (answeredQuestion != null) {
      Map answeredQuizzesMap = playerData['ansewredQuizzes'];
      DateTime date = DateTime.now();
      var dateString = "${date.year}-${date.month}-${date.day}";
      debugPrint("date is $dateString");
      if (answeredQuizzesMap.isNotEmpty) {
        List answeredQuizzesList = answeredQuizzesMap["quizIds"];
        answeredQuizzesList.add(answeredQuestion);
        answeredQuizzesMap["quizIds"] = answeredQuizzesList;

        List answeredQuizzesDates = answeredQuizzesMap["dates"];
        bool dateFound = false;
        for (var dateData in answeredQuizzesDates) {
          if (dateData["date"] == dateString) {
            dateFound = true;
            dateData["amount"] = dateData["amount"] + 1;
            break;
          }
        }
        if (dateFound == false) {
          answeredQuizzesDates.add({"date": dateString, "amount": 1});
        }
        answeredQuizzesMap["dates"] = answeredQuizzesDates;
      } else {
        answeredQuizzesMap = {"quizIds": [answeredQuestion], "dates": [{"date": dateString, "amount": 1}]};
      }
      playerData['ansewredQuizzes'] = answeredQuizzesMap;
    }


    //Updated player data
    debugPrint("updated playerData " + playerData.toString());

    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return 3;
    }
    var playerName = await userStorage.getUserName();
    debugPrint("playername is $playerName");
    var playerUrl = Uri.parse(_url + "/players/" + playerName);
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

  /**
   * Get the player data from the backend
   */
  Future<Map?> getPlayer() async {
    debugPrint("getPlayer() in http_communication");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return null;
    }
    var playerName = await userStorage.getUserName();
    debugPrint("playername is $playerName");
    var playerUrl = Uri.parse(_url + "/players/" + playerName);
    var response = await client.get(playerUrl, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken'
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedResponse;
    } else if (response.statusCode == 404) {
      return {'error': 404};
    }
    else {
      return null;
    }
  }

  Future<int> postPointLossEvent() async {
    return 0;
  }

  /**
   * Get the quiz questions from the server
   */
  Future<List?> getQuizHistory() async {
    var accessToken = await lock.synchronized(getAuthorizationToken);
    var userId = await userStorage.getUserId();
    if (accessToken == null) {
      return null;
    }
    try {
      var player = await getPlayer();
      Map answeredQuizzesMap = player!["ansewredQuizzes"];
      if(answeredQuizzesMap.isEmpty){
        return [];
      }
      List answeredQuizIds = [];
      List answeredMap = [];
      if (answeredQuizzesMap.isNotEmpty) {
        answeredQuizIds = answeredQuizzesMap["quizIds"];
      }
      var quizUrl = Uri.parse(_url + "/quizzes");
      var response = await client.get(quizUrl, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        List quizQuestionsToReturn = decodedResponse.toList();
        for (var quizQuestion in quizQuestionsToReturn) {
          if (answeredQuizIds.contains(quizQuestion["id"])){
            bool isCorrectAnswer = quizQuestion['correctUsers'].contains(userId);
            answeredMap.add({'id': quizQuestion['id'],
                             'answer': '',
                             'correctAnswer': quizQuestion['correctAnswer'],
                             'isCorrect': isCorrectAnswer,
                             'question': quizQuestion['question'],
                             'answers': quizQuestion['answers'],
            });
          }
        }
        return answeredMap;
      }
      else{
        return [];
        }
      }
    catch (e) {
      return [];
    }
  }


  /**
   * Get the quiz questions from the server
   */
  Future<List?> getQuiz() async {
    debugPrint("getQuiz() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return null;
    }
    try {
      int amountOfQuestionsToGive = 3;
      //Get already answered quiz questions and the user can answer 3 questions per day
      DateTime dateToday = DateTime.now();
      var dateTodayString = "${dateToday.year}-${dateToday.month}-${dateToday.day}";
      debugPrint("date is $dateTodayString");
      var player = await getPlayer();
      Map answeredQuizzesMap = player!["ansewredQuizzes"];
      List answeredQuizIds = [];
      List dates = [];
      if (answeredQuizzesMap.isNotEmpty) {
        answeredQuizIds = answeredQuizzesMap["quizIds"];
        dates = answeredQuizzesMap["dates"];
      }
      int alreadyAnsweredTodayAmount = 0;
      for (var date in dates) {
        var day = date["date"];
        if (day == dateTodayString) {
          alreadyAnsweredTodayAmount = date["amount"];
        }
      }
      amountOfQuestionsToGive =
          amountOfQuestionsToGive - alreadyAnsweredTodayAmount;
      var quizUrl = Uri.parse(_url + "/quizzes");
      var response = await client.get(quizUrl, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });
      debugPrint('Response body: + ${response.body}');
      debugPrint('Response code: + ${response.statusCode}');
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("quiz response decoded successfully");
        //Remove the answered questions, then return amountOfQuestionsToGive
        //amount of questions
        List quizQuestionsToReturn = decodedResponse.toList();
        debugPrint("quizquestions1 $quizQuestionsToReturn");
        for (var quizQuestion in quizQuestionsToReturn) {
          if (answeredQuizIds.contains(quizQuestion["id"])) {
            decodedResponse.remove(quizQuestion);
          }
        }
        debugPrint("quizquestions2 $quizQuestionsToReturn");
        debugPrint("decodedResponse now $decodedResponse");
        quizQuestionsToReturn = [];
        for (int i=0; i < amountOfQuestionsToGive; i++) {
          if (i < decodedResponse.length) {
            quizQuestionsToReturn.add(decodedResponse[i]);
          } else {
            break;
          }
        }
        debugPrint("quizquestions3 $quizQuestionsToReturn");
        return quizQuestionsToReturn;
      }
      if (response.statusCode == 404) {
        return null;
      }
    }
    catch (e) {
      return null;
    }
  }

  void updateQuizAnswer(String quizId, bool correctAnswer) async {
    updatePlayer(answeredQuestion: quizId);
    debugPrint("updating QuizAnswer");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return null;
    }
    var quizUrl = Uri.parse(_url + "/quizzes/" + quizId);
    var response = await client.get(quizUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    if (correctAnswer) {
      var correctUsers = decodedResponse['correctUsers'];
      correctUsers.add(await userStorage.getUserId());
      var quizAnswerData = {'correctUsers': correctUsers};
      var body = json.encode(quizAnswerData);
      var response2 = await client.patch(quizUrl, body: body, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-type': 'application/json'
      });
    } else {
      var wrongUsers = decodedResponse['wrongUsers'];
      wrongUsers.add(await userStorage.getUserId());
      var quizAnswerData = {'wrongUsers': wrongUsers};
      var body = json.encode(quizAnswerData);
      var response2 = await client.patch(quizUrl, body: body, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Content-type': 'application/json'
      });
    }
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
    //Remove watched stories
    List watchedStoryIds = [];
    var userId = await userStorage.getUserId();
    Map filter = {"where": {"id_user": userId, "tool": "app"}};
    var queryFilter = jsonEncode(filter);
    var watchedStoriesUrl = Uri.https(_urlWithoutHttps, '/article-views',
        {"filter": queryFilter});
    debugPrint("watchedStoriesUrl $watchedStoriesUrl");
    //First get the watched stories in the app
    var watchedStoriesResponse = await client.get(watchedStoriesUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${watchedStoriesResponse.body}');
    debugPrint('Response code: + ${watchedStoriesResponse.statusCode}');
    if (watchedStoriesResponse.statusCode == 200) {
      try {
        List watchedStoriesList = jsonDecode(
            utf8.decode(watchedStoriesResponse.bodyBytes));
        debugPrint("Article views response decoded successfully");
        for (Map watchedStory in watchedStoriesList) {
          watchedStoryIds.add(watchedStory["id"] as String);
        }
        for (var watchedStoryId in watchedStoryIds) {
          var watchedStoryUrl = Uri.parse(_url + "/article-views/" + watchedStoryId);
        //  debugPrint("deleting watched story $watchedStoryUrl");
          try {
            var response = await client.delete(
                watchedStoryUrl, headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            });
            debugPrint('Response body: + ${response.body}');
            debugPrint('Response code: + ${response.statusCode}');
          } catch (error) {
            debugPrint("error in removeWatchedStories(): $error");
          }
        }
      } catch (error) {
        debugPrint("error in removeUser(): $error");
        return 6;
      }
    }
    //Delete the user
    /*var usersUrl =
    Uri.parse(_url + "/users/" + userId);
    var deletionResponse = await client.delete(usersUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (deletionResponse.statusCode != 204) {
      return 1;
    }*/

    //Use the newer delete-user endpoint
    var deleteUserUrl = Uri.parse(_url + "/delete-user");
    var deletionResponse = await client.delete(deleteUserUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (deletionResponse.statusCode != 204) {
      return 1;
    }
    return 0;
  }

  /**
   * Get the list of articles from backend
   */
  Future<List?> getArticles({String? topic}) async {
    debugPrint("getArticles() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return null;
    }
    //Get only approved articles
    Map basicFilter = {"limit": 20, "where": {"status": "2"}};
    var queryFilter = jsonEncode(basicFilter);
    Map<String, dynamic> filter = {"filter": queryFilter};
    debugPrint("topic $topic");
    if (topic != null) {
      if (topic == "news") {
        filter = {"filter[limit]": "20", "filter[where][status]": "2", "filter[where][or][0][topic]": "3", "filter[where][or][1][topic]": "4", "filter[where][or][2][topic]": "7", "filter[where][or][3][topic]": "8"};
      } else if (topic == "mobility") {
        filter = {"filter[limit]": "20", "filter[where][status]": "2", "filter[where][or][0][topic]": "5"};
      } else if (topic == "info") {
        filter = {"filter[limit]": "20", "filter[where][status]": "2", "filter[where][or][0][topic]": "1", "filter[where][or][1][topic]": "2", "filter[where][or][2][topic]": "6"};
      }
    }
    debugPrint("filter is $filter");

    var articlesUrl = Uri.https(_urlWithoutHttps, '/articles', filter);
    debugPrint("getArticles articlesUrl $articlesUrl");
    var response = await client.get(articlesUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("Articles response decoded successfully");
        if (decodedResponse.isEmpty) {
          return null;
        }
        return decodedResponse;
      } catch (error) {
        debugPrint("error in getArticles(): $error");
        return null;
      }

    }
   return null;
  }

  Future<bool> checkNewStories(String topic) async {
    var accessToken = await lock.synchronized(getAuthorizationToken);
    var userId = await userStorage.getUserId();
    List watchedStoryIds = [];
    Map filter = {"where": {"id_user": userId, "tool": "app"}};
    var queryFilter = jsonEncode(filter);
    var watchedStoriesUrl = Uri.https(_urlWithoutHttps, '/article-views',
        {"filter": queryFilter});
    debugPrint("watchedStoriesUrl $watchedStoriesUrl");
    //First get the watched stories in the app
    var response = await client.get(watchedStoriesUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List watchedStoriesList = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("Article views response decoded successfully");
        for (Map watchedStory in watchedStoriesList) {
          watchedStoryIds.add(watchedStory["id_article"]);
        }
        //Check whether there are new articles
        var articles = await getArticles(topic: topic);
        if (articles == null) {
          return false;
        }
        int articleAmount = 0;
        var articlesReversed = articles.reversed.toList();
        var newArticlesAvailable = false;
        for (Map article in articlesReversed) {
          articleAmount += 1;
          var articleId = article["id"];
          if (articleAmount > 5) {
            break;
          }
          if (watchedStoryIds.contains(articleId)) {
            continue;
          } else {
            newArticlesAvailable = true;
            break;
          }
        }
        debugPrint("NEW ARTICLES AVAILABLE: $newArticlesAvailable");
        return newArticlesAvailable;


      } catch (error) {
        debugPrint("error in checkNewStories(): $error");
        return false;
      }
    }



    return false;
  }

  void storiesWatched(List watchedStoriesIds) async {
    var accessToken = await lock.synchronized(getAuthorizationToken);
    var articleViewsUrl = Uri.parse(_url + "/article-views");
    var userId = await userStorage.getUserId();
    //Check that the stories were not viewed before
    List alreadyWatchedStoryIds = [];
    Map filter = {"where": {"id_user": userId, "tool": "app"}};
    var queryFilter = jsonEncode(filter);
    var watchedStoriesUrl = Uri.https(_urlWithoutHttps, '/article-views',
        {"filter": queryFilter});
    debugPrint("watchedStoriesUrl $watchedStoriesUrl");

    var response = await client.get(watchedStoriesUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    debugPrint('Response body: + ${response.body}');
    debugPrint('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        List watchedStoriesList = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("Article views response decoded successfully");
        for (Map watchedStory in watchedStoriesList) {
          alreadyWatchedStoryIds.add(watchedStory["id_article"]);
        }
      } catch (error) {
        debugPrint("error in storiesWatched(): $error");
      }
    }

    //Do not spam the server with article views
   for (var storyId in alreadyWatchedStoryIds) {
     if (watchedStoriesIds.contains(storyId)) {
       watchedStoriesIds.remove(storyId);
     }
   }


    for (var watchedStoryId in watchedStoriesIds) {
      try {
        var watchData = {
          'id_article': watchedStoryId,
          'id_user': userId,
          'tool': 'app'
        };
        var body = json.encode(watchData);
        var response = await client.post(articleViewsUrl, body: body, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Content-type': 'application/json'
        });
      } catch (error) {
        debugPrint("error in storiesWatched(): $error");
      }
    }

  }

  //Sends a message to the backend to reset the password for the account
  //without authorization token
  void sendResetPassword(String email) async {
    var resetPasswordUrl = Uri.https(_urlWithoutHttps, '/reset-password',
        {"email": email});
    debugPrint("resetPasswordUrl $resetPasswordUrl");
    await client.post(resetPasswordUrl, headers: {
      'Accept': '*/*',
    });
    return;
  }

/**  Future<Map> getQuizHistory() async {
    debugPrint("getQuiz() in http_comm");
    var accessToken = await lock.synchronized(getAuthorizationToken);
    if (accessToken == null) {
      return null;
    }
    try {
      Map quizHistory = {};
      var player = await getPlayer();
      Map answeredQuizzesMap = player!["ansewredQuizzes"];
      quizHistory["answered"] = answeredQuizzesMap;
      List answeredQuizIds = [];
      List dates = [];
      if (answeredQuizzesMap.isNotEmpty) {
        answeredQuizIds = answeredQuizzesMap["quizIds"];
        dates = answeredQuizzesMap["dates"];
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
        debugPrint("quiz response decoded successfully");
        //Remove the non-answered questions
        List quizQuestionsToReturn = [];
        debugPrint("quizquestions1 $quizQuestionsToReturn");
        for (var quizQuestion in decodedResponse) {
          if (answeredQuizIds.contains(quizQuestion["id"])) {
            quizQuestionsToReturn.add(quizQuestion);
          }
        }
        debugPrint("quizquestions2 $quizQuestionsToReturn");
        debugPrint("decodedResponse now $decodedResponse");
        quizHistory["quizHistory"] = quizQuestionsToReturn;
        debugPrint("quizquestions3 $quizQuestionsToReturn");
        return quizHistory;
      }
      if (response.statusCode == 404) {
        return {};
      }
    }
    catch (e) {
      return {};
    }
  }*/

}
