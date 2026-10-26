// Runs against an isolated in-memory PostgreSQL instance; never uses the hosted database.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const bank = JSON.parse(fs.readFileSync('assets/content/fortnight.json', 'utf8'));
const uid = '20000000-0000-4000-8000-000000000001';
const otherUid = '20000000-0000-4000-8000-000000000002';
const sqlFile = path => fs.readFileSync(path, 'utf8').replace(/^\\set.*$/mg, '');
const call = async (name, args) => {
  const params = args.map((_,i)=>`$${i+1}`).join(',');
  return (await db.query(`select public.${name}(${params}) as result`, args)).rows[0].result;
};
const expectFailure = async (sql, params, match) => {
  await db.exec('savepoint expected_failure');
  try {
    await db.query(sql, params);
    throw new Error('Query unexpectedly succeeded: '+sql);
  } catch (error) {
    assert.match(error.message, match);
  } finally { await db.exec('rollback to savepoint expected_failure; release savepoint expected_failure'); }
};
try {
  for (const path of ['supabase/tests/bootstrap.sql','supabase/migrations/202610260001_core.sql','supabase/seed.sql',
    ...fs.readdirSync('supabase/migrations').filter(p=>p.includes('_daily_learning')).map(p=>'supabase/migrations/'+p)]) {
    await db.exec(sqlFile(path));
  }
  await db.exec(sqlFile('supabase/tests/security.sql'));
  console.log('PASS existing security and grading checks');
  await db.exec(`begin; insert into auth.users(id) values('${uid}'),('${otherUid}'); set local role authenticated;`);
  await db.query("select set_config('request.jwt.claim.sub',$1,true)",[uid]);
  const first=bank.lessons[0];
  await expectFailure('select public.complete_daily_lesson($1)',[first.id],/Start lesson first/);
  await call('start_daily_lesson',[first.id]);
  await expectFailure('select public.complete_daily_lesson($1)',[first.id],/Finish all four questions/);
  await expectFailure('select public.answer_daily_question($1,$2,$3)',[first.id,first.questions[1].id,'0'],/Answer questions in order/);
  await expectFailure('select * from private.daily_answers',[],/permission denied/);
  await expectFailure('update public.profiles set experience_points=99999',[],/permission denied/);
  for(const lesson of bank.lessons) {
    await call('start_daily_lesson',[lesson.id]);
    for(const q of lesson.questions) {
      const answer=q.kind==='map'?q.target:q.answer;
      const feedback=await call('answer_daily_question',[lesson.id,q.id,JSON.stringify(answer)]);
      assert.equal(feedback.points,100,`${lesson.id}: ${q.prompt}`);
      assert.equal(feedback.solution,q.solution);
      const retry=await call('answer_daily_question',[lesson.id,q.id,JSON.stringify(q.kind==='map'?{lat:0,lon:0}:99999)]);
      assert.deepEqual(retry,feedback,'answer cannot be changed after reveal');
    }
    assert.deepEqual(await call('complete_daily_lesson',[lesson.id]),{score:100,xp_awarded:100});
    assert.deepEqual(await call('complete_daily_lesson',[lesson.id]),{score:100,xp_awarded:100});
  }
  assert.equal((await db.query('select experience_points from public.profiles')).rows[0].experience_points,8400);
  await call('start_daily_lesson',[first.id]);
  for(const q of first.questions) await call('answer_daily_question',[first.id,q.id,JSON.stringify(q.answer)]);
  assert.equal((await call('complete_daily_lesson',[first.id])).xp_awarded,0);
  const geo=bank.lessons.find(l=>l.subject==='geo');
  await call('start_daily_lesson',[geo.id]);
  const map=geo.questions[0];
  const partial=await call('answer_daily_question',[geo.id,map.id,JSON.stringify({lat:map.target.lat+1.17,lon:map.target.lon})]);
  assert.equal(partial.points,50);
  assert.ok(partial.distance>129 && partial.distance<131);
  await db.query("select set_config('request.jwt.claim.sub',$1,true)",[otherUid]);
  assert.equal((await db.query('select count(*)::int n from public.user_progression')).rows[0].n,0);
  await expectFailure('select public.answer_daily_question($1,$2,$3)',[geo.id,map.id,'0'],/Start lesson first/);
  await db.exec('set local role anon');
  await expectFailure('select public.start_daily_lesson($1)',[first.id],/permission denied/);
  await db.exec('rollback');
  console.log('PASS 336 server-graded answers, map distance/partial credit, sequence, replay safety, XP caps, isolation and anonymous denial');
} catch(error) { console.error(error.message); process.exitCode=1; }
finally { await db.close(); }
