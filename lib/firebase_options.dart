import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGp3Oj_TL_954i2CV1yMpYUr0ZxbZisC8',
    appId: '1:148354290567:web:6fd23cd638e6fab6f8b922',
    messagingSenderId: '148354290567',
    projectId: 'civicease1',
    authDomain: 'civicease1.firebaseapp.com',
    storageBucket: 'civicease1.firebasestorage.app',
    measurementId: 'G-9J83ZCF0XB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6g4kR_sqSlJKl1F7rfco9ZOWPre-YTpo',
    appId: '1:148354290567:android:3852ee06bcf3d151f8b922',
    messagingSenderId: '148354290567',
    projectId: 'civicease1',
    storageBucket: 'civicease1.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDGp3Oj_TL_954i2CV1yMpYUr0ZxbZisC8',
    appId: '1:148354290567:web:b5f4823a566f06fdf8b922',
    messagingSenderId: '148354290567',
    projectId: 'civicease1',
    authDomain: 'civicease1.firebaseapp.com',
    storageBucket: 'civicease1.firebasestorage.app',
    measurementId: 'G-Q0WHQBCTP1',
  );

}