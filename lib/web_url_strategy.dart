// This file is only used for web builds
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void configureUrl() {
  setUrlStrategy(PathUrlStrategy());
} 