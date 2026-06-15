import 'package:flutter/material.dart';

/// Fügt [gap] zwischen aufeinanderfolgende Widgets ein.
List<Widget> spacedWidgets(List<Widget> items, double gap) {
  if (items.isEmpty) return items;
  final spaced = <Widget>[items.first];
  for (var i = 1; i < items.length; i++) {
    spaced
      ..add(SizedBox(height: gap))
      ..add(items[i]);
  }
  return spaced;
}
