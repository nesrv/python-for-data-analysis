CREATE or replace FUNCTION rect_hall(max_line integer, max_number integer)
--RETURNS SETOF seats
--RETURNS SETOF record
RETURNS TABLE(t_line text, t_number integer)
IMMUTABLE LANGUAGE sql
BEGIN ATOMIC
    SELECT chr(line+64), number
    FROM generate_series(1,max_line) AS line,
         generate_series(1,max_number) AS number;
END;


EXPLAIN (costs off)
SELECT * FROM rect_hall(2, 3) WITH ORDINALITY;;