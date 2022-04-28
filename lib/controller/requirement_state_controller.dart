import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';

class RequirementStateController extends GetxController {
  var bluetoothState = BluetoothState.stateOff.obs;
  var authorizationStatus = AuthorizationStatus.notDetermined.obs;
  var locationService = false.obs;

  var _startBroadcasting = false.obs;
  var _startScanning = false.obs;
  var _pauseScanning = false.obs;

  var _playerInfected = false.obs;
  var _playerPointsChanged = false.obs;
  var _immunityLevelChanged = false.obs;
  var _staticVirusNearby = false.obs;

  bool get bluetoothEnabled => bluetoothState.value == BluetoothState.stateOn;
  bool get authorizationStatusOk =>
      authorizationStatus.value == AuthorizationStatus.allowed ||
      authorizationStatus.value == AuthorizationStatus.always;
  bool get locationServiceEnabled => locationService.value;

  updateBluetoothState(BluetoothState state) {
    bluetoothState.value = state;
  }

  updateAuthorizationStatus(AuthorizationStatus status) {
    authorizationStatus.value = status;
  }

  updateLocationService(bool flag) {
    locationService.value = flag;
  }

  startBroadcasting() {
    _startBroadcasting.value = true;
  }

  stopBroadcasting() {
    _startBroadcasting.value = false;
  }

  startScanning() {
    _startScanning.value = true;
    _pauseScanning.value = false;
  }

  pauseScanning() {
    _startScanning.value = false;
    _pauseScanning.value = true;
  }

  playerInfected() {
    _playerInfected.value = true;
  }

  playerCured() {
    _playerInfected.value = false;
  }

  eventPlayerPointsChanged() {
    _playerPointsChanged.value = !_playerPointsChanged.value;
  }

  eventImmunityLevelChanged() {
    _immunityLevelChanged.value = !_immunityLevelChanged.value;
  }

  staticVirusNearby() {
    _staticVirusNearby.value = true;
  }

  staticVirusNearbyCleared() {
    _staticVirusNearby.value = false;
  }

  Stream<bool> get startBroadcastStream {
    return _startBroadcasting.stream;
  }

  Stream<bool> get startStream {
    return _startScanning.stream;
  }

  Stream<bool> get pauseStream {
    return _pauseScanning.stream;
  }

  Stream<bool> get playerInfectedStream {
    return _playerInfected.stream;
  }

  Stream<bool> get playerPointsChangedStream {
    return _playerPointsChanged.stream;
  }

  Stream<bool> get immunityLevelChangedStream {
    return _immunityLevelChanged.stream;
  }

  Stream<bool> get staticVirusNearbyStream {
    return _staticVirusNearby.stream;
  }

}
