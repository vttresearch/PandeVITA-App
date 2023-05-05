import 'dart:async';
import 'dart:isolate';
import '../mixpanel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:pandevita_game/communication/beacon_broadcast.dart';
import 'package:pandevita_game/view/quiz_page.dart';
import 'package:pandevita_game/view/scoreboard_page.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

//import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../game_logic/game_logic.dart';
import 'map_page.dart';
import 'settings_page.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Utility/styles.dart';

void startCallback() {
  FlutterForegroundTask.setTaskHandler(NotifTaskHandler());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // late TutorialCoachMark tutorialCoachMark;
  // GlobalKey keyBottomNavigation1 = GlobalKey();

  late final Mixpanel mixpanel;
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<BluetoothState>? _streamBluetooth;
  int currentIndex = 0;
  final GameLogic gameLogic = GameLogic();
  final BeaconBroadcastClass beaconBroadcastClass = BeaconBroadcastClass();
  ReceivePort? _receivePort;
  final pages = ["Scoreboard", "Radar", "Quiz", "Settings"];

  BoxDecoration pandeVITABackgroundDecoration = backgroundDecoration;

  var infected = false;

  @override
  void initState() {
    super.initState();
    initMixpanel();
    // createTutorial();
    WidgetsBinding.instance.addObserver(this);
    checkPermissions();
    listeningState();
    controller.playerInfectedStream.listen((flag) {
      if (flag == true) {
        infected = true;
      } else if (flag == false) {
        infected = false;
      }
      setState(() {});
    });

    initForegroundTask();

    //gameLogic.initGame();
  }

  Future<void> initMixpanel() async {
    mixpanel = await Mixpanel.init(token, trackAutomaticEvents: true);
  }

  //Check the permissions - need permission for "always" for location
  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothScan,
      //These are possibly needed for newer Android versions
      Permission.bluetoothAdvertise
    ].request();
    //if (statuses[Permission.locationWhenInUse]!.isGranted) {
    //  var status = await Permission.locationAlways.request();
    //  if (!status.isGranted) {
    //    //SnackBar here
    //    var snackBar = const SnackBar(
    //      content: Text(
    //          "Location permission is needed for the app to function correctly"),
    //      duration: Duration(seconds: 5),
    //    );
    //    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    //  }
    //}
  }

  /// Create a tutorial when the user opens the application for the first time
  /* void createTutorial() async {
    tutorialCoachMark = TutorialCoachMark(
      targets: createTutorialTargets(),
      colorShadow: Colors.lightBlueAccent,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
            "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
      onSkip: () {
        print("skip");
      },
    );
  }

  List<TargetFocus> createTutorialTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "keyBottomNavigation1",
        keyTarget: keyBottomNavigation1,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Lorem ipsum",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    return targets;
  }*/

  listeningState() async {
    debugPrint('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon.bluetoothStateChanged().listen((BluetoothState state) async {
      controller.updateBluetoothState(state);
      await checkAllRequirements();
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);
    debugPrint('BLUETOOTH $bluetoothState');

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);
    debugPrint('AUTHORIZATION $authorizationStatus');

    final locationServiceEnabled = await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
    debugPrint('LOCATION SERVICE $locationServiceEnabled');

    if (controller.bluetoothEnabled && controller.authorizationStatusOk && controller.locationServiceEnabled) {
      debugPrint('STATE READY');
      debugPrint('INITIATING SCANNING');
      controller.startScanning();
      debugPrint("INITIATING BROADCAST");
      controller.startBroadcasting();
      debugPrint('INITIATING GAME');
      await gameLogic.initGame();
    } else {
      debugPrint('STATE NOT READY');
      controller.pauseScanning();
      controller.stopBroadcasting();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null) {
        if (_streamBluetooth!.isPaused) {
          _streamBluetooth?.resume();
        }
      }
      await checkAllRequirements();
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
      // beaconBroadcastClass.stopBroadcastBeacon();
    } else if (state == AppLifecycleState.detached) {
      _streamBluetooth?.cancel();
      _receivePort?.close();
    }
  }

  @override
  void dispose() {
    debugPrint("dispose called");
    _streamBluetooth?.cancel();
    stopForegroundTask();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        isSticky: false,
        iconData: const NotificationIconData(
          resType: ResourceType.drawable,
          resPrefix: ResourcePrefix.img,
          name: 'pandevita_logo_small',
        ),
        buttons: [
          const NotificationButton(id: 'stopButton', text: 'Stop foreground task'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
      printDevLog: true,
    );
    startForegroundTask();
  }

  Future<bool> stopForegroundTask() async {
    debugPrint("stoppingForegroundTask");
    return await FlutterForegroundTask.stopService();
  }

  Future<bool> startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        // if (message is String) {
        //   debugPrint('receive message: $message');
        //  if (message == "closeBroadcast") {
        //   controller.stopBroadcasting();
        // }
        // }
      });

      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
        child: Scaffold(
      appBar: AppBar(
        title: Image.asset("images/white_logo.png", height: AppBar().preferredSize.height - 5.0),
        centerTitle: false,
      ),
      backgroundColor: backgroundBlue,
      body: Container(
          decoration: pandeVITABackgroundDecoration,
          child: IndexedStack(
            index: currentIndex,
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: ScoreboardPage(),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: TabMap(),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: QuizPage(),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: SettingsPage(),
              )
            ],
          )),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 36, 128, 198),
        currentIndex: currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        onTap: (index) {
          mixpanel.track("Clicked ${pages[index]}");
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
              //backgroundColor: const Color.fromARGB(255, 36, 128, 198),
              icon: Image.asset('images/league_icon.png', width: 25),
              label: 'Scoreboard'),
          BottomNavigationBarItem(
            //backgroundColor: const Color.fromARGB(255, 36, 128, 198),
            icon: Image.asset('images/map_icon.png', width: 25),
            label: 'Radar',
          ),
          BottomNavigationBarItem(
            //backgroundColor: const Color.fromARGB(255, 36, 128, 198),
            icon: Image.asset('images/quiz_icon.png', width: 25),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            // backgroundColor: const Color.fromARGB(255, 36, 128, 198),
            icon: Image.asset('images/settings_icon.png', width: 25),
            label: 'Settings',
          )
        ],
      ),
    ));
  }
}

class NotifTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // You can use the getData function to get the data you saved.
    final customData = await FlutterForegroundTask.getData<String>(key: 'customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    if (id == "stopButton") {
      //port?.send("closeBroadcast");
      FlutterForegroundTask.stopService();
    }
  }
}
