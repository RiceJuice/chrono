/// Lokale Quelldatei vor dem Upload in den Bucket [uploads] (flach im Root).
class CalendarEventPendingAttachment {
  CalendarEventPendingAttachment({
    required this.id,
    required this.localPath,
    required this.displayName,
    required this.isImage,
    required this.isPdf,
  });

  final String id;
  final String localPath;
  final String displayName;
  final bool isImage;
  final bool isPdf;
}
