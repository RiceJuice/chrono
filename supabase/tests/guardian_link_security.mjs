// Run with Node and PGLITE_MODULE pointing to an installed @electric-sql/pglite.
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
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
`);
await db.exec(readFileSync(new URL('../migrations/20261127215040_guardian_link_security.sql',import.meta.url),'utf8'));
const g='00000000-0000-0000-0000-000000000001', c='00000000-0000-0000-0000-000000000002', b='00000000-0000-0000-0000-000000000003';
await db.query(`INSERT INTO profiles(id,role,first_name,last_name,class_name,onboarding_completed_at) VALUES
 ($1,'Elternteil','Parent','Example',NULL,now()),($2,'Schüler','Child','Example','7a',now()),($3,'Schüler','Other','Child','8a',now())`,[g,c,b]);
async function as(user,sql,params=[]) {
 await db.exec('RESET ROLE'); await db.query("SELECT set_config('request.jwt.claim.sub',$1,false)",[user]);
 await db.exec('SET ROLE authenticated');
 return (await db.query(sql,params)).rows;
}
async function denied(user,sql,params=[]) { await assert.rejects(()=>as(user,sql,params)); }
assert.equal((await as(g,'SELECT * FROM profiles WHERE id=$1',[c])).length,0);
await denied(g,"UPDATE profiles SET role='Admin' WHERE id=$1",[g]);
assert.equal((await as(g,"SELECT * FROM search_students_for_guardian('Chi')")).length,2);
await denied(c,"SELECT * FROM search_students_for_guardian('Chi')");
let [l]=await as(g,'SELECT * FROM request_guardian_links(ARRAY[$1::uuid])',[c]);
await denied(g,"UPDATE guardian_child_links SET status='confirmed' WHERE id=$1",[l.id]);
await denied(g,"SELECT change_guardian_link($1,'confirm',1,'{}')",[l.id]);
await denied(b,"SELECT change_guardian_link($1,'confirm',1,'{}')",[l.id]);
let result=await as(c,`SELECT change_guardian_link($1,'confirm',1,'{"school":true}') AS link`,[l.id]);
assert.equal(result[0].link.revision,2);
assert.equal((await as(c,`SELECT change_guardian_link($1,'confirm',1,'{"school":true}') AS link`,[l.id]))[0].link.revision,2);
assert.equal((await as(g,'SELECT class_name FROM profiles WHERE id=$1',[g]))[0].class_name,'7a');
await as(c,"SELECT change_guardian_link($1,'permissions',2,'{}')",[l.id]);
assert.equal((await as(g,'SELECT class_name FROM profiles WHERE id=$1',[g]))[0].class_name,null);
await as(g,"SELECT change_guardian_link($1,'revoke',3,'{}')",[l.id]);
await denied(c,"SELECT change_guardian_link($1,'confirm',1,'{}')",[l.id]);
await denied(g,'SELECT * FROM request_guardian_links(ARRAY[$1::uuid])',[c]);
assert.equal((await as(g,'SELECT active_child_id FROM profiles WHERE id=$1',[g]))[0].active_child_id,null);
assert.equal((await as(b,'SELECT * FROM guardian_link_snapshot()')).length,0);
await denied(g,'SELECT * FROM claim_guardian_notifications()');
await db.exec('RESET ROLE');
await db.query("UPDATE guardian_child_links SET updated_at=now()-interval '8 days' WHERE id=$1",[l.id]);
// The version trigger always owns updated_at; simulate elapsed time without changing production code.
await db.exec('ALTER TABLE guardian_child_links DISABLE TRIGGER guardian_version_link');
await db.query("UPDATE guardian_child_links SET updated_at=now()-interval '8 days' WHERE id=$1",[l.id]);
await db.exec('ALTER TABLE guardian_child_links ENABLE TRIGGER guardian_version_link');
[l]=await as(g,'SELECT * FROM request_guardian_links(ARRAY[$1::uuid])',[c]);
assert.equal(l.status,'pending');
await denied(g,'SELECT request_guardian_reminder($1)',[l.id]);
console.log('PASS: RLS, role protection, minimal search, participant checks, consent, idempotency, revocation, re-request, reminder cooldown, worker grants');
await db.close();
