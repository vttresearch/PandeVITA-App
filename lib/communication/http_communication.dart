/** This file contains the logic necessary to communicate with the platform
    server*/

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

/**Singleton class that communicates with the platform server*/
class PandeVITAHttpClient {
  static final PandeVITAHttpClient _client = PandeVITAHttpClient._privateConstructor();
  final storage = new FlutterSecureStorage();
  final String _url = "https://gateway.pandevita.d.lst.tfo.upm.es";
 // final controller = Get.find<RequirementStateController>();

  factory PandeVITAHttpClient() {
    return _client;
  }

  PandeVITAHttpClient._privateConstructor();

  //Get authorization token from the server
  Future<String> getAuthorizationToken() async {
    String credentials = await loadCredentials();
    var credentialList = credentials.split(",");
    var authUrl = Uri.parse(_url + "/auth");
    var response = await http.post(authUrl, body: {
      'client_id': credentialList[0], 'grant_type': credentialList[1],
      'username': credentialList[2], 'password': credentialList[3]
    });
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      String accessToken = decodedResponse['access_token'];
      storage.write(key: 'access_token', value: accessToken);
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
    var accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      print("MASK: token was null");
      accessToken == await getAuthorizationToken();
      print("MASK TOKEN $accessToken");
    }
    var maskUrl = Uri.parse(_url + "/masks");
    var response = await http.get(maskUrl, headers: {
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
    var accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      print("token was null");
      accessToken == await getAuthorizationToken();
    }
    var vaccinationUrl = Uri.parse(_url + "/vaccination-locations");
    var response = await http.get(vaccinationUrl, headers: {
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
    var accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      print("token was null");
      accessToken == await getAuthorizationToken();
    }
    var virusUrl = Uri.parse(_url + "/viruses");
    var response = await http.get(virusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var virusArray = decodedResponse[0]["viruses"];
      print("VIRUSARRAY $virusArray");
      return virusArray;
    }
    return [];
  }

  Future<Map> getGameStatus() async {
    print("GETGAMESTATUS in http_comm");
    var accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      print("token was null");
      accessToken == await getAuthorizationToken();
    }
    var gameStatusUrl = Uri.parse(_url + "/game-status");
    var response = await http.get(gameStatusUrl, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });
    print('Response body: + ${response.body}');
    print('Response code: + ${response.statusCode}');
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var gameStatus = decodedResponse[0];
      print("GAMESTATUS $gameStatus");
      return gameStatus;
    }
    return {};
  }

  //TODO: updatePlayerPoints, updateScoreboardPlayer, createTeam, etc.
}