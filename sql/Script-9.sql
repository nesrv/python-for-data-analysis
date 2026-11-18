CREATE TABLE t1(a float);



CREATE or replace PROCEDURE fill()
AS $$
	TRUNCATE t1;
 	INSERT INTO t1 SELECT random() FROM generate_series(1,3);
$$ LANGUAGE sql;


CREATE or replace PROCEDURE fill()
begin Atomic
	delete from t1;
 	INSERT INTO t1 SELECT random() FROM generate_series(1,3);
end;


call fill();


table t1;