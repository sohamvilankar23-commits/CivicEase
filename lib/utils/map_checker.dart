import 'map_checker_stub.dart' if (dart.library.js) 'map_checker_web.dart';

bool checkGoogleMapsLoaded() {
  return isGoogleMapsAvailable();
}
