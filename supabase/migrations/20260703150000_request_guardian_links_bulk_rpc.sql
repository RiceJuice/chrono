-- Bulk-Insert für Guardian-Link-Anfragen (ein Roundtrip statt N Inserts).

CREATE OR REPLACE FUNCTION public.request_guardian_links(p_child_ids uuid[])
RETURNS TABLE (
  id uuid,
  guardian_id uuid,
  child_id uuid,
  status text,
  created_at timestamptz,
  was_inserted boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guardian_id uuid := auth.uid();
BEGIN
  IF v_guardian_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = v_guardian_id
      AND profiles.role = 'Elternteil'::role
  ) THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_child_ids IS NULL OR cardinality(p_child_ids) = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH requested AS (
    SELECT DISTINCT child_id
    FROM unnest(p_child_ids) AS child_id
    WHERE child_id IS NOT NULL
      AND child_id <> v_guardian_id
  ),
  inserted AS (
    INSERT INTO public.guardian_child_links (guardian_id, child_id, status)
    SELECT v_guardian_id, r.child_id, 'pending'
    FROM requested r
    WHERE EXISTS (
      SELECT 1 FROM public.profiles c
      WHERE c.id = r.child_id
        AND c.role = 'Schüler'::role
        AND c.onboarding_completed_at IS NOT NULL
    )
    ON CONFLICT (guardian_id, child_id) DO NOTHING
    RETURNING
      guardian_child_links.id,
      guardian_child_links.guardian_id,
      guardian_child_links.child_id,
      guardian_child_links.status,
      guardian_child_links.created_at
  )
  SELECT
    i.id,
    i.guardian_id,
    i.child_id,
    i.status,
    i.created_at,
    true AS was_inserted
  FROM inserted i
  UNION ALL
  SELECT
    gcl.id,
    gcl.guardian_id,
    gcl.child_id,
    gcl.status,
    gcl.created_at,
    false AS was_inserted
  FROM requested r
  INNER JOIN public.guardian_child_links gcl
    ON gcl.guardian_id = v_guardian_id
   AND gcl.child_id = r.child_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inserted i WHERE i.child_id = r.child_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public.request_guardian_links(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_guardian_links(uuid[]) TO authenticated;
