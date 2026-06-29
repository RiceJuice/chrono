-- Kürzel aktualisieren: BS → Buchseite, AH Arbeitsheft hinzufügen.

UPDATE public.homework_syntax_suggestions
  SET label = 'Buchseite',
      aliases = ARRAY['Buchseite', 'B.S.', 'bs', 'B.S']
  WHERE shorthand = 'BS'
    AND category = 'book'
    AND is_global = true;

INSERT INTO public.homework_syntax_suggestions
  (category, label, shorthand, aliases, insert_template, chip_color_key, sort_order, is_global)
SELECT
  'notebook',
  'Arbeitsheft',
  'AH',
  ARRAY['Arbeitsheft', 'A.H.', 'ah'],
  '{shorthand}',
  'notebook',
  205,
  true
WHERE NOT EXISTS (
  SELECT 1
  FROM public.homework_syntax_suggestions
  WHERE shorthand = 'AH'
    AND category = 'notebook'
    AND is_global = true
);
