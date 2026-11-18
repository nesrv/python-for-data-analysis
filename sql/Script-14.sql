CREATE TABLE seats(
    line text,
    number integer
);

INSERT INTO seats VALUES
    ('A', 42), ('B',  1), ('C', 27);


table seats;

SELECT typtype FROM pg_type WHERE typname = 'seats';
SELECT * FROM seats s WHERE s < ('B',52)::seats;