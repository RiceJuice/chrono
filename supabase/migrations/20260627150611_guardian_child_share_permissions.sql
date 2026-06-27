-- Granulare Privatsphäre-Freigaben pro Eltern-Kind-Verknüpfung.

ALTER TABLE public.guardian_child_links
  ADD COLUMN IF NOT EXISTS child_share_permissions jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.guardian_child_links.child_share_permissions IS
  'Freigaben des Kindes für Eltern (school, meal, choir, homework, …).';

-- Kind darf Freigaben nach Bestätigung nachträglich ändern (Status bleibt confirmed).
DROP POLICY IF EXISTS guardian_child_links_update_child_share_permissions
  ON public.guardian_child_links;
CREATE POLICY guardian_child_links_update_child_share_permissions
  ON public.guardian_child_links
  FOR UPDATE
  USING (child_id = auth.uid() AND status = 'confirmed')
  WITH CHECK (child_id = auth.uid() AND status = 'confirmed');
