import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:pandevita_game/communication/beacon_broadcast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pandevita_game/view/scoreboard_page.dart';
import '../controller/requirement_state_controller.dart';
import 'package:get/get.dart';
import '../game_logic/game_logic.dart';
import 'map_page.dart';
import 'action_page.dart';
import 'settings_page.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

void startCallback() {
  FlutterForegroundTask.setTaskHandler(NotifTaskHandler());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<BluetoothState>? _streamBluetooth;
  int currentIndex = 0;
  final GameLogic gameLogic = GameLogic();
  final BeaconBroadcastClass beaconBroadcastClass = BeaconBroadcastClass();
  ReceivePort? _receivePort;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();

    checkPermissions();
    listeningState();

    initForegroundTask();

    //gameLogic.initGame();
  }

  //Check the permissions - need permission for "always" for location
  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetooth,
    ].request();
    if (statuses[Permission.locationWhenInUse]!.isGranted) {
      var status = await Permission.locationAlways.request();
      if (!status.isGranted) {
        //Snackbar here
        var snackBar = const SnackBar(
          content: Text(
              "Location permission is needed for the app to function correctly"),
          duration: Duration(seconds: 5),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  listeningState() async {
    print('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      controller.updateBluetoothState(state);
      await checkAllRequirements();
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);
    print('BLUETOOTH $bluetoothState');

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);
    print('AUTHORIZATION $authorizationStatus');

    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
    print('LOCATION SERVICE $locationServiceEnabled');

    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      print('STATE READY');
      if (currentIndex == 0) {
        print('INITIATING GAME');
        //controller.startScanning();
        gameLogic.initGame();
        print("INITIATING BROADCAST");
        controller.startBroadcasting();
      } else {
        print('BROADCASTING');
        controller.startBroadcasting();
      }
    } else {
      print('STATE NOT READY');
      controller.pauseScanning();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null) {
        if (_streamBluetooth!.isPaused) {
          _streamBluetooth?.resume();
        }
      }
      await checkAllRequirements();
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
    }
  }

  @override
  void dispose() {
    _streamBluetooth?.cancel();
    _receivePort?.close();
    super.dispose();
  }

  Future<void> initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'stopButton', text: 'Stop app'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
    startForegroundTask();
  }

  Future<bool> stopForegroundTask() async {
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
        //if (message is DateTime) {
        //  print('receive timestamp: $message');
        //}
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
        title: const Text('PandeVITA app dev1.0'),
        centerTitle: false,
        /*actions: <Widget>[
          Obx(() {
            if (!controller.locationServiceEnabled)
              return IconButton(
                tooltip: 'Not Determined',
                icon: Icon(Icons.portable_wifi_off),
                color: Colors.grey,
                onPressed: () {},
              );

            if (!controller.authorizationStatusOk)
              return IconButton(
                tooltip: 'Not Authorized',
                icon: Icon(Icons.portable_wifi_off),
                color: Colors.red,
                onPressed: () async {
                  await flutterBeacon.requestAuthorization;
                },
              );

            return IconButton(
              tooltip: 'Authorized',
              icon: Icon(Icons.wifi_tethering),
              color: Colors.blue,
              onPressed: () async {
                await flutterBeacon.requestAuthorization;
              },
            );
          }),
          Obx(() {
            return IconButton(
              tooltip: controller.locationServiceEnabled
                  ? 'Location Service ON'
                  : 'Location Service OFF',
              icon: Icon(
                controller.locationServiceEnabled
                    ? Icons.location_on
                    : Icons.location_off,
              ),
              color:
                  controller.locationServiceEnabled ? Colors.blue : Colors.red,
              onPressed: controller.locationServiceEnabled
                  ? () {}
                  : handleOpenLocationSettings,
            );
          }),
          Obx(() {
            final state = controller.bluetoothState.value;

            if (state == BluetoothState.stateOn) {
              return IconButton(
                tooltip: 'Bluetooth ON',
                icon: Icon(Icons.bluetooth_connected),
                onPressed: () {},
                color: Colors.lightBlueAccent,
              );
            }

            if (state == BluetoothState.stateOff) {
              return IconButton(
                tooltip: 'Bluetooth OFF',
                icon: Icon(Icons.bluetooth),
                onPressed: handleOpenBluetooth,
                color: Colors.red,
              );
            }

            return IconButton(
              icon: Icon(Icons.bluetooth_disabled),
              tooltip: 'Bluetooth State Unknown',
              onPressed: () {},
              color: Colors.grey,
            );
          }),
        ],*/
      ),
      //TODO: TABS HERE
      body: IndexedStack(
        index: currentIndex,
        children: [
          ScoreboardPage(),
          TabMap(), //TODO: IMPLEMENTOI ERI VÄLILEHDET (PLACEHOLDERIT)
          TabAction(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (currentIndex == 0) {
            controller.startScanning();
          } else {
            controller.pauseScanning();
            controller.startBroadcasting();
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Image.asset('images/league_icon.png', width: 25),
              label: 'League'),
          BottomNavigationBarItem(
            icon: Image.asset('images/map_icon.png', width: 25),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('images/action_icon.png', width: 25),
            label: 'Action',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('images/settings_icon.png', width: 25),
            label: 'Settings',
          )
        ],
      ),
    ));
  }

/**handleOpenLocationSettings() async {
    if (Platform.isAndroid) {
    await flutterBeacon.openLocationSettings;
    } else if (Platform.isIOS) {
    await showDialog(
    context: context,
    builder: (context) {
    return AlertDialog(
    title: Text('Location Services Off'),
    content: Text(
    'Please enable Location Services on Settings > Privacy > Location Services.',
    ),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('OK'),
    ),
    ],
    );
    },
    );
    }
    }*/

/**handleOpenBluetooth() async {
    if (Platform.isAndroid) {
    try {
    await flutterBeacon.openBluetoothSettings;
    } on PlatformException catch (e) {
    print(e);
    }
    } else if (Platform.isIOS) {
    await showDialog(
    context: context,
    builder: (context) {
    return AlertDialog(
    title: Text('Bluetooth is Off'),
    content: Text('Please enable Bluetooth on Settings > Bluetooth.'),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('OK'),
    ),
    ],
    );
    },
    );
    }
    }*/
}

class NotifTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // You can use the getData function to get the data you saved.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    if (id == "stopButton") {
      FlutterForegroundTask.stopService();
    }
  }
}
