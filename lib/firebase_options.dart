// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyAmjiTje1aQyO-JEDwbcrZejqcWdXPm13w',
    appId: '1:5955824795:web:cb87dfe6be6486114caa3e',
    messagingSenderId: '5955824795',
    projectId: 'ultimate-ba724',
    authDomain: 'ultimate-ba724.firebaseapp.com',
    storageBucket: 'ultimate-ba724.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX4wCvNP9phScVkiR4P7bSD8IpdTvPdRg',
    appId: '1:5955824795:android:b6dd7d888562ce3e4caa3e',
    messagingSenderId: '5955824795',
    projectId: 'ultimate-ba724',
    storageBucket: 'ultimate-ba724.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwG2wIwoIHYnc9kanwJI3v3t7K0x_gpZc',
    appId: '1:5955824795:ios:346e4991d6a6ccad4caa3e',
    messagingSenderId: '5955824795',
    projectId: 'ultimate-ba724',
    storageBucket: 'ultimate-ba724.appspot.com',
    iosBundleId: 'com.example.ultimatesolutions',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwG2wIwoIHYnc9kanwJI3v3t7K0x_gpZc',
    appId: '1:5955824795:ios:bdd9a9f06dd2f1934caa3e',
    messagingSenderId: '5955824795',
    projectId: 'ultimate-ba724',
    storageBucket: 'ultimate-ba724.appspot.com',
    iosBundleId: 'com.example.ultimatesolutions.RunnerTests',
  );
}