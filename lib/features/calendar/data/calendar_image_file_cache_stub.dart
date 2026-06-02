/// Web: kein Dateisystem-Cache — Bilder laufen über [CachedNetworkImage].
abstract final class CalendarImageFileCache {
  static Object? peek(String cacheKey) => null;

  static void remember(String cacheKey, Object file) {}

  static Future<Object?> resolve(String cacheKey) async => null;
}
