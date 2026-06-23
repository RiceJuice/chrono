-- Schüler-Suche: reine SQL-Funktionen (kein PL/pgSQL-Shadowing-Bug).

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
  WHERE auth.uid() IS NOT NULL
    AND p.role = 'Schüler'::role
    AND p.onboarding_completed_at IS NOT NULL
    AND p.id <> auth.uid()
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 200;
$$;

REVOKE ALL ON FUNCTION public.list_searchable_students_for_guardian() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_searchable_students_for_guardian() TO authenticated;

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
  SELECT *
  FROM public.list_searchable_students_for_guardian() s
  WHERE length(trim(p_query)) >= 2
    AND (
      s.profile_name ILIKE ('%' || replace(trim(p_query), ' ', '%') || '%')
      OR s.first_name ILIKE ('%' || trim(p_query) || '%')
      OR s.last_name ILIKE ('%' || trim(p_query) || '%')
    )
  LIMIT 20;
$$;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;
