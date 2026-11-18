

CREATE or replace PROCEDURE fill(in nrows integer, out average float)
begin Atomic
	delete from t1;
 	INSERT INTO t1 SELECT random() FROM generate_series(1,nrows);
	select AVG(a) from t1;
end;


call fill(10, 0);


table t1;


DROP PROCEDURE fill(integer);