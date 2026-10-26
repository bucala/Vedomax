"""Fill the CLI-created migration with the API plus content from the single authored bank."""
import json
import pathlib

root=pathlib.Path(__file__).resolve().parents[1]
target=sorted((root/'supabase/migrations').glob('*_daily_learning*.sql'))[-1]
data=json.loads((root/'assets/content/fortnight.json').read_text(encoding='utf8'))
def literal(value):
    if not isinstance(value,str): value=json.dumps(value,ensure_ascii=False,separators=(',',':'))
    return "'"+value.replace("'","''")+"'"
sql=[(root/'supabase/daily_rpc.sql').read_text(encoding='utf8')]
for grade in [8,9]:
    for subject,index,subject_id in [('math',0,3),('slovak',1,1),('geo',2,7)]:
        topic=grade*100+index
        sql.append(f"insert into public.topics(id,subject_id,grade,title_sk,order_index,curriculum_status,curriculum_source,curriculum_standard) values({topic},{subject_id},{grade},'Denný plán 2026',100,'draft',{literal(data['sources'][subject])},'Autorské precvičovanie; tematická väzba uvedená pri otázke');")
for lesson in data['lessons']:
    lid=lesson['id'];topic=lesson['grade']*100+['math','slovak','geo'].index(lesson['subject'])
    sql.append(f"insert into public.lessons(id,topic_id,title_sk,type,time_limit_seconds) values({lid},{topic},{literal(lesson['title'])},'minigame',600);")
    sql.append(f"insert into public.daily_lesson_catalog(lesson_id,grade,day,subject) values({lid},{lesson['grade']},{lesson['day']},{literal(lesson['subject'])});")
    for order,q in enumerate(lesson['questions']):
        content={k:v for k,v in q.items() if k not in ['answer','target','solution','explanation']}
        kind={'choice':'rpg_chat','number':'puzzle_calc','map':'geo_click'}[q['kind']]
        sql.append(f"insert into public.questions(id,lesson_id,question_text_sk,mechanic_type,content_json,order_index) values({literal(q['id'])},{lid},{literal(q['prompt'])},{literal(kind)},{literal(content)}::jsonb,{order});")
        sql.append(f"insert into private.question_keys(question_id,answer) values({literal(q['id'])},{literal(q)}::jsonb);")
sql += ["select setval(pg_get_serial_sequence('public.topics','id'),(select max(id) from public.topics));",
        "select setval(pg_get_serial_sequence('public.lessons','id'),(select max(id) from public.lessons));"]
target.write_text('\n'.join(sql)+'\n',encoding='utf8')
print(target.name)
