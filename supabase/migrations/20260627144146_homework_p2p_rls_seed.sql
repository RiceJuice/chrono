-- Homework P2P Sync: RLS und Seed-Daten.

ALTER TABLE public.homework_syntax_suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS homework_syntax_suggestions_select ON public.homework_syntax_suggestions;
CREATE POLICY homework_syntax_suggestions_select ON public.homework_syntax_suggestions
  FOR SELECT
  USING (is_global = true OR created_by = auth.uid());

DROP POLICY IF EXISTS homework_syntax_suggestions_insert ON public.homework_syntax_suggestions;
CREATE POLICY homework_syntax_suggestions_insert ON public.homework_syntax_suggestions
  FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND is_global = false
  );

DROP POLICY IF EXISTS homework_syntax_suggestions_update ON public.homework_syntax_suggestions;
CREATE POLICY homework_syntax_suggestions_update ON public.homework_syntax_suggestions
  FOR UPDATE
  USING (created_by = auth.uid() AND is_global = false)
  WITH CHECK (created_by = auth.uid() AND is_global = false);

DROP POLICY IF EXISTS homework_syntax_suggestions_delete ON public.homework_syntax_suggestions;
CREATE POLICY homework_syntax_suggestions_delete ON public.homework_syntax_suggestions
  FOR DELETE
  USING (created_by = auth.uid() AND is_global = false);

ALTER TABLE public.homework_contributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS homework_contributions_select_class ON public.homework_contributions;
CREATE POLICY homework_contributions_select_class ON public.homework_contributions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.class_name = homework_contributions.class_name
        AND (
          homework_contributions.schooltrack IS NULL
          OR p.schooltrack IS NULL
          OR p.schooltrack::text = homework_contributions.schooltrack::text
        )
    )
  );

DROP POLICY IF EXISTS homework_contributions_insert_own ON public.homework_contributions;
CREATE POLICY homework_contributions_insert_own ON public.homework_contributions
  FOR INSERT
  WITH CHECK (
    profile_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.class_name = homework_contributions.class_name
        AND (
          homework_contributions.schooltrack IS NULL
          OR p.schooltrack IS NULL
          OR p.schooltrack::text = homework_contributions.schooltrack::text
        )
    )
  );

DROP POLICY IF EXISTS homework_contributions_update_own ON public.homework_contributions;
CREATE POLICY homework_contributions_update_own ON public.homework_contributions
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (
    profile_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.class_name = homework_contributions.class_name
        AND (
          homework_contributions.schooltrack IS NULL
          OR p.schooltrack IS NULL
          OR p.schooltrack::text = homework_contributions.schooltrack::text
        )
    )
  );

DROP POLICY IF EXISTS homework_contributions_delete_own ON public.homework_contributions;
CREATE POLICY homework_contributions_delete_own ON public.homework_contributions
  FOR DELETE
  USING (profile_id = auth.uid());

ALTER TABLE public.homework_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS homework_tasks_select_own ON public.homework_tasks;
CREATE POLICY homework_tasks_select_own ON public.homework_tasks
  FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_tasks_insert_own ON public.homework_tasks;
CREATE POLICY homework_tasks_insert_own ON public.homework_tasks
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_tasks_update_own ON public.homework_tasks;
CREATE POLICY homework_tasks_update_own ON public.homework_tasks
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS homework_tasks_delete_own ON public.homework_tasks;
CREATE POLICY homework_tasks_delete_own ON public.homework_tasks
  FOR DELETE
  USING (profile_id = auth.uid());

INSERT INTO public.homework_syntax_suggestions
  (category, label, shorthand, aliases, insert_template, chip_color_key, sort_order, is_global)
VALUES
  ('book', 'Buch BS', 'BS', ARRAY['B.S.', 'bs', 'B.S'], '{shorthand} ', 'book', 10, true),
  ('book', 'Buch TB', 'TB', ARRAY['T.B.', 'tb'], '{shorthand} ', 'book', 20, true),
  ('book', 'Buch LB', 'LB', ARRAY['L.B.', 'lb'], '{shorthand} ', 'book', 30, true),
  ('book', 'Buch KB', 'KB', ARRAY['K.B.', 'kb'], '{shorthand} ', 'book', 40, true),
  ('book', 'Buch EB', 'EB', ARRAY['E.B.', 'eb'], '{shorthand} ', 'book', 50, true),
  ('book', 'Buch AB (Lehrbuch)', 'LB AB', ARRAY['LB-AB'], '{shorthand} ', 'book', 60, true),
  ('worksheet', 'Arbeitsblatt', 'AB', ARRAY['Arb.Bl.', 'ArbBl', 'arb.bl', 'Arbeitsblatt'], '{shorthand} ', 'worksheet', 100, true),
  ('worksheet', 'Übungsblatt', 'ÜB', ARRAY['UB', 'Üb.Bl.', 'Übungsblatt'], '{shorthand} ', 'worksheet', 110, true),
  ('worksheet', 'Kopiervorlage', 'KV', ARRAY['Kopie', 'Kopievorlage'], '{shorthand} ', 'worksheet', 120, true),
  ('notebook', 'Hefteintrag', 'HE', ARRAY['H.E.', 'Hefteintrag', 'he', 'H.E'], '{shorthand}', 'notebook', 200, true),
  ('notebook', 'Vokabeln', 'Vok', ARRAY['Vokabeln', 'Vokabelheft', 'Vok.'], '{shorthand}', 'notebook', 210, true),
  ('notebook', 'Lernkartei', 'LK', ARRAY['Lernkarten', 'Karteikarten'], '{shorthand}', 'notebook', 220, true),
  ('notebook', 'Übungsheft', 'ÜH', ARRAY['UH', 'Übungsheft', 'Übungsheft'], '{shorthand}', 'notebook', 230, true),
  ('format', 'Aufgabe', 'Aufg.', ARRAY['Aufg', 'Aufgabe', 'aufg'], '{shorthand} ', 'format', 300, true),
  ('format', 'Übung', 'Ü', ARRAY['Ueb', 'Üb.', 'Übung', 'ue'], '{shorthand} ', 'format', 310, true),
  ('format', 'Nummer', 'Nr.', ARRAY['Nr', 'nummer', 'nr'], '{shorthand} ', 'format', 320, true),
  ('format', 'Seite', 'S.', ARRAY['Seite', 's.', 'S', 'seite'], '{shorthand}', 'separator', 330, true),
  ('format', 'Präsentation', 'Präsi', ARRAY['Praesi', 'Präsentation', 'Referat'], '{shorthand}', 'format', 340, true),
  ('format', 'Lernen', 'lernen', ARRAY['auswendig', 'auswendig lernen'], '{shorthand}', 'format', 350, true),
  ('online', 'IServ', 'IServ', ARRAY['iserv', 'I-Serv'], '{shorthand}', 'online', 400, true),
  ('online', 'Teams', 'Teams', ARRAY['teams', 'MS Teams'], '{shorthand}', 'online', 410, true),
  ('online', 'Online', 'Online', ARRAY['digital', 'online'], '{shorthand}', 'online', 420, true),
  ('separator', 'Seite mit Aufgabe', '/', ARRAY['/', ' / '], '/', 'separator', 500, true);
