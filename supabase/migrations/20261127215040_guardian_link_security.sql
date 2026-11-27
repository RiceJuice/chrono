-- Deploy together with the guardian-link client and reviewed PowerSync streams.
BEGIN;
CREATE SCHEMA IF NOT EXISTS guardian_private;
REVOKE ALL ON SCHEMA guardian_private FROM PUBLIC, anon, authenticated;
CREATE TABLE guardian_private.rate_limits (
  user_id uuid NOT NULL, action text NOT NULL, window_start timestamptz NOT NULL,
  attempts integer NOT NULL, PRIMARY KEY(user_id, action)
);
ALTER TABLE guardian_private.rate_limits ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION guardian_private.limit_action(p_action text, p_limit integer, p_window interval)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE n integer;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated' USING ERRCODE='42501'; END IF;
  INSERT INTO guardian_private.rate_limits AS r VALUES(auth.uid(),p_action,clock_timestamp(),1)
  ON CONFLICT(user_id,action) DO UPDATE SET
    attempts=CASE WHEN r.window_start < clock_timestamp()-p_window THEN 1 ELSE r.attempts+1 END,
    window_start=CASE WHEN r.window_start < clock_timestamp()-p_window THEN clock_timestamp() ELSE r.window_start END
  RETURNING attempts INTO n;
  IF n>p_limit THEN RAISE EXCEPTION 'Bitte später erneut versuchen.' USING ERRCODE='P0001'; END IF;
END $$;
REVOKE ALL ON FUNCTION guardian_private.limit_action(text,integer,interval) FROM PUBLIC;

ALTER TABLE public.guardian_child_links ADD COLUMN revision bigint NOT NULL DEFAULT 1,
  ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN requested_at timestamptz NOT NULL DEFAULT now();
REVOKE INSERT, UPDATE, DELETE ON public.guardian_child_links FROM anon, authenticated;
DROP POLICY IF EXISTS profiles_select_students_for_guardians ON public.profiles;
DROP POLICY IF EXISTS profiles_select_linked_children ON public.profiles;
DROP POLICY IF EXISTS profiles_update_linked_children_for_guardian ON public.profiles;
CREATE FUNCTION guardian_private.is_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text='Admin');
$$;
GRANT USAGE ON SCHEMA guardian_private TO authenticated;
GRANT EXECUTE ON FUNCTION guardian_private.is_admin() TO authenticated;
REVOKE EXECUTE ON FUNCTION guardian_private.is_admin() FROM PUBLIC;
CREATE POLICY profiles_select_admin ON public.profiles FOR SELECT TO authenticated USING (guardian_private.is_admin());
-- Close every legacy overload, including the unfiltered directory endpoint.
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT oid::regprocedure AS signature FROM pg_proc WHERE pronamespace='public'::regnamespace
 AND proname IN ('list_searchable_students_for_guardian','update_linked_child_calendar_defaults','notify_event_change_targets') LOOP
 EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', f.signature);
 END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.search_students_for_guardian(p_query text,p_class_names text[] DEFAULT NULL)
RETURNS TABLE(student_id uuid,first_name text,last_name text,class_name text,profile_name text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE q text := lower(btrim(p_query));
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND role::text IN ('Elternteil','Admin')) THEN
 RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF q IS NULL OR length(q)<3 OR length(q)>100 THEN RETURN; END IF;
 PERFORM guardian_private.limit_action('search',30,interval '1 minute');
 RETURN QUERY SELECT p.id,p.first_name,p.last_name,p.class_name,
 btrim(coalesce(p.first_name,'')||' '||coalesce(p.last_name,'')) FROM public.profiles p
 WHERE p.role::text='Schüler' AND p.onboarding_completed_at IS NOT NULL AND p.id<>auth.uid()
 AND position(q IN lower(coalesce(p.first_name,'')||' '||coalesce(p.last_name,'')))>0
 AND (p_class_names IS NULL OR cardinality(p_class_names)=0 OR p.class_name=ANY(p_class_names))
 ORDER BY p.last_name,p.first_name,p.id LIMIT 10;
END $$;
REVOKE ALL ON FUNCTION public.search_students_for_guardian(text,text[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.search_students_for_guardian(text,text[]) TO authenticated;

-- A role may be selected once during onboarding; never self-assign Admin.
CREATE FUNCTION guardian_private.protect_profile() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF current_user IN ('postgres','service_role','supabase_admin') THEN RETURN NEW; END IF;
 IF NEW.id IS DISTINCT FROM auth.uid() THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF TG_OP='UPDATE' THEN
  IF NEW.id IS DISTINCT FROM OLD.id OR (NEW.role IS DISTINCT FROM OLD.role AND OLD.role IS NOT NULL) THEN
   RAISE EXCEPTION 'Profilbesitz und Rolle sind unveränderlich.' USING ERRCODE='42501'; END IF;
 END IF;
 IF NEW.role::text='Admin' AND (TG_OP='INSERT' OR OLD.role IS NULL) THEN
  RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF NEW.active_child_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.guardian_child_links
 WHERE guardian_id=NEW.id AND child_id=NEW.active_child_id AND status='confirmed') THEN
  RAISE EXCEPTION 'Keine bestätigte Verbindung.' USING ERRCODE='42501'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER a_guardian_protect_profile BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION guardian_private.protect_profile();
-- Keep existing self-edit fields, remove table-wide grants and managed columns.
REVOKE UPDATE, INSERT ON public.profiles FROM authenticated,anon;
GRANT UPDATE(first_name,last_name,class_name,schooltrack,arts_subject,language_subject,
 timetable_subject_choices,voice,choir,diet,role,calendar_preferences,active_child_id,
 guardian_search_classes,fcm_token,fcm_token_updated_at,updated_at) ON public.profiles TO authenticated;

CREATE FUNCTION guardian_private.version_link() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF (NEW.id,NEW.guardian_id,NEW.child_id,NEW.created_at) IS DISTINCT FROM
 (OLD.id,OLD.guardian_id,OLD.child_id,OLD.created_at) THEN
 RAISE EXCEPTION 'Link participants are immutable'; END IF;
 NEW.revision:=OLD.revision+1; NEW.updated_at:=clock_timestamp(); RETURN NEW;
END $$;
CREATE TRIGGER guardian_version_link BEFORE UPDATE ON public.guardian_child_links
FOR EACH ROW EXECUTE FUNCTION guardian_private.version_link();

CREATE TABLE guardian_private.notification_outbox (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), link_id uuid NOT NULL REFERENCES public.guardian_child_links(id) ON DELETE CASCADE,
 revision bigint NOT NULL, action text NOT NULL, attempts integer NOT NULL DEFAULT 0,
 available_at timestamptz NOT NULL DEFAULT now(), claimed_at timestamptz,
 completed_at timestamptz, accepted integer NOT NULL DEFAULT 0, failed integer NOT NULL DEFAULT 0,
 UNIQUE(link_id,revision,action)
);
ALTER TABLE guardian_private.notification_outbox ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION guardian_private.enqueue_link() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
 INSERT INTO guardian_private.notification_outbox(link_id,revision,action)
 VALUES(NEW.id,NEW.revision,CASE NEW.status WHEN 'pending' THEN 'request' ELSE NEW.status END)
 ON CONFLICT DO NOTHING;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guardian_enqueue_link AFTER INSERT OR UPDATE ON public.guardian_child_links
FOR EACH ROW EXECUTE FUNCTION guardian_private.enqueue_link();

CREATE OR REPLACE FUNCTION public.request_guardian_links(p_child_ids uuid[])
RETURNS TABLE(id uuid,guardian_id uuid,child_id uuid,status text,created_at timestamptz,was_inserted boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c uuid; l public.guardian_child_links; changed boolean;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE profiles.id=auth.uid() AND role::text='Elternteil') THEN
 RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF cardinality(p_child_ids) NOT BETWEEN 1 AND 5 THEN RAISE EXCEPTION 'Bitte 1 bis 5 Kinder auswählen.'; END IF;
 PERFORM guardian_private.limit_action('request',10,interval '1 day');
 -- Serializes same-parent requests, including first inserts and repeat requests.
 PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,17));
 FOR c IN SELECT DISTINCT unnest(p_child_ids) LOOP
  IF c=auth.uid() OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE profiles.id=c AND role::text='Schüler' AND onboarding_completed_at IS NOT NULL) THEN
   RAISE EXCEPTION 'Kind nicht verfügbar.'; END IF;
  SELECT * INTO l FROM public.guardian_child_links g WHERE g.guardian_id=auth.uid() AND g.child_id=c FOR UPDATE;
  changed:=false;
  IF NOT FOUND THEN
   INSERT INTO public.guardian_child_links(guardian_id,child_id) VALUES(auth.uid(),c) RETURNING * INTO l; changed:=true;
  ELSIF l.status IN ('rejected','revoked') THEN
   IF l.updated_at>now()-interval '7 days' THEN RAISE EXCEPTION 'Eine neue Anfrage ist nach sieben Tagen möglich.'; END IF;
   UPDATE public.guardian_child_links g SET status='pending',child_share_permissions='{}',responded_at=NULL,
    reminder_sent_at=NULL,requested_at=now() WHERE g.id=l.id RETURNING * INTO l; changed:=true;
  END IF;
  RETURN QUERY SELECT l.id,l.guardian_id,l.child_id,l.status,l.created_at,changed;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION public.request_guardian_links(uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.request_guardian_links(uuid[]) TO authenticated;

CREATE FUNCTION public.change_guardian_link(p_link_id uuid,p_action text,p_revision bigint,p_permissions jsonb DEFAULT '{}')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE l public.guardian_child_links; desired text;
BEGIN
 SELECT * INTO l FROM public.guardian_child_links WHERE id=p_link_id FOR UPDATE;
 IF NOT FOUND OR auth.uid() IS NULL OR auth.uid() NOT IN (l.child_id,l.guardian_id) THEN
 RAISE EXCEPTION 'Anfrage nicht verfügbar.' USING ERRCODE='42501'; END IF;
 IF p_action NOT IN ('confirm','reject','permissions','revoke') THEN RAISE EXCEPTION 'Invalid action'; END IF;
 IF p_action<>'revoke' AND auth.uid()<>l.child_id THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF jsonb_typeof(p_permissions)<>'object' OR EXISTS(SELECT 1 FROM jsonb_each(p_permissions) e
 WHERE e.key NOT IN ('school','meal','choir','homework') OR jsonb_typeof(e.value)<>'boolean') THEN
 RAISE EXCEPTION 'Invalid permissions'; END IF;
 desired:=CASE p_action WHEN 'confirm' THEN 'confirmed' WHEN 'reject' THEN 'rejected' WHEN 'revoke' THEN 'revoked' ELSE 'confirmed' END;
 IF l.revision<>p_revision THEN
  IF l.status=desired AND (p_action IN ('reject','revoke') OR l.child_share_permissions=p_permissions) THEN RETURN to_jsonb(l); END IF;
  RAISE EXCEPTION 'Die Anfrage wurde inzwischen geändert. Bitte aktualisieren.' USING ERRCODE='40001';
 END IF;
 IF (p_action IN ('confirm','reject') AND l.status<>'pending') OR
 (p_action='permissions' AND l.status<>'confirmed') OR
 (p_action='revoke' AND l.status NOT IN ('pending','confirmed','revoked')) THEN
 RAISE EXCEPTION 'Dieser Übergang ist nicht mehr möglich.' USING ERRCODE='40001'; END IF;
 UPDATE public.guardian_child_links SET status=desired,
 child_share_permissions=CASE WHEN desired='confirmed' THEN p_permissions ELSE '{}'::jsonb END,
 responded_at=CASE WHEN p_action='permissions' THEN responded_at ELSE now() END
 WHERE id=l.id RETURNING * INTO l;
 RETURN to_jsonb(l);
END $$;
REVOKE ALL ON FUNCTION public.change_guardian_link(uuid,text,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.change_guardian_link(uuid,text,bigint,jsonb) TO authenticated;

-- Replicate only the participant identity and explicitly consented selectors.
ALTER TABLE public.guardian_child_links
 ADD COLUMN guardian_first_name text, ADD COLUMN guardian_last_name text,
 ADD COLUMN child_first_name text, ADD COLUMN child_last_name text,
 ADD COLUMN child_class_name text, ADD COLUMN child_schooltrack text,
 ADD COLUMN child_arts_subject text, ADD COLUMN child_language_subject text,
 ADD COLUMN child_timetable_subject_choices jsonb,
 ADD COLUMN child_choir text, ADD COLUMN child_voice text, ADD COLUMN child_diet text;
CREATE FUNCTION guardian_private.link_identity() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.profiles; p public.profiles;
BEGIN
 SELECT * INTO c FROM public.profiles WHERE id=NEW.child_id;
 SELECT * INTO p FROM public.profiles WHERE id=NEW.guardian_id;
 NEW.guardian_first_name:=p.first_name; NEW.guardian_last_name:=p.last_name;
 NEW.child_first_name:=c.first_name; NEW.child_last_name:=c.last_name;
 NEW.child_class_name:=NULL; NEW.child_schooltrack:=NULL; NEW.child_arts_subject:=NULL;
 NEW.child_language_subject:=NULL; NEW.child_timetable_subject_choices:=NULL;
 NEW.child_choir:=NULL; NEW.child_voice:=NULL; NEW.child_diet:=NULL;
 IF NEW.status='confirmed' THEN
  IF NEW.child_share_permissions->>'school'='true' THEN
   NEW.child_class_name:=c.class_name; NEW.child_schooltrack:=c.schooltrack;
   NEW.child_arts_subject:=c.arts_subject; NEW.child_language_subject:=c.language_subject;
   NEW.child_timetable_subject_choices:=c.timetable_subject_choices;
  END IF;
  IF NEW.child_share_permissions->>'choir'='true' THEN NEW.child_choir:=c.choir; NEW.child_voice:=c.voice; END IF;
  IF NEW.child_share_permissions->>'meal'='true' THEN NEW.child_diet:=c.diet; END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guardian_link_identity BEFORE INSERT OR UPDATE ON public.guardian_child_links
FOR EACH ROW EXECUTE FUNCTION guardian_private.link_identity();
CREATE FUNCTION guardian_private.refresh_identity() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF (NEW.first_name,NEW.last_name,NEW.class_name,NEW.schooltrack,NEW.arts_subject,NEW.language_subject,NEW.timetable_subject_choices,NEW.choir,NEW.voice,NEW.diet)
 IS DISTINCT FROM (OLD.first_name,OLD.last_name,OLD.class_name,OLD.schooltrack,OLD.arts_subject,OLD.language_subject,OLD.timetable_subject_choices,OLD.choir,OLD.voice,OLD.diet) THEN
 UPDATE public.guardian_child_links SET child_id=child_id WHERE child_id=NEW.id OR (guardian_id=NEW.id AND (NEW.first_name,NEW.last_name) IS DISTINCT FROM (OLD.first_name,OLD.last_name));
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guardian_refresh_identity AFTER UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION guardian_private.refresh_identity();
CREATE FUNCTION public.guardian_link_snapshot() RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$
 SELECT to_jsonb(g) FROM public.guardian_child_links g WHERE auth.uid() IN (g.guardian_id,g.child_id);
$$;
REVOKE ALL ON FUNCTION public.guardian_link_snapshot() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.guardian_link_snapshot() TO authenticated;

CREATE FUNCTION public.request_guardian_reminder(p_link_id uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE l public.guardian_child_links; job uuid;
BEGIN
 SELECT * INTO l FROM public.guardian_child_links WHERE id=p_link_id FOR UPDATE;
 IF NOT FOUND OR auth.uid() IS NULL OR l.guardian_id<>auth.uid() OR l.status<>'pending' THEN
 RAISE EXCEPTION 'Anfrage nicht verfügbar.' USING ERRCODE='42501'; END IF;
 IF greatest(l.requested_at,l.reminder_sent_at)>now()-interval '24 hours' THEN
 RAISE EXCEPTION 'Eine Erinnerung ist erst nach 24 Stunden möglich.'; END IF;
 -- Timestamp reserves an attempt, not proof of delivery. Failures use the outbox retry.
 UPDATE public.guardian_child_links SET reminder_sent_at=now() WHERE id=l.id RETURNING * INTO l;
 INSERT INTO guardian_private.notification_outbox(link_id,revision,action) VALUES(l.id,l.revision,'reminder') RETURNING id INTO job;
 RETURN job;
END $$;
REVOKE ALL ON FUNCTION public.request_guardian_reminder(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.request_guardian_reminder(uuid) TO authenticated;


-- Preserve the deployed derived-profile hook, but clear denied/withdrawn data.
CREATE OR REPLACE FUNCTION public._refresh_guardian_school_profile(p_guardian_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.profiles; chosen uuid; allowed boolean;
BEGIN
 SELECT active_child_id INTO chosen FROM public.profiles WHERE id=p_guardian_id AND role::text='Elternteil';
 IF NOT FOUND THEN RETURN; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.guardian_child_links WHERE guardian_id=p_guardian_id AND child_id=chosen AND status='confirmed') THEN
  SELECT child_id INTO chosen FROM public.guardian_child_links WHERE guardian_id=p_guardian_id AND status='confirmed' ORDER BY created_at,id LIMIT 1;
 END IF;
 SELECT child_share_permissions->>'school'='true' INTO allowed FROM public.guardian_child_links
 WHERE guardian_id=p_guardian_id AND child_id=chosen AND status='confirmed';
 IF allowed THEN SELECT * INTO c FROM public.profiles WHERE id=chosen; END IF;
 UPDATE public.profiles p SET active_child_id=chosen,class_name=c.class_name,schooltrack=c.schooltrack,
 arts_subject=c.arts_subject,language_subject=c.language_subject,timetable_subject_choices=coalesce(c.timetable_subject_choices,'{}')
 WHERE p.id=p_guardian_id AND (p.active_child_id,p.class_name,p.schooltrack,p.arts_subject,p.language_subject,p.timetable_subject_choices)
 IS DISTINCT FROM (chosen,c.class_name,c.schooltrack,c.arts_subject,c.language_subject,coalesce(c.timetable_subject_choices,'{}'));
END $$;
REVOKE ALL ON FUNCTION public._refresh_guardian_school_profile(uuid) FROM PUBLIC,anon,authenticated;
-- An independent hook also covers installations without the school-year feature.
CREATE FUNCTION guardian_private.refresh_parent() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public._refresh_guardian_school_profile(coalesce(NEW.guardian_id,OLD.guardian_id)); RETURN coalesce(NEW,OLD); END $$;
CREATE TRIGGER guardian_refresh_parent AFTER INSERT OR UPDATE OR DELETE ON public.guardian_child_links
FOR EACH ROW EXECUTE FUNCTION guardian_private.refresh_parent();

-- Worker-only leasing. A crashed invocation becomes eligible after five minutes.
CREATE FUNCTION public.claim_guardian_notifications(p_link_id uuid DEFAULT NULL)
RETURNS SETOF jsonb LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 WITH picked AS (SELECT o.id FROM guardian_private.notification_outbox o
 WHERE o.completed_at IS NULL AND o.attempts<3 AND o.available_at<=now()
 AND (o.claimed_at IS NULL OR o.claimed_at<now()-interval '5 minutes')
 AND (p_link_id IS NULL OR o.link_id=p_link_id)
 ORDER BY o.available_at LIMIT 20 FOR UPDATE SKIP LOCKED),
 claimed AS (UPDATE guardian_private.notification_outbox o SET claimed_at=now(),attempts=o.attempts+1
 FROM picked WHERE o.id=picked.id RETURNING o.*)
 SELECT to_jsonb(claimed) FROM claimed;
$$;
CREATE FUNCTION public.finish_guardian_notification(p_id uuid,p_attempt integer,p_accepted integer,p_failed integer,p_retry boolean)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 UPDATE guardian_private.notification_outbox SET accepted=p_accepted,failed=p_failed,
 completed_at=CASE WHEN p_retry AND attempts<3 THEN NULL ELSE now() END,
 available_at=now()+interval '5 minutes'*attempts,claimed_at=NULL
 WHERE id=p_id AND attempts=p_attempt AND completed_at IS NULL;
$$;
REVOKE ALL ON FUNCTION public.claim_guardian_notifications(uuid), public.finish_guardian_notification(uuid,integer,integer,integer,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.claim_guardian_notifications(uuid), public.finish_guardian_notification(uuid,integer,integer,integer,boolean) TO service_role;
-- Populate projections without sending historical notifications. Status/consent remain intact.
UPDATE public.guardian_child_links SET child_id=child_id;
-- Trigger functions are not public RPCs.
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA guardian_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION guardian_private.is_admin() TO authenticated;
COMMIT;
