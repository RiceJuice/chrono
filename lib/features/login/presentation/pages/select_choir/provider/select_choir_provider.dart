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

  // Die Methode, um die Auswahl zu steuern
  void selectChoir(String label) {
    if (state == label) {
      // Toggle-Logik: Wenn schon ausgewählt, dann abwählen
      state = null;
    } else {
      // Ansonsten: Den neuen Namen als Status setzen
      state = label;
    }
  }
}