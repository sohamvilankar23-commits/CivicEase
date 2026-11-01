import 'dart:js' as js;

bool isGoogleMapsAvailable() {
  try {
    return js.context.hasProperty('google') &&
        js.context['google'] != null &&
        js.context['google'].hasProperty('maps') &&
        js.context['google']['maps'] != null &&
        js.context['google']['maps'].hasProperty('MapTypeId');
  } catch (e) {
    return false;
  }
}
