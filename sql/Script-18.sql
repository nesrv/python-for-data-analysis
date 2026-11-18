CREATE or replace FUNCTION amphitheatre(max_line integer)
RETURNS TABLE(t_line text, t_number integer)
IMMUTABLE LANGUAGE sql
BEGIN ATOMIC
    SELECT chr(line+64), number
    FROM generate_series(1,max_line) AS line,
         generate_series(1,line) AS number;
END;

EXPLAIN (costs off)
SELECT * FROM amphitheatre(10) WITH ORDINALITY;


alter function rect_hall(integer,integer) IMMUTABLE;

EXPLAIN (costs off)
SELECT * FROM rect_hall(2, 3) WHERE t_line = 'A';