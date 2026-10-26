\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('10000000-0000-4000-8000-000000000001'),('10000000-0000-4000-8000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
do $$ begin
 if (select count(*) from public.profiles) <> 1 then raise exception 'Profile RLS broken'; end if;
 if (select count(*) from public.subjects) <> 9 then raise exception 'Subject seed missing'; end if;
 begin
  update public.profiles set experience_points=999999;
  raise exception 'XP write unexpectedly allowed';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.user_progression(user_id,lesson_id,high_score) values(auth.uid(),1,100);
  raise exception 'Direct score write unexpectedly allowed';
 exception when insufficient_privilege then null; end;
 begin
  perform * from private.question_keys;
  raise exception 'Answer key exposed';
 exception when insufficient_privilege then null; end;
end $$;
select public.begin_lesson(1);
select public.submit_lesson(1,'{"00000000-0000-4000-8000-000000000001":4}');
do $$ begin if (select experience_points from public.profiles)<>0 then raise exception 'Wrong answer awarded XP'; end if; end $$;
select public.begin_lesson(1);
select public.submit_lesson(1,'{"00000000-0000-4000-8000-000000000001":5}');
do $$ begin
 if (select experience_points from public.profiles)<>100 then raise exception 'XP award failed'; end if;
 if not (select completed from public.user_progression where lesson_id=1) then raise exception 'Completion failed'; end if;
 begin
  perform public.submit_lesson(1,'{"00000000-0000-4000-8000-000000000001":5}');
  raise exception 'Replay unexpectedly allowed';
 exception when raise_exception then
  if sqlerrm <> 'Attempt expired; restart lesson' then raise; end if;
 end;
end $$;
select public.begin_lesson(1);
select public.submit_lesson(1,'{"00000000-0000-4000-8000-000000000001":5}');
do $$ begin if (select experience_points from public.profiles)<>100 then raise exception 'Repeat farming allowed'; end if; end $$;
select public.begin_lesson(2);
select public.submit_lesson(2,'{"00000000-0000-4000-8000-000000000002":[5,1]}');
select public.begin_lesson(3);
select public.submit_lesson(3,'{"00000000-0000-4000-8000-000000000003":{"x":0.307,"y":0.424}}');
do $$ begin if (select experience_points from public.profiles)<>300 then raise exception 'Mechanic grading failed'; end if; end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$ begin
 if (select count(*) from public.user_progression)<>0 then raise exception 'Cross-user progression leak'; end if;
 if (select experience_points from public.profiles)<>0 then raise exception 'Cross-user XP write'; end if;
end $$;
reset role;
rollback;
