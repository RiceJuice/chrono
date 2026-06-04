// Werte aus android/app/google-services.json und ios/Runner/GoogleService-Info.plist
// (manuell aus Firebase Console; flutterfire configure optional).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Push ist nur für Android und iOS vorgesehen.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Push ist nur für Android und iOS vorgesehen.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYvK_XhCq2PqBbEqDegH447GayJHawsqk',
    appId: '1:304796088073:android:bb3df035d42db284dd05d8',
    messagingSenderId: '304796088073',
    projectId: 'chronoapp-e0ccf',
    storageBucket: 'chronoapp-e0ccf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZsNWr8iIMNmsXw_Hlh0w9IqqjBxZBHxA',
    appId: '1:304796088073:ios:5103a9d4e47014e4dd05d8',
    messagingSenderId: '304796088073',
    projectId: 'chronoapp-e0ccf',
    storageBucket: 'chronoapp-e0ccf.firebasestorage.app',
    iosBundleId: 'com.domspatzen.chronoapp',
  );
}
