/**Settings page for handling account and teams
 * for the PandeVITA application
 */

import 'package:flutter/material.dart';
import 'package:pandevita_game/Utility/user.dart';
import 'package:pandevita_game/communication/http_communication.dart';
import '../Utility/styles.dart';

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
  String joinTeamName = "";
  List<String> teamMembers = [];


  String playerName = "";

  //Map of teams - name --> teamId
  Map<String, String> teamsMap = {};
  List<String> teamsList = [];
  String dropDownTeam = "";

  String dropdownValue = "Choose team";
  //
  bool isNotMemberOfTeam = true;
  bool isFounderOfTeam = false;

  bool isBluetoothEnabled = false;
  bool isLocationEnabled = false;

  void toggleBluetooth() {
    //TODO
  }

  void toggleLocation() {
    //TODO
  }

  //Update the page
  void updatePage() {
    setState(() {});
  }

  @override
  void initState() {
    initializeSettings();
    super.initState();
  }

  void initializeSettings() async {
    playerName = await storage.getUserName();
    var teamName = await storage.getTeam();
    if (teamName != null) {
      currentTeamName = teamName;
      isNotMemberOfTeam = false;
      if (await storage.isTeamFounder(teamName)) {
        isFounderOfTeam = true;
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
    } else {
      var teamId = await storage.getTeamId();
      var playersTeam = await client.getTeam(teamId!);
      if (playersTeam != {}) {
        teamMembers = playersTeam['teamPlayers'];
      }
    }
    dropdownValue = teamsList[0];
    print("teamsList $teamsList");
    updatePage();
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
            storage.deleteTeam();
            currentTeamName = "";
            var snackBar = const SnackBar(
              content: Text("Successfully deleted the team"),
              duration: Duration(seconds: 5),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            isNotMemberOfTeam = true;
            isFounderOfTeam = false;
            updatePage();
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
        currentTeamName = joinTeamName;
        storage.joinTeam(currentTeamName, teamsMap[joinTeamName]!);
        isNotMemberOfTeam = false;
        updatePage();
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
          currentTeamName = joinTeamName;
          updatePage();
        }
      }
    }

    doDeleteAccount() async {
      //TODO
      int success = await client.removeUser();
      return;
    }

    var deleteTeamRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Delete your team"),
        IconButton(
          icon: const Icon(Icons.remove),
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

    return Scaffold(
        backgroundColor: backgroundBlue,
        body: Container(
            padding: const EdgeInsets.all(40.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 215),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Name    "),
                  Text(playerName),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Team    "),
                  isNotMemberOfTeam == true
                      ? const Text("")
                      : Text(currentTeamName),
                ],
              ),
              const SizedBox(height: 20),
              if (isFounderOfTeam == true) deleteTeamRow,
              if (isNotMemberOfTeam == true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Create team"),
                    IconButton(
                      icon: const Icon(Icons.add),
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
              isNotMemberOfTeam == false
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                      child: Text("Your team members: " + teamMembers.join(","))
                )])
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Choose a team to join "),
                        DropdownButton<String>(
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
                                  dropdownValue =  newValue;
                                } else {
                                  joinTeamName = "";
                                }

                              });

                            },
                          value: dropdownValue),

                        IconButton(
                            onPressed: () => showDialog<String>(
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
                                ),
                            icon: const Icon(Icons.group_add))
                      ],
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Delete account "),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Delete account'),
                        content: const Text(
                            'Do you really want to delete your account?'),
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
              SwitchListTile(
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
              )
            ])));
  }
}
