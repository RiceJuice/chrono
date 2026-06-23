-- Schülerliste für Eltern-Suche: SECURITY DEFINER umgeht RLS-Probleme.

CREATE OR REPLACE FUNCTION public.list_searchable_students_for_guardian()
RETURNS TABLE (
  student_id uuid,
  first_name text,
  last_name text,
  class_name text,
  profile_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT
    p.id AS student_id,
    p.first_name,
    p.last_name,
    p.class_name,
    trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) AS profile_name
  FROM public.profiles p
  WHERE public.auth_is_guardian_or_admin()
    AND p.role = 'Schüler'::role
    AND p.onboarding_completed_at IS NOT NULL
    AND p.id <> auth.uid()
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 200;
$$;

REVOKE ALL ON FUNCTION public.list_searchable_students_for_guardian() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_searchable_students_for_guardian() TO authenticated;

-- RLS-Policy robuster (Funktion gecacht pro Abfrage).
DROP POLICY IF EXISTS profiles_select_students_for_guardians ON public.profiles;
CREATE POLICY profiles_select_students_for_guardians ON public.profiles
  FOR SELECT
  USING (
    role = 'Schüler'::role
    AND onboarding_completed_at IS NOT NULL
    AND (SELECT public.auth_is_guardian_or_admin())
  );
