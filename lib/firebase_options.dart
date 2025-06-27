import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMZkI9R6z51gnZHB7LTcusc1H-lbMF6WM',
    appId: '1:1063411423044:android:6e281dad57d3b315c6a911',
    messagingSenderId: '1063411423044',
    projectId: 'nutriscan-3efb4',
    storageBucket: 'nutriscan-3efb4.firebasestorage.app',
  );

  // Note: iOS configuration will need to be added when you set up iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY', // Replace when adding iOS support
    appId: 'YOUR-IOS-APP-ID', // Replace when adding iOS support
    messagingSenderId: '1063411423044', // Same as Android
    projectId: 'nutriscan-3efb4', // Same as Android
    storageBucket: 'nutriscan-3efb4.firebasestorage.app', // Same as Android
    iosClientId: 'YOUR-IOS-CLIENT-ID', // Replace when adding iOS support
    iosBundleId: 'com.example.scanner', // Same package name as Android
  );
} 