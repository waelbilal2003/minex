import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzWwuVRe9LujNzXcHxSZf0NcJAx5b2MLo',
    appId: '1:987403350920:android:71d37203ecf069b7ae403d',
    messagingSenderId: '987403350920',
    projectId: 'minex-notifications',
    storageBucket: 'minex-notifications.appspot.com',
  );
}
