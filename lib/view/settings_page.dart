/**Settings page for handling account and teams
 * for the PandeVITA application
 */
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../mixpanel.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pandevita_game/Utility/user.dart';
import 'package:pandevita_game/communication/http_communication.dart';
import 'package:pandevita_game/game_logic/game_logic.dart';
import '../Utility/styles.dart';
import 'package:get/get.dart';
import '../controller/requirement_state_controller.dart';
import '../game_logic/game_status.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  TextEditingController _textFieldController = TextEditingController();
  PandeVITAHttpClient client = PandeVITAHttpClient();
  UserStorage storage = UserStorage();
  late String newTeamName;
  late String currentTeamName;
  String? joinTeamName;
  List teamMembers = [];

  final controller = Get.find<RequirementStateController>();

  String playerName = "";

  //Map of teams - name --> teamId
  Map<String, String> teamsMap = {};
  List<String> teamsList = [];
  String dropDownTeam = "";

  String dropdownValue = "Choose team";

  String playerStatus = "Healthy";

  //
  bool isNotMemberOfTeam = true;
  bool isFounderOfTeam = false;

  bool isBluetoothEnabled = false;
  bool isLocationEnabled = false;

  //timestamp for controlling updates
  int settingsPageUpdated = 0;
  late final Mixpanel mixpanel;

  void toggleBluetooth() {}

  void toggleLocation() {
    //TODO
  }

  //Update the page
  void updatePage() {
    setState(() {});
  }

  Future<String> loadPrivacyPolicy() async {
    return await rootBundle.loadString('asset_files/privacy_policy.md');
  }

  @override
  void initState() {
    super.initState();
    initMixpanel();
    initializeSettings();
    controller.playerInfectedStream.listen((flag) {
      if (flag == true) {
        playerStatus = "Infected";
      } else if (flag == false) {
        playerStatus = "Healthy";
      }
      updatePage();
    });
    //If the users credentials have expired, force log out
    controller.credentialsExpiredStream.listen((flag) {
      doLogOut();
    });
  }
  Future<void> initMixpanel() async {
    mixpanel = await Mixpanel.init(token,trackAutomaticEvents: true );
  }

  void initializeSettings() async {
    teamsList.clear();
    playerName = await storage.getUserName();
    var teamName = await storage.getTeam();
    if (teamName != null) {
      currentTeamName = teamName;
      isNotMemberOfTeam = false;
      if (await storage.isTeamFounder(teamName)) {
        isFounderOfTeam = true;
      }
      //Check if team has been deleted by the team founder
      var teamId = await storage.getTeamId();
      Map team = await client.getTeam(teamId!);
      if (team.containsKey('notfound_error')) {
        currentTeamName = '';
        isNotMemberOfTeam = true;
        isFounderOfTeam = false;
        storage.deleteTeam();
      }
    }
    if (isNotMemberOfTeam) {
      var listOfTeams = await client.getTeams();
      for (var team in listOfTeams) {
        var teamName = team['teamName'];
        var teamId = team["id"];
        teamsMap[teamName] = teamId;
        teamsList.add(teamName);
      }
      if (teamsList.isNotEmpty) {
        dropdownValue = teamsList[0];
      }
    } else {
      var teamId = await storage.getTeamId();
      var playersTeam = await client.getTeam(teamId!);
      debugPrint("playersTeam $playersTeam");
      if (playersTeam.isNotEmpty) {
        debugPrint("playersTeam not empty");
        List teamPlayers = playersTeam['teamPlayers'];
        teamMembers.clear();
        for (var player in teamPlayers) {
          if (player != playerName) {
            teamMembers.add(player);
          }
        }

        debugPrint("teamMembers $teamMembers");
      }
    }
    debugPrint("teamsList $teamsList");
    settingsPageUpdated = DateTime.now().millisecondsSinceEpoch;
    updatePage();
  }

  ///Refreshes the settings page data if enough time has passed
  void refreshSettingsPage() async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    //Allow updating every 5 minutes
    if (timestamp - settingsPageUpdated > 300000) {
      initializeSettings();
    } else {
      var snackBar = SnackBar(
        content: Text("Settings page was updated recently."),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /*
    Logs the user out and removes local data.
     */
  void doLogOut() async {
    var snackBar = const SnackBar(
      content: Text("Logging out. The app will return to "
          "landing page shortly."),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    mixpanel.track("Logged out");
    //Clear local data
    GameStatus gameStatus = GameStatus();
    controller.stopBroadcasting();
    await gameStatus.deleteAllData();
    await storage.deleteUser();
    //Stop the game
    GameLogic gameLogic = GameLogic();
    gameLogic.stopGame();

    //Back to the landing screen
    Navigator.pushReplacementNamed(context, '/landing');

    return;
  }

  @override
  Widget build(BuildContext context) {
    /*final teamNameField = TextFormField(
        autofocus: false,
        onSaved: (value) => newTeamName = value as String,
        validator: (value) =>
        value!.isEmpty
            ? 'Please enter team name to create it'
            : null,
        decoration: const InputDecoration(
            icon: Icon(Icons.person), labelText: 'Create a team'));*/
    //initMixpanel();

    doCreateTeam() async {
      if (newTeamName == null || newTeamName == "") {
        var snackBar = const SnackBar(
          content: Text("Enter a team name to create a team"),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      //Save to the server
      List success = await client.createTeam(newTeamName);
      if (success[0] != 0) {
        var snackBar = const SnackBar(
          content: Text("Creating the team did not succeed"),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        mixpanel.track("Created a team");
        var snackBar = const SnackBar(
          content: Text("Successfully created a team"),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        //Save in local memory
        storage.createTeam(newTeamName, success[1]);
        currentTeamName = newTeamName;
        isFounderOfTeam = true;
        isNotMemberOfTeam = false;
        updatePage();
      }
    }

    doDeleteTeam() async {
      if (currentTeamName == null) {
        return;
      }
      bool isFounder = await storage.isTeamFounder(currentTeamName);
      if (isFounder) {
        var teamId = await storage.getTeamId();
        if (teamId != null) {
          //Remove team from server
          int success = await client.deleteTeam(teamId);
          if (success == 0 || success == 2) {
            //Remove team from local storage
            mixpanel.track("Deleted team");
            await storage.deleteTeam();
            currentTeamName = "";
            var snackBar = const SnackBar(
              content: Text("Successfully deleted the team"),
              duration: Duration(seconds: 5),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            isNotMemberOfTeam = true;
            isFounderOfTeam = false;
            initializeSettings();
          }
        }
        return;
      }
    }

    doJoinTeam() async {
      if (joinTeamName == null || joinTeamName == "") {
        return;
      }
      int success = await client.addToTeam(playerName, teamsMap[joinTeamName]!);
      if (success == 0) {
        mixpanel.track("Joined a team");
        currentTeamName = joinTeamName!;
        await storage.joinTeam(currentTeamName, teamsMap[joinTeamName]!);
        isNotMemberOfTeam = false;
        initializeSettings();
        var snackBar = const SnackBar(
          content: Text("Successfully joined a team"),
          duration: Duration(seconds: 5),
        );
      }
    }

    doLeaveTeam() async {
      debugPrint("leavingteam");
      if (currentTeamName == null) {
        return;
      }
      var teamId = await storage.getTeamId();
      int success = await client.removeFromTeam(playerName, teamId!);
      if (success == 0) {
        mixpanel.track("Left team");
        await storage.deleteTeam();
        currentTeamName = '';
        isNotMemberOfTeam = true;
        isFounderOfTeam = false;
        initializeSettings();
      }
    }

    doChangeTeam() async {
      if (currentTeamName == null || joinTeamName == null) {
        return;
      }
      int success =
      await client.removeFromTeam(playerName, teamsMap[currentTeamName]!);
      if (success == 0) {
        int success2 =
        await client.addToTeam(playerName, teamsMap[joinTeamName]!);
        if (success2 == 0) {
          currentTeamName = joinTeamName!;
          updatePage();
        }
      }
    }

    ///Deletes the user account on the server and application memory
    doDeleteAccount() async {
      //Delete the user account on the server side first
      int success = await client.removeUser();
      if (success != 0) {
        var snackBar = const SnackBar(
          content: Text("User deletion was unsuccessful."),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }

      var snackBar = const SnackBar(
        content: Text("User deletion was successful. The app will return to "
            "registration screen shortly."),
        duration: Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      mixpanel.track("Deleted account");
      //If serverside deletion successful, clear local data
      GameStatus gameStatus = GameStatus();
      controller.stopBroadcasting();
      await gameStatus.deleteAllData();
      await storage.deleteUser();
      //Stop the game
      GameLogic gameLogic = GameLogic();
      gameLogic.stopGame();
      //Back to the landing screen

      Navigator.pushReplacementNamed(context, '/landing');

      return;
    }

    var deleteTeamRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
            child: Text("Delete your team", style: settingsTextStyle),
            padding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)),
        ElevatedButton(
          child: Icon(Icons.remove, color: yellowColor, size: 35.0),
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            onPrimary: Colors.blue,
            shape: CircleBorder(),
            padding: EdgeInsets.all(0.0),
          ),
          onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Delete your team'),
              content: const Text("Are you sure you want to delete your team?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'Cancel');
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, 'Yes');
                    doDeleteTeam();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("Settings", style: settingsTextStyle),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  refreshSettingsPage();
                },
              ),
              Spacer(),
              Padding(
                  child: Text("Log out", style: settingsTextStyleAlt),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 10.0)),
              IconButton(
                icon: const Icon(Icons.logout_outlined, size: 30.0, color: Colors.white),
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(

                    title: const Text('Log out'),
                    content:
                    const Text('Do you really want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'Cancel');
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'Yes');
                          doLogOut();
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
              child: Container(
                  // padding: const EdgeInsets.all(20.0),
                  decoration: boxDecorationWhiteBorder,
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3.5),
                              1: FlexColumnWidth(6.5),
                            },
                            children: [
                              TableRow(
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 10.0),
                                        child: Text("Name", style: settingsTextStyle)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 16.0),
                                        child: Card(
                                            child: Container(
                                                child: Text(playerName,
                                                    style: settingsTextStyleName),
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 5.0, horizontal: 10.0))))
                                  ]),
                              TableRow(
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 10.0),
                                        child: Text("Your status",
                                            style: settingsTextStyle)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 16.0),
                                        child: Card(
                                            child: Container(
                                                child: Text(playerStatus,
                                                    style: settingsTextStyleName),
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 5.0,
                                                    horizontal: 10.0))))
                                  ]),
                              if (isNotMemberOfTeam == false)
                                TableRow(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 10.0),
                                          child: Text("Team", style: settingsTextStyle)),
                                          Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 10.0, horizontal: 16.0),
                                              child: Card(
                                                  child: Container(
                                                      child: Text(currentTeamName,
                                                          style: settingsTextStyleName),
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 5.0,
                                                          horizontal: 10.0))))
                                    ]),
                            ]),
                        if (isFounderOfTeam == true) deleteTeamRow,
                        if (isNotMemberOfTeam == true)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  child: Text("Create team",
                                      style: settingsTextStyleTeamAct),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0)),
                              ElevatedButton(
                                child:
                                Icon(Icons.add, color: yellowColor, size: 35.0),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.white,
                                  onPrimary: Colors.blue,
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(0.0),
                                ),
                                onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: const Text('Create a team'),
                                    content: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          newTeamName = value;
                                        });
                                      },
                                      controller: _textFieldController,
                                      decoration: const InputDecoration(
                                          hintText: "Insert team name"),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'Cancel');
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'OK');
                                          doCreateTeam();
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (isNotMemberOfTeam == false && isFounderOfTeam == false)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                  child:
                                  Text("Leave team", style: settingsTextStyle),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 10.0)),
                              ElevatedButton(
                                child: Icon(Icons.remove,
                                    size: 35.0, color: yellowColor),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.white,
                                  onPrimary: Colors.blue,
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(0.0),
                                ),
                                onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: const Text('Leave your team'),
                                    content: const Text(
                                        'Do you really want to leave your current team?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'Cancel');
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'OK');
                                          doLeaveTeam();
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        if (isNotMemberOfTeam == true)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                  child: Text("Choose a team to join ",
                                      style: settingsTextStyleTeamAct),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0)),
                              DropdownButton<String>(
                                  style: TextStyle(color: Colors.black),
                                  dropdownColor: Colors.white,
                                  items: teamsList.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      if (newValue != null) {
                                        joinTeamName = newValue;
                                      } else {
                                        joinTeamName = null;
                                      }
                                    });
                                  },
                                  value: joinTeamName),
                              if (joinTeamName != null)
                                ElevatedButton(
                                  onPressed: () => {
                                    if (joinTeamName != null)
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AlertDialog(
                                              title: const Text('Join a team'),
                                              content: Text(
                                                  'Do you really want to join the team called $joinTeamName?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context, 'Cancel');
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context, 'Yes');
                                                    if (joinTeamName != null &&
                                                        joinTeamName != "") {
                                                      doJoinTeam();
                                                    }
                                                  },
                                                  child: const Text('Yes'),
                                                ),
                                              ],
                                            ),
                                      )
                                  },
                                  child: Icon(Icons.group_add,
                                      color: yellowColor, size: 25.0),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                    onPrimary: Colors.blue,
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(5.0),
                                  ),
                                )
                            ],
                          ),
                        //Show the names of the team mates
                        if (!isNotMemberOfTeam)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                  child: Text("See teammates",
                                      style: settingsTextStyle),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0.0, horizontal: 10.0)),
                              ElevatedButton(
                                child: Icon(Icons.group,
                                    size: 25.0, color: yellowColor),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.white,
                                  onPrimary: Colors.blue,
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(5.0),
                                ),
                                onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    scrollable: true,
                                    title: const Text('Scroll to see more'),
                                    content: Container(
                                        height: 100,
                                        width: 200,
                                        child: ListView.builder(
                                          // padding: const EdgeInsets.all(16.0),
                                            itemCount: teamMembers.length,
                                            itemBuilder: (context, i) {
                                              var teamMember = teamMembers[i];
                                              return Center(
                                                  child: Text(teamMember,
                                                      style:
                                                      TextStyle(fontSize: 18)));
                                            })),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'Close');
                                        },
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Spacer(),
                        //Privacy policy
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                  text: TextSpan(
                                      text: "Read Privacy Policy",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.underline,
                                          fontSize: 17),
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
                                      }))
                            ]),
                        //Delete account row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                                child: Text("Delete account"),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 25.0),
                              onPressed: () => showDialog<String>(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Delete account'),
                                  content: const Text(
                                      'Do you really want to delete your account? This action cannot be reverted.'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, 'Cancel');
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, 'Yes');
                                        doDeleteAccount();
                                      },
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              //Icon(Icons.info_outline),
                              Padding(
                                  child: Icon(Icons.info_outline, color: Colors.white),
                                  padding: const EdgeInsets.only( bottom: 5.0, left: 10.0)
                              ),

                              Expanded(
                                child: Padding(
                                    child: Text(
                                        "To change the user data or the password, please visit the PandeVITA dashboard.",
                                        style: TextStyle(
                                            fontSize: 15.0, color: whiteColor)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0)),),
                            ]),
                        //Log out row

                        /*SwitchListTile(
            title: const Text('Bluetooth'),
            value: isBluetoothEnabled,
            onChanged: (bool value) {
              setState(() {
                isBluetoothEnabled = value;
                toggleBluetooth();
              });
            },
            secondary: const Icon(Icons.bluetooth),
          ),
          SwitchListTile(
            title: const Text('Location'),
            value: isLocationEnabled,
            onChanged: (bool value) {
              setState(() {
                isLocationEnabled = value;
                toggleLocation();
              });
            },
            secondary: const Icon(Icons.map),
          )*/
                      ])))
        ]);
  }
}
