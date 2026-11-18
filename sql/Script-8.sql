CREATE TABLE t(n integer);


CREATE or replace FUNCTION cnt() RETURNS bigint
LANGUAGE sql VOLATILE 
RETURN (SELECT count(*) FROM t);




table t;

CREATE FUNCTION rnd() RETURNS float
LANGUAGE sql VOLATILE 
RETURN random();

EXPLAIN (costs off)

SELECT * FROM generate_series(1,10) WHERE rnd() > 0.5;


ALTER FUNCTION rnd() immutable;