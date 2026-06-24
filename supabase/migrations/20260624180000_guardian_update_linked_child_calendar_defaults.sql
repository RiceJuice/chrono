-- Eltern dürfen Kalender-relevante Profilfelder bestätigter Kinder aktualisieren.

CREATE OR REPLACE FUNCTION public.update_linked_child_calendar_defaults(
  p_child_id uuid,
  p_class_name text DEFAULT NULL,
  p_schooltrack text DEFAULT NULL,
  p_voice text DEFAULT NULL,
  p_diet text DEFAULT NULL,
  p_choir text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.guardian_child_links gcl
    WHERE gcl.guardian_id = auth.uid()
      AND gcl.child_id = p_child_id
      AND gcl.status = 'confirmed'
  ) THEN
    RAISE EXCEPTION 'Keine bestätigte Verknüpfung mit diesem Kind'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET
    class_name = COALESCE(p_class_name, class_name),
    schooltrack = COALESCE(p_schooltrack, schooltrack),
    voice = COALESCE(p_voice, voice),
    diet = COALESCE(p_diet, diet),
    choir = COALESCE(p_choir, choir),
    updated_at = now()
  WHERE id = p_child_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_linked_child_calendar_defaults(
  uuid, text, text, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_linked_child_calendar_defaults(
  uuid, text, text, text, text, text
) TO authenticated;
