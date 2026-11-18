CREATE or RAPLACE FUNCTION maximum(
    a anycompatible, 
    b anycompatible, 
    c anycompatible DEFAULT NULL
) RETURNS anycompatible 
AS $$
SELECT CASE
         WHEN c IS NULL THEN
             x
         ELSE
             CASE WHEN x > c THEN x ELSE c END
       END
FROM (
    SELECT CASE WHEN a > b THEN a ELSE b END
) max2(x);
$$ LANGUAGE sql;


SELECT maximum(10, 300.14, 30E3), maximum ('a', 'v');