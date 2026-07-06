-- Persönliche Schul-Termine (Schulaufgabe, Referat, Stegreifaufgabe) pro Profil.

CREATE TABLE IF NOT EXISTS public.school_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind text NOT NULL
    CHECK (kind IN ('schulaufgabe', 'referat', 'stegreifaufgabe')),
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  scheduled_at timestamptz NOT NULL,
  schedule_source text NOT NULL
    CHECK (schedule_source IN ('lesson_slot', 'custom_date')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS school_assessments_profile_idx
  ON public.school_assessments (profile_id);

CREATE INDEX IF NOT EXISTS school_assessments_subject_scheduled_idx
  ON public.school_assessments (subject_id, scheduled_at);

COMMENT ON TABLE public.school_assessments IS
  'Persönliche Schul-Termine: ersetzen eine Stunde visuell im Kalender.';

ALTER TABLE public.school_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS school_assessments_select_own ON public.school_assessments;
CREATE POLICY school_assessments_select_own ON public.school_assessments
  FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS school_assessments_insert_own ON public.school_assessments;
CREATE POLICY school_assessments_insert_own ON public.school_assessments
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS school_assessments_update_own ON public.school_assessments;
CREATE POLICY school_assessments_update_own ON public.school_assessments
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS school_assessments_delete_own ON public.school_assessments;
CREATE POLICY school_assessments_delete_own ON public.school_assessments
  FOR DELETE
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS school_assessments_select_guardian_child ON public.school_assessments;
CREATE POLICY school_assessments_select_guardian_child ON public.school_assessments
  FOR SELECT
  USING (
    profile_id IN (
      SELECT child_id
      FROM public.guardian_child_links
      WHERE guardian_id = auth.uid()
        AND status = 'confirmed'
        AND COALESCE((child_share_permissions->>'school')::boolean, false)
    )
  );
