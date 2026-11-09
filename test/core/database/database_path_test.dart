import 'dart:io';
import 'package:chronoapp/core/database/database_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  setUp(
    () => directory = Directory.systemTemp.createTempSync('chrono-db-test'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  String createCache(int version, {bool data = false, bool pending = false}) {
    final path = p.join(directory.path, 'chrono_powersync_v$version.db');
    final db = sqlite3.open(path);
    db.execute('CREATE TABLE ps_data__subjects (id TEXT)');
    db.execute('CREATE TABLE ps_crud (id TEXT)');
    if (data) db.execute("INSERT INTO ps_data__subjects VALUES ('math')");
    if (pending) db.execute("INSERT INTO ps_crud VALUES ('pending-edit')");
    db.close();
    return path;
  }

  test('reuses populated legacy cache when new version is empty', () {
    final old = createCache(14, data: true);
    createCache(16);
    expect(resolveDatabasePath(directory.path), old);
  });
  test('keeps populated current cache', () {
    createCache(14, data: true);
    final current = createCache(16, data: true);
    expect(resolveDatabasePath(directory.path), current);
  });
  test('never abandons queued changes in current cache', () {
    createCache(14, data: true);
    final current = createCache(16, pending: true);
    expect(resolveDatabasePath(directory.path), current);
  });
  test('new installation starts with current path', () {
    expect(
      resolveDatabasePath(directory.path),
      p.join(directory.path, 'chrono_powersync_v16.db'),
    );
  });
}
