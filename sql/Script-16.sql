CREATE or replace FUNCTION seat_no(seat seats) returns text
IMMUTABLE LANGUAGE sql
RETURN seat.line || seat.number;


SELECT seat_no(ROW('A',42));

create MATERIALIZED VIEW  seats_vm as
	SELECT s.line, number(s), seat_no(s) FROM seats s;


REFRESH MATERIALIZED view seats_vm;

select seat_no from seats_vm;


table seats;