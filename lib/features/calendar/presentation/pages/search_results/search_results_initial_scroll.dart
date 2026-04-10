import 'package:flutter/material.dart';

void scheduleInitialSearchResultsScroll({
  required ScrollController controller,
  required List<GlobalKey> sectionKeys,
  required int targetSectionIndex,
  required VoidCallback onScrolled,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    if (sectionKeys.isEmpty) return;
    final boundedIndex = targetSectionIndex.clamp(0, sectionKeys.length - 1);
    final targetContext = sectionKeys[boundedIndex].currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.0,
      duration: Duration.zero,
    );
    onScrolled();
  });
}
