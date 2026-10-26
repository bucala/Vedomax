-- Illustrative draft content, NOT a certified iŠVP mapping. All nine subjects.
insert into public.subjects(id,name_sk,slug) values
(1,'Slovenský jazyk a literatúra','slovensky-jazyk'),(2,'Anglický jazyk','anglicky-jazyk'),
(3,'Matematika','matematika'),(4,'Fyzika','fyzika'),(5,'Chémia','chemia'),
(6,'Biológia','biologia'),(7,'Geografia','geografia'),(8,'Dejepis','dejepis'),(9,'Informatika','informatika')
on conflict(id) do nothing;
insert into public.topics(id,subject_id,grade,title_sk,order_index) values
(1,1,8,'Pravopis a vetné členy',0),(2,1,9,'Súvetie a jazykové štýly',0),
(3,2,8,'Past simple a present perfect',0),(4,2,9,'Komunikácia a podmienkové vety',0),
(5,3,8,'Pytagorova veta',0),(6,3,9,'Podobnosť trojuholníkov',0),
(7,4,8,'Sila a pohyb',0),(8,4,9,'Elektrické obvody',0),
(9,5,8,'Chemické prvky a zlúčeniny',0),(10,5,9,'Organické látky',0),
(11,6,8,'Životné prostredie organizmov',0),(12,6,9,'Dedičnosť a premenlivosť',0),
(13,7,8,'Európa',0),(14,7,9,'Slovensko: sídla a regióny',0),
(15,8,8,'Dlhé 19. storočie',0),(16,8,9,'Svetové vojny a moderné Slovensko',0),
(17,9,8,'Algoritmy a opakovanie',0),(18,9,9,'Programovanie a bezpečnosť na internete',0)
on conflict(id) do nothing;
insert into public.lessons(id,topic_id,title_sk,type,time_limit_seconds) values
(1,5,'Matematika • Zachráň prieskumníka','minigame',120),
(2,1,'Slovenčina • Vetriť chybu','minigame',30),
(3,14,'Geografia • Slepá mapa','minigame',60)
on conflict(id) do nothing;
insert into public.questions(id,lesson_id,question_text_sk,mechanic_type,content_json) values
('00000000-0000-4000-8000-000000000001',1,'Stena má výšku 4 m a päta rebríka je 3 m od steny. Aký dlhý je rebrík?','puzzle_calc','{"a":3,"b":4}'),
('00000000-0000-4000-8000-000000000002',2,'Odhaľ dve pravopisné chyby v príspevku.','detective','{"words":["Moji","kamarátiy","dnes","navštívili","hrad.","Bolily","nadšení!"],"error_indices":[1,5]}'),
('00000000-0000-4000-8000-000000000003',3,'Kde sa nachádza Bojnický zámok?','geo_click','{"map":"assets/maps/slovakia.png"}')
on conflict(id) do nothing;
insert into private.question_keys(question_id,answer) values
('00000000-0000-4000-8000-000000000001','{"value":5,"tolerance":0.01}'),
('00000000-0000-4000-8000-000000000002','{"indices":[1,5]}'),
('00000000-0000-4000-8000-000000000003','{"x":0.307,"y":0.424,"radius":0.06}')
on conflict(question_id) do nothing;
-- Explicit identity values must not collide with subsequently generated IDs.
select setval(pg_get_serial_sequence('public.subjects','id'),(select max(id) from public.subjects));
select setval(pg_get_serial_sequence('public.topics','id'),(select max(id) from public.topics));
select setval(pg_get_serial_sequence('public.lessons','id'),(select max(id) from public.lessons));
