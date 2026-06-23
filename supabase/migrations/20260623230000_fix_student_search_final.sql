-- Schüler-Suche: ohne auth_is_guardian_or_admin-Blocker, Wortsuche auf Profilname.

DROP FUNCTION IF EXISTS public.search_students_for_guardian(text);
DROP FUNCTION IF EXISTS public.list_searchable_students_for_guardian();

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
  v_caller_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT p.role::text INTO v_caller_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  -- Schüler dürfen nicht suchen; Elternteil/Admin/Onboarding (NULL) schon.
  IF v_caller_role = 'Schüler' THEN
    RAISE EXCEPTION 'Nur Elternteile können Schüler suchen' USING ERRCODE = '42501';
  END IF;

  IF length(v_query) < 2 THEN
    RETURN;
  END IF;

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
      trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) ILIKE
        ('%' || replace(v_query, ' ', '%') || '%')
      OR p.first_name ILIKE ('%' || v_query || '%')
      OR p.last_name ILIKE ('%' || v_query || '%')
      OR (
        SELECT bool_and(
          trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')) ILIKE
            ('%' || replace(w.word, ' ', '%') || '%')
          OR p.first_name ILIKE ('%' || w.word || '%')
          OR p.last_name ILIKE ('%' || w.word || '%')
        )
        FROM unnest(regexp_split_to_array(v_query, '\s+')) AS w(word)
        WHERE length(trim(w.word)) >= 2
      )
    )
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text) TO authenticated;
