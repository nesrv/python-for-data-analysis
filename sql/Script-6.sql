CREATE or replace FUNCTION hello_world_in(in name text, IN greet text DEFAULT 'Dear')
RETURNS text
LANGUAGE sql
return 'Привет-2 ' || greet || ' ' || name || ' !' ;


select hello_world_in('Дорогой', name =>'Dima');

