-- Klassengefilterte Schülersuche für Eltern + serverseitiger Onboarding-Abschluss.

DROP FUNCTION IF EXISTS public.search_students_for_guardian(text);
DROP FUNCTION IF EXISTS public.search_students_for_guardian(text, text[]);
DROP FUNCTION IF EXISTS public.list_searchable_students_for_guardian();
DROP FUNCTION IF EXISTS public.list_searchable_students_for_guardian(text[]);

CREATE OR REPLACE FUNCTION public.list_searchable_students_for_guardian(
  p_class_names text[] DEFAULT NULL
)
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
    AND (
      p_class_names IS NULL
      OR cardinality(p_class_names) = 0
      OR p.class_name = ANY(p_class_names)
    )
  ORDER BY p.last_name NULLS LAST, p.first_name NULLS LAST
  LIMIT 200;
$$;

CREATE OR REPLACE FUNCTION public.search_students_for_guardian(
  p_query text,
  p_class_names text[] DEFAULT NULL
)
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
  FROM public.list_searchable_students_for_guardian(p_class_names) AS s
  WHERE length(trim(coalesce(p_query, ''))) >= 2
    AND (
      s.profile_name ILIKE ('%' || replace(trim(p_query), ' ', '%') || '%')
      OR s.first_name ILIKE ('%' || trim(p_query) || '%')
      OR s.last_name ILIKE ('%' || trim(p_query) || '%')
    )
  ORDER BY s.profile_name
  LIMIT 20;
$$;

REVOKE ALL ON FUNCTION public.list_searchable_students_for_guardian(text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_searchable_students_for_guardian(text[]) TO authenticated;

REVOKE ALL ON FUNCTION public.search_students_for_guardian(text, text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text, text[]) TO authenticated;

-- Onboarding atomar abschließen (Guardian + Schüler).
CREATE OR REPLACE FUNCTION public.complete_user_onboarding(
  p_active_child_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_role text;
  v_first_name text;
  v_last_name text;
  v_class_name text;
  v_schooltrack text;
  v_voice text;
  v_choir text;
  v_active_child_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT
    p.role::text,
    p.first_name,
    p.last_name,
    p.class_name,
    p.schooltrack,
    p.voice,
    p.choir
  INTO
    v_role,
    v_first_name,
    v_last_name,
    v_class_name,
    v_schooltrack,
    v_voice,
    v_choir
  FROM public.profiles p
  WHERE p.id = v_user_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF v_role = 'Elternteil' THEN
    IF coalesce(trim(v_first_name), '') = ''
       OR coalesce(trim(v_last_name), '') = '' THEN
      RETURN false;
    END IF;

    v_active_child_id := p_active_child_id;

    IF v_active_child_id IS NOT NULL THEN
      IF NOT EXISTS (
        SELECT 1
        FROM public.guardian_child_links gcl
        WHERE gcl.guardian_id = v_user_id
          AND gcl.child_id = v_active_child_id
          AND gcl.status = 'confirmed'
      ) THEN
        v_active_child_id := NULL;
      END IF;
    END IF;

    IF v_active_child_id IS NULL THEN
      SELECT gcl.child_id
      INTO v_active_child_id
      FROM public.guardian_child_links gcl
      WHERE gcl.guardian_id = v_user_id
        AND gcl.status = 'confirmed'
      ORDER BY gcl.responded_at NULLS LAST, gcl.created_at
      LIMIT 1;
    END IF;

    UPDATE public.profiles
    SET
      onboarding_completed_at = now(),
      updated_at = now(),
      active_child_id = coalesce(v_active_child_id, active_child_id)
    WHERE id = v_user_id;

    RETURN true;
  END IF;

  IF v_role = 'Schüler' THEN
    IF coalesce(trim(v_first_name), '') = ''
       OR coalesce(trim(v_last_name), '') = ''
       OR coalesce(trim(v_class_name), '') = ''
       OR coalesce(trim(v_schooltrack), '') = ''
       OR coalesce(trim(v_voice), '') = ''
       OR coalesce(trim(v_choir), '') = '' THEN
      RETURN false;
    END IF;

    UPDATE public.profiles
    SET
      onboarding_completed_at = now(),
      updated_at = now()
    WHERE id = v_user_id;

    RETURN true;
  END IF;

  IF v_role = 'Admin' THEN
    UPDATE public.profiles
    SET
      onboarding_completed_at = now(),
      updated_at = now()
    WHERE id = v_user_id;

    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_user_onboarding(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_user_onboarding(uuid) TO authenticated;
