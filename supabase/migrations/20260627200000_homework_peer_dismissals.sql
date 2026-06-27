-- Abgelehnte Klassen-Vorschläge pro Nutzer (geräteübergreifend).

CREATE TABLE IF NOT EXISTS public.homework_peer_dismissals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  canonical_key text NOT NULL,
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  lesson_date date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT homework_peer_dismissals_unique
    UNIQUE (profile_id, canonical_key, subject_id, lesson_date)
);

CREATE INDEX IF NOT EXISTS homework_peer_dismissals_profile_day_idx
  ON public.homework_peer_dismissals (profile_id, lesson_date);

COMMENT ON TABLE public.homework_peer_dismissals IS
  'Vom Nutzer abgelehnte Klassen-Hausaufgaben-Vorschläge.';

ALTER TABLE public.homework_peer_dismissals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS homework_peer_dismissals_select_own ON public.homework_peer_dismissals;
CREATE POLICY homework_peer_dismissals_select_own ON public.homework_peer_dismissals
  FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_peer_dismissals_insert_own ON public.homework_peer_dismissals;
CREATE POLICY homework_peer_dismissals_insert_own ON public.homework_peer_dismissals
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_peer_dismissals_delete_own ON public.homework_peer_dismissals;
CREATE POLICY homework_peer_dismissals_delete_own ON public.homework_peer_dismissals
  FOR DELETE
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_peer_dismissals_select_guardian_child ON public.homework_peer_dismissals;
CREATE POLICY homework_peer_dismissals_select_guardian_child ON public.homework_peer_dismissals
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.guardian_child_links gcl
      WHERE gcl.guardian_id = auth.uid()
        AND gcl.child_id = homework_peer_dismissals.profile_id
        AND gcl.status = 'confirmed'
        AND COALESCE((gcl.child_share_permissions->>'homework')::boolean, false)
    )
  );
