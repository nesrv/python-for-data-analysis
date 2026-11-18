CREATE or replace FUNCTION maximum(a integer, b integer, c integer)
RETURNS integer
RETURN CASE 
	WHEN a > b THEN maximum(a,c)
	ELSE maximum (b,c)
END;




SELECT maximum(10, 200, 10);