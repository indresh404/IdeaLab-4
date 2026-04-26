import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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


  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcEc9I9ghGn2Nh1LJxDRWgf49xTNifr7g',
    authDomain: 'crisisclarity.firebaseapp.com',
    projectId: 'crisisclarity',
    storageBucket: 'crisisclarity.firebasestorage.app',
    messagingSenderId: '836424596718',
    appId: '1:836424596718:web:2cf94c531191713d85c7ff',
    measurementId: 'G-TZLHWVSY9X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtAy4vEc0QX_y94LutAbuYB8mgTLdagFU',
    appId: '1:836424596718:android:97bbb56fed7b9a6485c7ff',
    messagingSenderId: '836424596718',
    projectId: 'crisisclarity',
    storageBucket: 'crisisclarity.firebasestorage.app',
  );
}
