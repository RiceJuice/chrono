import 'package:flutter/material.dart';

void scheduleInitialSearchResultsScroll({
  required ScrollController controller,
  required List<GlobalKey> sectionKeys,
  required int targetSectionIndex,
  required VoidCallback onScrolled,
}) {
  const maxAttempts = 8;

  void tryScroll(int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients || sectionKeys.isEmpty) return;
      final boundedIndex = targetSectionIndex.clamp(0, sectionKeys.length - 1);
      final targetContext = sectionKeys[boundedIndex].currentContext;

      if (targetContext == null) {
        if (attempt < maxAttempts) {
          tryScroll(attempt + 1);
        }
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: Duration.zero,
      );
      onScrolled();
    });
  }

  tryScroll(1);
}
