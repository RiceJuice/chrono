-- Schüler-Suche für Eltern: Profilname (Vor- + Nachname), REST-Fallback.

CREATE OR REPLACE FUNCTION public.auth_is_guardian_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role::text IN ('Elternteil', 'Admin')
  );
$$;

REVOKE ALL ON FUNCTION public.auth_is_guardian_or_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_guardian_or_admin() TO authenticated;

DROP FUNCTION IF EXISTS public.search_students_for_guardian(text);

CREATE OR REPLACE FUNCTION public.search_students_for_guardian(p_query text)
RETURNS TABLE (
  student_id uuid,
  first_name text,
  last_name text,
  class_name text,
  profile_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_query text := trim(p_query);
  v_pattern text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.auth_is_guardian_or_admin() THEN
    RAISE EXCEPTION 'Nur Elternteile können Schüler suchen' USING ERRCODE = '42501';
  END IF;

  IF length(v_query) < 2 THEN
    RETURN;
  END IF;

  v_pattern := '%' || replace(v_query, ' ', '%') || '%';

  RETURN QUERY
  SELECT
    p.id AS student_id,
    p.first_name,
    p.last_name,
    p.class_name,
    trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) AS profile_name
  FROM public.profiles p
  WHERE p.role = 'Schüler'::role
    AND p.onboarding_completed_at IS NOT NULL
    AND p.id <> auth.uid()
    AND (
      trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) ILIKE v_pattern
      OR p.first_name ILIKE v_pattern
      OR p.last_name ILIKE v_pattern
    )
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;

DROP POLICY IF EXISTS profiles_select_students_for_guardians ON public.profiles;
CREATE POLICY profiles_select_students_for_guardians ON public.profiles
  FOR SELECT
  USING (
    role = 'Schüler'::role
    AND onboarding_completed_at IS NOT NULL
    AND public.auth_is_guardian_or_admin()
  );
