-- Eltern-Suche und Verknüpfung: Admins wie Schüler behandeln (Profilname, Bestätigung).

DROP FUNCTION IF EXISTS public.search_students_for_guardian(text);
DROP FUNCTION IF EXISTS public.list_searchable_students_for_guardian();

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
  WHERE p.role IN ('Schüler'::role, 'Admin'::role)
    AND p.onboarding_completed_at IS NOT NULL
    AND (auth.uid() IS NULL OR p.id <> auth.uid())
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 200;
$$;

CREATE OR REPLACE FUNCTION public.search_students_for_guardian(p_query text)
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
    s.student_id,
    s.first_name,
    s.last_name,
    s.class_name,
    s.profile_name
  FROM public.list_searchable_students_for_guardian() AS s
  WHERE length(trim(coalesce(p_query, ''))) >= 2
    AND (
      s.profile_name ILIKE ('%' || replace(trim(p_query), ' ', '%') || '%')
      OR s.first_name ILIKE ('%' || trim(p_query) || '%')
      OR s.last_name ILIKE ('%' || trim(p_query) || '%')
    )
  ORDER BY s.profile_name
  LIMIT 20;
$$;

REVOKE ALL ON FUNCTION public.list_searchable_students_for_guardian() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_searchable_students_for_guardian() TO authenticated;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;

DROP POLICY IF EXISTS profiles_select_students_for_guardians ON public.profiles;
CREATE POLICY profiles_select_students_for_guardians ON public.profiles
  FOR SELECT
  USING (
    role IN ('Schüler'::role, 'Admin'::role)
    AND onboarding_completed_at IS NOT NULL
    AND public.auth_is_guardian_or_admin()
  );

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
        AND c.role IN ('Schüler'::role, 'Admin'::role)
        AND c.onboarding_completed_at IS NOT NULL
    )
  );
