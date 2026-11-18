DO $$
DECLARE
    cur refcursor := 'cursor12345';
BEGIN
    OPEN cur FOR SELECT * FROM t;
    RAISE NOTICE '%', cur;
END
$$;


CREATE or replace FUNCTION t_cur(cur refcursor) RETURNS void
AS $$
DECLARE
    cur refcursor;
BEGIN
    OPEN cur FOR SELECT * FROM t;
    RETURN cur;
END
$$ LANGUAGE plpgsql;


CREATE or replace FUNCTION t_cur_2(cur refcursor) RETURNS void
AS $$
BEGIN
    OPEN cur FOR SELECT * FROM t;
END
$$ LANGUAGE plpgsql;