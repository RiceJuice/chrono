-- Run only after deploying notify-guardian-link and configuring these two Vault
-- secrets through the dashboard: guardian_link_worker_url (full function URL),
-- guardian_link_worker_service_key (service-role JWT, never a client key).
BEGIN;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_extension WHERE extname='pg_cron') OR
    NOT EXISTS(SELECT 1 FROM pg_extension WHERE extname='pg_net') THEN
  RAISE EXCEPTION 'Enable pg_cron and pg_net before scheduling the worker.';
 END IF;
 IF (SELECT count(*) FROM vault.decrypted_secrets WHERE name IN
 ('guardian_link_worker_url','guardian_link_worker_service_key') AND nullif(decrypted_secret,'') IS NOT NULL)<>2 THEN
  RAISE EXCEPTION 'Configure the guardian worker Vault secrets first.';
 END IF;
END $$;
CREATE OR REPLACE FUNCTION guardian_private.dispatch_notifications()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE endpoint text; secret text; request_id bigint;
BEGIN
 SELECT decrypted_secret INTO STRICT endpoint FROM vault.decrypted_secrets WHERE name='guardian_link_worker_url';
 SELECT decrypted_secret INTO STRICT secret FROM vault.decrypted_secrets WHERE name='guardian_link_worker_service_key';
 SELECT net.http_post(url:=endpoint,headers:=jsonb_build_object('Authorization','Bearer '||secret,'Content-Type','application/json'),body:='{}'::jsonb,timeout_milliseconds:=10000) INTO request_id;
 UPDATE guardian_private.notification_outbox SET completed_at=now(),failed=greatest(failed,1) WHERE completed_at IS NULL AND attempts>=3 AND claimed_at<now()-interval '5 minutes';
 DELETE FROM guardian_private.notification_outbox WHERE completed_at<now()-interval '30 days';
 DELETE FROM guardian_private.rate_limits WHERE window_start<now()-interval '30 days';
 RETURN request_id;
END $$;
REVOKE ALL ON FUNCTION guardian_private.dispatch_notifications() FROM PUBLIC,anon,authenticated;
SELECT cron.schedule('guardian-link-outbox','* * * * *','SELECT guardian_private.dispatch_notifications()');
COMMIT;
