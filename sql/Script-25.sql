DO $$
DECLARE  
	rec record; 
begin    
	 for rec in (SELECT * FROM t) LOOP		
		 raise notice '%', rec;
		 DELETE FROM t WHERE id = rec.id;
	 end LOOP;
	 raise notice '%', found;
END
$$;
ROLLBACK;


BEGIN;
DELETE FROM t RETURNING *;
ROLLBACK;