CREATE TABLE tickets(
    line text,
    number integer,
    movie_start date
);


INSERT INTO tickets VALUES
    ('A', 42, current_date),
    ('B',  1, current_date+1);


SELECT * FROM seats WHERE (line, number) in (
select line, number from tickets where movie_start  = current_date
);