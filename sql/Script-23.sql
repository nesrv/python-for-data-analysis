CREATE TABLE t(id integer, s text);


INSERT INTO t VALUES (1, 'Раз'), (2, 'Два'), (3, 'Три');


DO $$
DECLARE  
	cur refcursor;
	rec record;
     
begin    
	 OPEN cur FOR SELECT * FROM t;
	 move cur; 
	 fetch cur into rec;
	 raise notice '%', rec;
	 close cur;
END
$$;



