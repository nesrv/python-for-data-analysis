DO $$
DECLARE  
	cur refcursor;
	rec record;
     
begin    
	 OPEN cur FOR SELECT * FROM t;
	 LOOP
		 fetch cur into rec;
		 exit when not found;
		 raise notice '%', rec;
	 end LOOP;
END
$$;

DO $$
DECLARE  
	cur CURSOR FOR SELECT * FROM t;  
begin    
	 for rec in cur LOOP		
		 raise notice '%', rec;
	 end LOOP;
END
$$;

