/// Lokale Quelldatei vor dem Upload in den Bucket [uploads] (flach im Root).
class CalendarEventPendingAttachment {
  CalendarEventPendingAttachment({
    required this.id,
    required this.localPath,
    required this.displayName,
    required this.isImage,
    required this.isPdf,
    this.pixelWidth,
    this.pixelHeight,
  });

  final String id;
  final String localPath;
  final String displayName;
  final bool isImage;
  final bool isPdf;

  /// Pixelabmessungen des Bildes — für Vorschau in natürlichem Seitenverhältnis.
  final int? pixelWidth;
  final int? pixelHeight;

  double? get aspectRatio {
    final w = pixelWidth;
    final h = pixelHeight;
    if (w == null || h == null || h <= 0) return null;
    return w / h;
  }
}
