// Run with Node and PGLITE_MODULE pointing to an installed @electric-sql/pglite.
import { readFileSync } from "node:fs";
import assert from "node:assert/strict";
const { PGlite } = await import(
  process.env.PGLITE_MODULE || "@electric-sql/pglite"
);
const db = new PGlite();
await db.exec(`
 CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role;
 CREATE SCHEMA auth; CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
 $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 GRANT USAGE ON SCHEMA auth TO authenticated,anon;
 CREATE TABLE profiles(id uuid PRIMARY KEY,first_name text,last_name text,class_name text,schooltrack text,arts_subject text,
 language_subject text,timetable_subject_choices jsonb DEFAULT '{}',voice text,choir text,diet text,role text,
 calendar_preferences jsonb,active_child_id uuid,guardian_search_classes text[],fcm_token text,fcm_token_updated_at timestamptz,
 updated_at timestamptz,onboarding_completed_at timestamptz);
 CREATE TABLE guardian_child_links(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),guardian_id uuid REFERENCES profiles,
 child_id uuid REFERENCES profiles,status text DEFAULT 'pending',created_at timestamptz DEFAULT now(),responded_at timestamptz,
 reminder_sent_at timestamptz,child_share_permissions jsonb DEFAULT '{}',UNIQUE(guardian_id,child_id));
 ALTER TABLE profiles ENABLE ROW LEVEL SECURITY; ALTER TABLE guardian_child_links ENABLE ROW LEVEL SECURITY;
 CREATE POLICY profiles_own ON profiles TO authenticated USING(id=auth.uid()) WITH CHECK(id=auth.uid());
 CREATE POLICY links_participant ON guardian_child_links FOR SELECT TO authenticated USING(auth.uid() IN(guardian_id,child_id));
 GRANT ALL ON profiles,guardian_child_links TO authenticated;
 GRANT UPDATE(guardian_id) ON guardian_child_links TO authenticated;
 CREATE TABLE profile_push_devices(id uuid PRIMARY KEY,user_id uuid,fcm_token text,platform text);
 CREATE FUNCTION _profile_matches_audience(p profiles,a jsonb,t text) RETURNS boolean LANGUAGE sql AS $$ SELECT p.class_name=a->>'class_name' $$;
 CREATE FUNCTION notify_event_change_targets(jsonb,jsonb,text,uuid) RETURNS TABLE(id uuid,user_id uuid,fcm_token text,platform text,match_type text) LANGUAGE sql AS $$ SELECT *, 'changed'::text FROM profile_push_devices $$;
 CREATE TABLE homework_tasks(id uuid PRIMARY KEY,profile_id uuid,title text);
 ALTER TABLE homework_tasks ENABLE ROW LEVEL SECURITY;
 CREATE POLICY own_tasks ON homework_tasks FOR SELECT TO authenticated USING(profile_id=auth.uid());
 CREATE POLICY guardian_tasks ON homework_tasks FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM guardian_child_links g WHERE g.child_id=homework_tasks.profile_id AND g.guardian_id=auth.uid() AND g.status='confirmed' AND g.child_share_permissions->>'homework'='true'));
 GRANT SELECT ON homework_tasks TO authenticated;

`);
await db.exec(
  readFileSync(
    new URL(
      "../migrations/20261127215040_guardian_link_security.sql",
      import.meta.url,
    ),
    "utf8",
  ),
);
const g = "00000000-0000-0000-0000-000000000001",
  c = "00000000-0000-0000-0000-000000000002",
  b = "00000000-0000-0000-0000-000000000003";
await db.query(
  `INSERT INTO profiles(id,role,first_name,last_name,class_name,onboarding_completed_at) VALUES
 ($1,'Elternteil','Parent','Example',NULL,now()),($2,'Schüler','Child','Example','7a',now()),($3,'Schüler','Other','Child','8a',now())`,
  [g, c, b],
);
async function as(user, sql, params = []) {
  await db.exec("RESET ROLE");
  await db.query("SELECT set_config('request.jwt.claim.sub',$1,false)", [user]);
  await db.exec("SET ROLE authenticated");
  return (await db.query(sql, params)).rows.map((row) =>
    row.request_guardian_links ?? row
  );
}
async function denied(user, sql, params = []) {
  await assert.rejects(() => as(user, sql, params));
}
assert.equal(
  (await as(g, "SELECT * FROM profiles WHERE id=$1", [c])).length,
  0,
);
await denied(g, "UPDATE profiles SET role='Admin' WHERE id=$1", [g]);
assert.equal(
  (await as(g, "SELECT * FROM search_students_for_guardian('Chi')")).length,
  2,
);
await denied(c, "SELECT * FROM search_students_for_guardian('Chi')");
let [l] = await as(g, "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])", [
  c,
]);
await denied(
  g,
  "UPDATE guardian_child_links SET status='confirmed' WHERE id=$1",
  [l.id],
);
await denied(g, "SELECT change_guardian_link($1,'confirm',1,'{}')", [l.id]);
await denied(g, "SELECT change_guardian_link($1,NULL,1,'{}')", [l.id]);
await denied(c, "SELECT change_guardian_link($1,'confirm',NULL,'{}')", [l.id]);
await denied(c, "SELECT change_guardian_link($1,'confirm',1,NULL)", [l.id]);
await denied(c, "UPDATE guardian_child_links SET guardian_id=$2 WHERE id=$1", [
  l.id,
  b,
]);
await denied(g, "UPDATE profiles SET active_child_id=$2 WHERE id=$1", [g, c]);

await denied(b, "SELECT change_guardian_link($1,'confirm',1,'{}')", [l.id]);
let result = await as(
  c,
  `SELECT change_guardian_link($1,'confirm',1,'{"school":true}') AS link`,
  [l.id],
);
assert.equal(result[0].link.revision, 2);
assert.equal(result[0].link.child_class_name, "7a");
assert.equal(result[0].link.child_diet, null);
await db.exec("RESET ROLE");
await db.query(
  "INSERT INTO homework_tasks VALUES(gen_random_uuid(),$1,'Private task')",
  [c],
);
await db.query(
  "INSERT INTO profile_push_devices VALUES(gen_random_uuid(),$1,'synthetic-token','test')",
  [g],
);
assert.equal((await as(g, "SELECT * FROM homework_tasks")).length, 0);
await denied(
  g,
  "SELECT * FROM notify_event_change_targets('{}','{}','lesson',$1)",
  [b],
);
await db.exec("RESET ROLE");
let targets = await db.query(
  "SELECT * FROM notify_event_change_targets('{}',jsonb_build_object('class_name','7a'),'lesson',$1)",
  [b],
);
assert.equal(targets.rows.length, 1);

assert.equal(
  (await as(
    c,
    `SELECT change_guardian_link($1,'confirm',1,'{"school":true}') AS link`,
    [l.id],
  ))[0].link.revision,
  2,
);
assert.equal(
  (await as(g, "SELECT class_name FROM profiles WHERE id=$1", [g]))[0]
    .class_name,
  "7a",
);
await as(c, "SELECT change_guardian_link($1,'permissions',2,'{}')", [l.id]);
assert.equal(
  (await as(g, "SELECT class_name FROM profiles WHERE id=$1", [g]))[0]
    .class_name,
  null,
);
await db.exec("RESET ROLE");
assert.equal(
  (await db.query(
    "SELECT * FROM notify_event_change_targets('{}',jsonb_build_object('class_name','7a'),'lesson',$1)",
    [b],
  )).rows.length,
  0,
);

await as(g, "SELECT change_guardian_link($1,'revoke',3,'{}')", [l.id]);
await denied(c, "SELECT change_guardian_link($1,'confirm',1,'{}')", [l.id]);
await denied(g, "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])", [c]);
assert.equal(
  (await as(g, "SELECT active_child_id FROM profiles WHERE id=$1", [g]))[0]
    .active_child_id,
  null,
);
assert.equal((await as(b, "SELECT * FROM guardian_link_snapshot()")).length, 0);
await denied(g, "SELECT * FROM claim_guardian_notifications()");
await db.exec("RESET ROLE");
await db.query(
  "UPDATE guardian_child_links SET updated_at=now()-interval '8 days',responded_at=now()-interval '8 days' WHERE id=$1",
  [l.id],
);
// The version trigger always owns updated_at; simulate elapsed time without changing production code.
await db.exec(
  "ALTER TABLE guardian_child_links DISABLE TRIGGER guardian_version_link",
);
await db.query(
  "UPDATE guardian_child_links SET updated_at=now()-interval '8 days',responded_at=now()-interval '8 days' WHERE id=$1",
  [l.id],
);
await db.exec(
  "ALTER TABLE guardian_child_links ENABLE TRIGGER guardian_version_link",
);
[l] = await as(g, "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])", [c]);
assert.equal(l.status, "pending");
await denied(g, "SELECT request_guardian_reminder($1)", [l.id]);

// Two guardians and two children retain independent scopes and active selection.
const g2 = "00000000-0000-0000-0000-000000000004";
await db.exec("RESET ROLE");
await db.query(
  "INSERT INTO profiles(id,role,first_name,last_name,onboarding_completed_at) VALUES($1,'Elternteil','Second','Parent',now())",
  [g2],
);
await db.query(
  "UPDATE profiles SET choir='Test Choir',voice='Bass',diet='Vegetarisch' WHERE id=$1",
  [c],
);
[l] = await as(g, "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])", [c]);
let own = await as(c, "SELECT * FROM guardian_link_snapshot()");
let current = own.map((r) => r.guardian_link_snapshot).find((r) =>
  r.id === l.id
);
await as(
  c,
  `SELECT change_guardian_link($1,'confirm',$2,'{"school":false,"choir":true,"meal":true,"homework":true}')`,
  [l.id, current.revision],
);
const [secondLink] = await as(
  g2,
  "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])",
  [c],
);
await as(c, `SELECT change_guardian_link($1,'confirm',$2,'{"school":true}')`, [
  secondLink.id,
  secondLink.revision,
]);
assert.equal((await as(g, "SELECT * FROM homework_tasks")).length, 1);
assert.equal((await as(g2, "SELECT * FROM homework_tasks")).length, 0);
const scoped = (await as(g, "SELECT * FROM guardian_link_snapshot()"))[0]
  .guardian_link_snapshot;
assert.equal(scoped.child_class_name, null);
assert.equal(scoped.child_choir, "Test Choir");
assert.equal(scoped.child_diet, "Vegetarisch");
await denied(g2, "SELECT change_guardian_link($1,'revoke',$2,'{}')", [
  l.id,
  scoped.revision,
]);
const [otherChild] = await as(
  g,
  "SELECT * FROM request_guardian_links(ARRAY[$1::uuid])",
  [b],
);
await as(b, "SELECT change_guardian_link($1,'confirm',$2,'{}')", [
  otherChild.id,
  otherChild.revision,
]);
await as(g, "UPDATE profiles SET active_child_id=$2 WHERE id=$1", [g, b]);
await as(b, "SELECT change_guardian_link($1,'revoke',$2,'{}')", [
  otherChild.id,
  otherChild.revision + 1,
]);
assert.equal(
  (await as(g, "SELECT active_child_id FROM profiles WHERE id=$1", [g]))[0]
    .active_child_id,
  c,
);
await as(c, "SELECT change_guardian_link($1,'revoke',$2,'{}')", [
  l.id,
  scoped.revision,
]);
assert.equal((await as(g, "SELECT * FROM homework_tasks")).length, 0);
assert.equal(
  (await as(g, "SELECT active_child_id FROM profiles WHERE id=$1", [g]))[0]
    .active_child_id,
  null,
);
assert.equal(
  (await as(g2, "SELECT active_child_id FROM profiles WHERE id=$1", [g2]))[0]
    .active_child_id,
  c,
);
// Claim leasing excludes already claimed work; service workers cannot bypass cooldown APIs as clients.
await db.exec("RESET ROLE");
const jobs = await db.query("SELECT * FROM claim_guardian_notifications()");
assert.ok(jobs.rows.length > 0);
assert.equal(
  (await db.query("SELECT * FROM claim_guardian_notifications()")).rows.length,
  0,
);
console.log(
  "PASS: RLS, role protection, minimal search, participant checks, consent, idempotency, revocation, re-request, reminder cooldown, worker grants",
);
await db.close();
