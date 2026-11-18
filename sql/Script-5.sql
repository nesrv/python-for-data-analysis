
CREATE or replace FUNCTION hello_world()
returns text
as $$ select 'Привет' ; $$
language sql;


CREATE or replace FUNCTION hello_world_1() 
returns text
return 'Привет-1';

CREATE or replace FUNCTION hello_world_2() RETURNS text
begin atomic
	select 'Привет-1';
	select 'Привет-2'; 
end;

select hello_world_2();


select hello_world_1();

# NO
# BEGIN, COMMIT, ROLLBACK 
# VACUUM или CREATE INDEX