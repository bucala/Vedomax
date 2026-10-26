-- Run in SQL Editor or psql. Entire fixture is rolled back: no real accounts or XP are modified.
begin;
insert into auth.users(id) values
 ('20000000-0000-4000-8000-000000000001'),
 ('20000000-0000-4000-8000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000001',true);
select public.start_daily_lesson(80010);
do $$
declare q record; feedback jsonb;
begin
 for q in select id from public.questions where lesson_id=80010 order by order_index loop
  feedback:=public.answer_daily_question(80010,q.id,'-1'::jsonb);
  if (feedback->>'points')::integer<>100 then raise exception 'Server grading failed'; end if;
  if public.answer_daily_question(80010,q.id,'999'::jsonb)<>feedback then raise exception 'Answer changed after reveal'; end if;
 end loop;
end $$;
select public.complete_daily_lesson(80010);
select public.complete_daily_lesson(80010);
do $$ begin
 if (select experience_points from public.profiles)<>100 then raise exception 'Completion retry awarded duplicate XP'; end if;
 begin
  perform * from private.daily_answers;
  raise exception 'Private answers exposed';
 exception when insufficient_privilege then null; end;
 begin
  update public.profiles set experience_points=99999;
  raise exception 'Direct XP modification allowed';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
do $$ begin
 if (select count(*) from public.user_progression)<>0 then raise exception 'Cross-user progression leak'; end if;
 if (select experience_points from public.profiles)<>0 then raise exception 'Cross-user profile leak'; end if;
end $$;
set local role anon;
do $$ begin
 begin
  perform public.start_daily_lesson(80010);
  raise exception 'Anonymous access allowed';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'daily security checks passed; fixture rolled back' as validation;
