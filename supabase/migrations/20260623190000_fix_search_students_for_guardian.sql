-- Robustere Schüler-Suche für Eltern (Enum-Rolle, Wortsuche, klarere Fehler).

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
  v_caller_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT p.role::text
  INTO v_caller_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'Profil nicht gefunden' USING ERRCODE = '42501';
  END IF;

  IF v_caller_role NOT IN ('Elternteil', 'Admin') THEN
    RAISE EXCEPTION 'Nur Elternteile können Schüler suchen' USING ERRCODE = '42501';
  END IF;

  IF length(v_query) < 2 THEN
    RETURN;
  END IF;

  -- „Max Weber“ findet auch „Maximilian Weber“ (Leerzeichen → Wildcard).
  v_pattern := '%' || replace(v_query, ' ', '%') || '%';

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
      OR trim(coalesce(p.last_name, '') || ' ' || coalesce(p.first_name, '')) ILIKE v_pattern
    )
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;
