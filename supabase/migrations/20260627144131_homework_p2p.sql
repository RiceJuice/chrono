-- Homework P2P Sync: Tabellen.

CREATE TABLE IF NOT EXISTS public.homework_syntax_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL
    CHECK (category IN ('book', 'worksheet', 'notebook', 'format', 'online', 'separator')),
  label text NOT NULL,
  shorthand text NOT NULL,
  aliases text[] NOT NULL DEFAULT '{}',
  insert_template text,
  chip_color_key text NOT NULL DEFAULT 'default',
  sort_order int NOT NULL DEFAULT 0,
  is_global boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS homework_syntax_suggestions_category_idx
  ON public.homework_syntax_suggestions (category, sort_order);

CREATE INDEX IF NOT EXISTS homework_syntax_suggestions_shorthand_idx
  ON public.homework_syntax_suggestions (lower(shorthand));

COMMENT ON TABLE public.homework_syntax_suggestions IS
  'Vorschlagskatalog für Hausaufgaben-Syntax (global + nutzererweiterbar).';

CREATE TABLE IF NOT EXISTS public.homework_contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  class_name text NOT NULL,
  schooltrack public.schooltrack,
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  lesson_date date NOT NULL,
  fragments jsonb NOT NULL DEFAULT '[]'::jsonb,
  fragment_hashes text[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT homework_contributions_unique_per_user_day
    UNIQUE (profile_id, class_name, schooltrack, subject_id, lesson_date)
);

CREATE INDEX IF NOT EXISTS homework_contributions_class_day_idx
  ON public.homework_contributions (class_name, schooltrack, lesson_date);

CREATE INDEX IF NOT EXISTS homework_contributions_subject_idx
  ON public.homework_contributions (subject_id);

COMMENT ON TABLE public.homework_contributions IS
  'Klassen-Peer-Sync: strukturierte Hausaufgaben-Fragmente pro Fach/Tag.';

CREATE TABLE IF NOT EXISTS public.homework_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  fragments jsonb NOT NULL DEFAULT '[]'::jsonb,
  plain_text text,
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  is_completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  due_at timestamptz,
  due_source text CHECK (due_source IS NULL OR due_source IN ('next_lesson', 'custom_date')),
  contribution_id uuid REFERENCES public.homework_contributions(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS homework_tasks_profile_idx
  ON public.homework_tasks (profile_id, is_completed);

COMMENT ON TABLE public.homework_tasks IS
  'Persönliche Hausaufgaben-Aufgaben mit strukturiertem Inhalt.';
