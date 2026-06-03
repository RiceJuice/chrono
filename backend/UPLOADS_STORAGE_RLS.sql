-- Storage-RLS: Bucket „uploads“, Dateien FLACH im Root (keine Ordner).
-- App-Dateiname: {auth.uid()}-{timestamp}-{name}.ext
--
-- WICHTIG: Nach jedem Wechsel Ordner ↔ flach dieses Script erneut ausführen!
-- Symptom bei veralteten Policies: 403 „row-level security policy“

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('uploads', 'uploads', false, 20971520, NULL)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit;

-- Alle uploads_* Policies entfernen (inkl. alter Ordner-Varianten).
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname LIKE 'uploads_%'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON storage.objects',
      pol.policyname
    );
  END LOOP;
END $$;

-- INSERT: flache Datei im Root, Präfix = eingeloggte User-ID (wie in der App).
CREATE POLICY "uploads_insert_flat_own_prefix"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'uploads'
  AND name LIKE auth.uid()::text || '-%'
);

-- Fallback: jeder authentifizierte Upload in uploads (falls Präfix-Check scheitert).
CREATE POLICY "uploads_insert_authenticated"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'uploads');

CREATE POLICY "uploads_select_own"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'uploads' AND owner = auth.uid());

CREATE POLICY "uploads_update_own"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'uploads' AND owner = auth.uid())
WITH CHECK (bucket_id = 'uploads' AND owner = auth.uid());

CREATE POLICY "uploads_delete_own"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'uploads' AND owner = auth.uid());

-- Kontrolle (sollte 5 Zeilen zeigen, keine uploads_insert_own_folder mehr):
-- SELECT policyname, cmd FROM pg_policies
-- WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE 'uploads_%';
