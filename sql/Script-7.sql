CREATE or replace FUNCTION hello_tz( 
	IN name text,
	OUT greeting text,
	OUT clock timetz
)
RETURN ('Hello, ' || name || '!' , current_time);


SELECT hello_tz('Alice');