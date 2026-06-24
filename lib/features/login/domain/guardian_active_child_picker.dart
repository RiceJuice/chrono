import 'package:chronoapp/core/utils/class_name_order.dart';

import 'models/guardian_child_link.dart';

int _compareGuardianChildClass(GuardianChildLink a, GuardianChildLink b) {
  final aClass = a.childClassName?.trim() ?? '';
  final bClass = b.childClassName?.trim() ?? '';

  if (aClass.isEmpty && bClass.isEmpty) return 0;
  if (aClass.isEmpty) return -1;
  if (bClass.isEmpty) return 1;

  return compareClassNames(aClass, bClass);
}

/// Wählt unter bestätigten Verknüpfungen das Kind in der höchsten Klasse.
GuardianChildLink pickGuardianActiveChild(List<GuardianChildLink> confirmed) {
  if (confirmed.isEmpty) {
    throw ArgumentError.value(confirmed, 'confirmed', 'must not be empty');
  }
  if (confirmed.length == 1) return confirmed.first;

  return confirmed.reduce((current, candidate) {
    return _compareGuardianChildClass(candidate, current) > 0
        ? candidate
        : current;
  });
}
