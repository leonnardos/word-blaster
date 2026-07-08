insert into public.words (en, pt, topic, topic_level, cefr, examples) values
('see you soon', 'até logo', 'Conversação', 23, 'A1', '[["My aunt says *see you soon* on every call.","Minha tia diz até logo em toda ligação."],["My aunt said *see you soon* last night.","Minha tia disse até logo ontem à noite."],["My aunt will say *see you soon* tomorrow.","Minha tia vai dizer até logo amanhã."]]'::jsonb)
on conflict (en) do update set
  pt = excluded.pt, topic = excluded.topic,
  topic_level = excluded.topic_level,
  cefr = excluded.cefr, examples = excluded.examples;
