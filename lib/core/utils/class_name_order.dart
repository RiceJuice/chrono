/// Vergleicht Klassennamen (z. B. „9b“, „10a“) für Sortierung.
int compareClassNames(String a, String b) {
  final aTrimmed = a.trim();
  final bTrimmed = b.trim();

  if (aTrimmed.isEmpty && bTrimmed.isEmpty) return 0;
  if (aTrimmed.isEmpty) return 1;
  if (bTrimmed.isEmpty) return -1;

  final numberPattern = RegExp(r'\d+');
  final aMatch = numberPattern.firstMatch(aTrimmed);
  final bMatch = numberPattern.firstMatch(bTrimmed);

  if (aMatch != null && bMatch != null) {
    final aNumber = int.tryParse(aMatch.group(0)!);
    final bNumber = int.tryParse(bMatch.group(0)!);
    if (aNumber != null && bNumber != null && aNumber != bNumber) {
      return aNumber.compareTo(bNumber);
    }
  }

  return aTrimmed.toLowerCase().compareTo(bTrimmed.toLowerCase());
}
