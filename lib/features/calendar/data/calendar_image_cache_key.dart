import '../domain/models/calendar_entry.dart';

/// Stabiler Schlüssel für [CachedNetworkImage], unabhängig von rotierenden Signed URLs.
String calendarEventImageCacheKey({
  required String entryId,
  required int imageIndex,
  required CalendarEntry entry,
}) {
  final paths = entry.imagePaths;
  final urls = entry.imageUrls;
  final sourceKey = (paths != null && paths.length > imageIndex)
      ? paths[imageIndex]
      : (urls != null && urls.length > imageIndex)
      ? urls[imageIndex]
      : 'no-image-$imageIndex';
  return 'calendar-img-$entryId-$imageIndex-$sourceKey';
}
