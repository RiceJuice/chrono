-- A row also records that the optional onboarding step was skipped if both
-- weekdays are NULL. Keep the data separate from profiles, which guardians
-- can read for students they are not yet linked to.
create table public.student_music_lessons (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  starts_on date not null default ((now() at time zone 'Europe/Berlin')::date),
  voice_weekday smallint,
  voice_start_minute smallint,
  voice_teacher text,
  voice_additum boolean not null default false,
  instrument_weekday smallint,
  instrument_start_minute smallint,
  instrument_teacher text,
  instrument_name text,
  instrument_double boolean not null default false,
  constraint voice_lesson_valid check (
    case when voice_weekday is null then
      voice_start_minute is null and voice_teacher is null and not voice_additum
    else
      voice_weekday between 1 and 5 and voice_start_minute is not null
      and voice_start_minute between 0 and (1440 - case when voice_additum then 45 else 15 end)
      and (voice_teacher is null or char_length(btrim(voice_teacher)) between 1 and 100)
    end
  ),
  constraint instrument_lesson_valid check (
    case when instrument_weekday is null then
      instrument_start_minute is null and instrument_teacher is null
      and instrument_name is null and not instrument_double
    else
      instrument_weekday between 1 and 5 and instrument_start_minute is not null
      and instrument_start_minute between 0 and (1440 - case when instrument_double then 45 else 25 end)
      and instrument_name is not null and char_length(btrim(instrument_name)) between 1 and 80
      and (instrument_teacher is null or char_length(btrim(instrument_teacher)) between 1 and 100)
    end
  )
);

alter table public.student_music_lessons enable row level security;
revoke all on public.student_music_lessons from public, anon, authenticated;
grant select, insert, update on public.student_music_lessons to authenticated;

create policy "Students manage their own music lessons"
on public.student_music_lessons
for all to authenticated
using (profile_id = (select auth.uid()))
with check (
  profile_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'Schüler'
  )
);
