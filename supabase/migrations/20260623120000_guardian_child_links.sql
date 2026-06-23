-- Eltern-Kind-Verknüpfung mit Kind-Bestätigung.

CREATE TABLE IF NOT EXISTS public.guardian_child_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  child_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'rejected', 'revoked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  reminder_sent_at timestamptz,
  CONSTRAINT guardian_child_links_distinct_users CHECK (guardian_id <> child_id),
  UNIQUE (guardian_id, child_id)
);

CREATE INDEX IF NOT EXISTS guardian_child_links_child_status_idx
  ON public.guardian_child_links (child_id, status);

CREATE INDEX IF NOT EXISTS guardian_child_links_guardian_status_idx
  ON public.guardian_child_links (guardian_id, status);

COMMENT ON TABLE public.guardian_child_links IS
  'Verknüpfung Elternteil ↔ Schüler; Zugriff erst nach status=confirmed.';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS active_child_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.profiles.active_child_id IS
  'Aktives Kind für Elternteil-Kalenderfilter (Mehrfach-Kind).';

-- ---------------------------------------------------------------------------
-- RLS: guardian_child_links
-- ---------------------------------------------------------------------------

ALTER TABLE public.guardian_child_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS guardian_child_links_select_participant ON public.guardian_child_links;
CREATE POLICY guardian_child_links_select_participant ON public.guardian_child_links
  FOR SELECT
  USING (guardian_id = auth.uid() OR child_id = auth.uid());

DROP POLICY IF EXISTS guardian_child_links_insert_guardian ON public.guardian_child_links;
CREATE POLICY guardian_child_links_insert_guardian ON public.guardian_child_links
  FOR INSERT
  WITH CHECK (
    guardian_id = auth.uid()
    AND status = 'pending'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'Elternteil'::role
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles c
      WHERE c.id = child_id
        AND c.role = 'Schüler'::role
        AND c.onboarding_completed_at IS NOT NULL
    )
  );

DROP POLICY IF EXISTS guardian_child_links_update_child ON public.guardian_child_links;
CREATE POLICY guardian_child_links_update_child ON public.guardian_child_links
  FOR UPDATE
  USING (child_id = auth.uid() AND status = 'pending')
  WITH CHECK (
    child_id = auth.uid()
    AND status IN ('confirmed', 'rejected')
  );

DROP POLICY IF EXISTS guardian_child_links_update_guardian_revoke ON public.guardian_child_links;
CREATE POLICY guardian_child_links_update_guardian_revoke ON public.guardian_child_links
  FOR UPDATE
  USING (guardian_id = auth.uid())
  WITH CHECK (
    guardian_id = auth.uid()
    AND status = 'revoked'
  );

-- ---------------------------------------------------------------------------
-- RLS: profiles — verknüpfte Kinder für Eltern lesbar
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS profiles_select_linked_children ON public.profiles;
CREATE POLICY profiles_select_linked_children ON public.profiles
  FOR SELECT
  USING (
    id IN (
      SELECT gcl.child_id
      FROM public.guardian_child_links gcl
      WHERE gcl.guardian_id = auth.uid()
        AND gcl.status = 'confirmed'
    )
  );

-- ---------------------------------------------------------------------------
-- RPC: Schüler-Suche für Eltern
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.search_students_for_guardian(p_query text)
RETURNS TABLE (
  id uuid,
  first_name text,
  last_name text,
  class_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_query text := trim(p_query);
  v_pattern text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role = 'Elternteil'::role
  ) THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF length(v_query) < 2 THEN
    RETURN;
  END IF;

  v_pattern := '%' || v_query || '%';

  RETURN QUERY
  SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.class_name
  FROM public.profiles p
  WHERE p.role = 'Schüler'::role
    AND p.onboarding_completed_at IS NOT NULL
    AND p.id <> auth.uid()
    AND (
      p.first_name ILIKE v_pattern
      OR p.last_name ILIKE v_pattern
      OR trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) ILIKE v_pattern
    )
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;
