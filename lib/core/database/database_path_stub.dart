/// Web-Variante von `database_path.dart`: Im Browser gibt es kein Dateisystem
/// und keine alten Cache-Dateien, PowerSync nutzt einen festen DB-Namen.
String resolveDatabasePath(String directory) => 'chrono_powersync_v16.db';
