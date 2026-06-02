import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? resolveCalendarEntryDiskImageProvider(Object file) {
  if (file is! File) return null;
  return FileImage(file);
}

Widget buildCalendarLocalDiskImage({
  required Object file,
  required BoxFit fit,
  required Widget error,
}) {
  if (file is! File) return error;
  return Image.file(
    file,
    fit: fit,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, _, _) => error,
  );
}
