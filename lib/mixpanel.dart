import 'package:mixpanel_flutter/mixpanel_flutter.dart';

String token = "";

class MixpanelManager {
  static Mixpanel? _instance;

  static Future<Mixpanel> init() async {
    _instance ??= await Mixpanel.init(token, optOutTrackingDefault: false, trackAutomaticEvents: true);
    return _instance!;
  }
}