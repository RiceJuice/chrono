# Storage: Bucket `uploads` (flach, ohne Ordner)

## Pfad in der App

```text
uploads/42f62473-9408-…-1780509500635-…-bild.jpg
```

Kein `{userId}/…`-Ordner — nur der **Dateiname** beginnt mit der User-UUID.

## 403 nach Umstellung auf „flach“

Die **alten** Policies (`uploads_insert_own_folder`) erwarten einen Ordner `{auth.uid()}/…`. Flache Dateien erfüllen das nicht → **403**.

**Fix:** [`UPLOADS_STORAGE_RLS.sql`](./UPLOADS_STORAGE_RLS.sql) im [SQL Editor](https://supabase.com/dashboard/project/chrbvfaknykaycwumuba/sql/new) ausführen. Das Script löscht alle `uploads_*` Policies und legt neue an.

### Prüfen

```sql
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE 'uploads_%';
```

Erwartet u. a. `uploads_insert_flat_own_prefix`, **nicht** `uploads_insert_own_folder`.

## Erfolg in der App

```text
[EventSourceUpload] ok path=42f62473-…-….jpg
```
