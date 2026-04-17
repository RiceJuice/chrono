import 'package:riverpod_annotation/riverpod_annotation.dart';


// Diese Zeile ist wichtig für die Code-Generierung (Dateiname muss passen!)
part 'select_choir_provider.g.dart'; 

@riverpod
class SelectedChoir extends _$SelectedChoir {
  
  // Hier definierst du den Startwert (nichts ausgewählt)
  @override
  String? build() {
    return null; 
  }

  /// Setzt den Chor passend zur aktuell zentrierten Karussell-Seite (ohne Tap-Bestätigung).
  void selectChoir(String label) {
    state = label;
  }
}