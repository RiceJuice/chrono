import 'package:flutter/foundation.dart';

/// Google OAuth Web-Client-ID (öffentlich).
const String kDefaultGoogleWebClientId =
    '304796088073-g9b092e5mamdtsd3gcjdjo8gt6ua09si.apps.googleusercontent.com';

/// Überschreiben: `--dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com`
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: kDefaultGoogleWebClientId,
);

/// Google OAuth iOS-Client-ID.
const String kDefaultGoogleIosClientId =
    '304796088073-4df2dpk5rfq1kavr7apgrb1f0pidthqc.apps.googleusercontent.com';

/// Überschreiben: `--dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com`
const String kGoogleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: kDefaultGoogleIosClientId,
);

/// URL-Scheme für Google Sign-In auf iOS (REVERSED_CLIENT_ID).
///
/// Überschreiben: `--dart-define=GOOGLE_IOS_REVERSED_CLIENT_ID=com.googleusercontent.apps....`
const String kGoogleIosReversedClientId = String.fromEnvironment(
  'GOOGLE_IOS_REVERSED_CLIENT_ID',
);

/// True, wenn die nötigen Google-Client-IDs für die aktuelle Plattform gesetzt sind.
bool get isGoogleSignInConfigured {
  if (kGoogleWebClientId.trim().isEmpty) return false;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return kGoogleIosClientId.trim().isNotEmpty;
  }
  return true;
}
