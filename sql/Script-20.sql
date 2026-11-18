CREATE FUNCTION sqr_in(IN a numeric) RETURNS numeric
AS $$
BEGIN
    RETURN a * a;
end
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION sqr_OUT(IN a numeric, out retval numeric) 
AS $$
BEGIN
    retval := a * a;
end
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION sqr_INOUT(INOUT a numeric)
AS $$
BEGIN
    a := a * a;
end
$$ LANGUAGE plpgsql IMMUTABLE;

select sqr_INOUT(5), sqr_OUT(5);

