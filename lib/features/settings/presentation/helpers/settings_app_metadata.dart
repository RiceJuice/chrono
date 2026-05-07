import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:package_info_plus/package_info_plus.dart';

class SettingsAppMetadata {
  const SettingsAppMetadata({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get versionLabel => 'Version $version ($buildNumber)';
}

final settingsAppMetadataProvider = fr.FutureProvider<SettingsAppMetadata>((
  ref,
) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return SettingsAppMetadata(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
});
