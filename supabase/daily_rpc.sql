-- App API: the server fixes each answer before revealing its solution.
-- Trigger-only function must not be callable from the Data API.
revoke execute on function public.create_profile() from authenticated;
create table public.daily_lesson_catalog (
 lesson_id integer primary key references public.lessons(id),
 grade integer not null check(grade in (8,9)),
 day integer not null check(day between 1 and 14),
 subject text not null check(subject in ('math','slovak','geo')),
 unique(grade,day,subject)
);
alter table public.daily_lesson_catalog enable row level security;
create policy daily_catalog_read on public.daily_lesson_catalog for select to authenticated using(true);
revoke all on public.daily_lesson_catalog from public,anon,authenticated;
grant select on public.daily_lesson_catalog to authenticated;
create table private.daily_runs (
 user_id uuid not null references public.profiles(id) on delete cascade,
 lesson_id integer not null references public.daily_lesson_catalog(lesson_id),
 started_at timestamptz not null default clock_timestamp(),
 result jsonb,
 primary key(user_id,lesson_id)
);
create table private.daily_answers (
 user_id uuid not null,
 lesson_id integer not null,
 question_id uuid not null references public.questions(id),
 feedback jsonb not null,
 points integer not null check(points between 0 and 100),
 primary key(user_id,lesson_id,question_id),
 foreign key(user_id,lesson_id) references private.daily_runs(user_id,lesson_id) on delete cascade
);
alter table private.daily_runs enable row level security;
alter table private.daily_answers enable row level security;
revoke all on private.daily_runs,private.daily_answers from public,anon,authenticated;

create function public.start_daily_lesson(p_lesson_id integer) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 if not exists(select 1 from public.daily_lesson_catalog where lesson_id=p_lesson_id) then raise exception 'Unknown daily lesson'; end if;
 insert into private.daily_runs(user_id,lesson_id) values(auth.uid(),p_lesson_id)
 on conflict(user_id,lesson_id) do update set started_at=clock_timestamp(),result=null;
 delete from private.daily_answers where user_id=auth.uid() and lesson_id=p_lesson_id;
end $$;

create function public.answer_daily_question(p_lesson_id integer,p_question_id uuid,p_answer jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare run private.daily_runs; q record; k jsonb; existing jsonb; expected uuid;
 points integer:=0; distance double precision; h double precision;
 lat double precision; lon double precision; target_lat double precision; target_lon double precision;
 feedback jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 select * into run from private.daily_runs where user_id=auth.uid() and lesson_id=p_lesson_id for update;
 if run.user_id is null then raise exception 'Start lesson first'; end if;
 -- Retry returns the original receipt even after completion; a solution never permits changing the answer.
 select a.feedback into existing from private.daily_answers a
 where a.user_id=auth.uid() and a.lesson_id=p_lesson_id and a.question_id=p_question_id;
 if existing is not null then return existing; end if;
 if run.result is not null then raise exception 'Attempt already completed'; end if;
 if clock_timestamp()>run.started_at+interval '30 minutes' then raise exception 'Attempt expired'; end if;
 select qu.id into expected from public.questions qu where qu.lesson_id=p_lesson_id
 and not exists(select 1 from private.daily_answers a where a.user_id=auth.uid() and a.lesson_id=p_lesson_id and a.question_id=qu.id)
 order by qu.order_index limit 1;
 if expected is null or expected<>p_question_id then raise exception 'Answer questions in order'; end if;
 select qu.*,keys.answer into strict q from public.questions qu
 join private.question_keys keys on keys.question_id=qu.id where qu.id=p_question_id and qu.lesson_id=p_lesson_id;
 k:=q.answer;
 if k->>'kind' in ('choice','number') then
  if jsonb_typeof(p_answer)<>'number' or p_answer is null then raise exception 'Invalid numeric answer'; end if;
  if k->>'kind'='choice' then
   if p_answer=k->'answer' then points:=100; end if;
  elsif abs((p_answer#>>'{}')::numeric-(k->>'answer')::numeric)<=0.01 then points:=100;
  end if;
 elsif k->>'kind'='map' then
  if jsonb_typeof(p_answer->'lat') is distinct from 'number' or jsonb_typeof(p_answer->'lon') is distinct from 'number' then raise exception 'Invalid map coordinates'; end if;
  lat:=(p_answer->>'lat')::double precision;lon:=(p_answer->>'lon')::double precision;
  if not(lat between -90 and 90) or not(lon between -180 and 180) then raise exception 'Invalid map coordinates'; end if;
  target_lat:=(k->'target'->>'lat')::double precision;target_lon:=(k->'target'->>'lon')::double precision;
  h:=power(sin(radians(target_lat-lat)/2),2)+cos(radians(lat))*cos(radians(target_lat))*power(sin(radians(target_lon-lon)/2),2);
  distance:=6371.0088*2*asin(sqrt(least(1.0,greatest(0.0,h))));
  points:=round(least(100.0,greatest(0.0,100*(1-(distance-(k->>'fullCreditKm')::double precision)/
    ((k->>'zeroCreditKm')::double precision-(k->>'fullCreditKm')::double precision)))))::integer;
 else raise exception 'Unsupported question'; end if;
 feedback:=jsonb_build_object('points',points,'solution',k->>'solution','explanation',k->>'explanation',
  'target',k->'target','distance',distance,'correctIndex',case when k->>'kind'='choice' then k->'answer' else null end);
 insert into private.daily_answers(user_id,lesson_id,question_id,feedback,points)
 values(auth.uid(),p_lesson_id,p_question_id,feedback,points);
 return feedback;
end $$;

create function public.complete_daily_lesson(p_lesson_id integer) returns jsonb
language plpgsql security definer set search_path='' as $$
declare run private.daily_runs; total integer; answered integer; score integer; old_score integer; delta integer;
 today date; last_day date; receipt jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 select * into run from private.daily_runs where user_id=auth.uid() and lesson_id=p_lesson_id for update;
 if run.user_id is null then raise exception 'Start lesson first'; end if;
 if run.result is not null then return run.result; end if;
 select count(*) into total from public.questions where lesson_id=p_lesson_id;
 select count(*),round(avg(a.points))::integer into answered,score from private.daily_answers a
 where a.user_id=auth.uid() and a.lesson_id=p_lesson_id;
 if total<>4 or answered<>total then raise exception 'Finish all four questions'; end if;
 select high_score into old_score from public.user_progression where user_id=auth.uid() and lesson_id=p_lesson_id;
 delta:=greatest(0,score-coalesce(old_score,0));
 insert into public.user_progression(user_id,lesson_id,completed,high_score,completed_at)
 values(auth.uid(),p_lesson_id,score=100,score,case when score=100 then now() end)
 on conflict(user_id,lesson_id) do update set high_score=greatest(public.user_progression.high_score,excluded.high_score),
 completed=public.user_progression.completed or excluded.completed,
 completed_at=coalesce(public.user_progression.completed_at,excluded.completed_at);
 today:=(now() at time zone 'Europe/Bratislava')::date;
 select (last_active_at at time zone 'Europe/Bratislava')::date into last_day from public.profiles where id=auth.uid();
 update public.profiles set experience_points=experience_points+delta,
 streak_days=case when last_day=today then streak_days when last_day=today-1 then streak_days+1 else 1 end,
 last_active_at=now() where id=auth.uid();
 receipt:=jsonb_build_object('score',score,'xp_awarded',delta);
 update private.daily_runs set result=receipt where user_id=auth.uid() and lesson_id=p_lesson_id;
 return receipt;
end $$;
revoke all on function public.start_daily_lesson(integer),public.answer_daily_question(integer,uuid,jsonb),public.complete_daily_lesson(integer) from public,anon;
grant execute on function public.start_daily_lesson(integer),public.answer_daily_question(integer,uuid,jsonb),public.complete_daily_lesson(integer) to authenticated;
