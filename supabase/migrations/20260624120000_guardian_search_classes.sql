-- Distinct Klassen für die Eltern-Schüler-Suche (bereits auf Remote angewendet).

CREATE OR REPLACE FUNCTION public.list_guardian_search_classes()
RETURNS TABLE (class_name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT DISTINCT p.class_name
  FROM public.profiles p
  WHERE p.role IN ('Schüler'::role, 'Admin'::role)
    AND p.onboarding_completed_at IS NOT NULL
    AND p.class_name IS NOT NULL
    AND trim(p.class_name) <> ''
  ORDER BY p.class_name;
$$;

REVOKE ALL ON FUNCTION public.list_guardian_search_classes() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_guardian_search_classes() TO authenticated;
