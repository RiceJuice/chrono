/// Hides provenance from imported event text without changing the stored data.
String calendarEntryDisplayText(String? raw) {
  final text = (raw ?? '').trim();
  if (!RegExp(
    r'^\s*(?:Quelle|Quellen|Import)\s*:',
    multiLine: true,
    caseSensitive: false,
  ).hasMatch(text)) {
    return text;
  }
  return text
      .split('\n')
      .where(
        (line) => !RegExp(
          r'^\s*(?:Quelle|Quellen|Import|Original)\s*:',
          caseSensitive: false,
        ).hasMatch(line),
      )
      .map(
        (line) => line
            .replaceAll('in der Quelle ', '')
            .replaceAll(
              '00:00 ist ausschließlich ein technischer Datumsplatzhalter, keine bestätigte Beginnzeit.',
              '',
            )
            .trim(),
      )
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
