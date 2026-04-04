/// PowerSync Cloud. Überschreiben: `--dart-define=POWERSYNC_URL=...`
const String kDefaultPowerSyncUrl =
    'https://69d133791d5ec6fc42c8c528.powersync.journeyapps.com';

const String kPowerSyncUrl = String.fromEnvironment(
  'POWERSYNC_URL',
  defaultValue: kDefaultPowerSyncUrl,
);

bool isPowerSyncSyncEnabled() {
  final url = kPowerSyncUrl.trim();
  if (url.isEmpty) return false;
  final lower = url.toLowerCase();
  if (lower.contains('deine_powersync') || lower.contains('your_powersync')) {
    return false;
  }
  final uri = Uri.tryParse(url);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}
