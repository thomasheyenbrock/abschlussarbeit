-- main procedure for regression analysis
CREATE OR REPLACE FUNCTION SLinReg_Main(ref refcursor)
RETURNS refcursor AS $$
BEGIN

OPEN ref FOR
WITH
    beta AS (
        SELECT SUM((purchases - (
            SELECT AVG(purchases)
            FROM regression
        )) * (money - (
            SELECT AVG(money)
            FROM regression
        ))) / SUM(POWER(purchases - (
            SELECT AVG(purchases)
            FROM regression
        ), 2)) AS value
        FROM regression
    ),
    alpha AS (
        SELECT
            (
                SELECT AVG(money)
                FROM regression
            ) - ((
                SELECT value
                FROM beta
            ) * (
                SELECT AVG(purchases)
                FROM regression
            )) AS value
    )
SELECT
    'bias' AS variable,
    value
FROM alpha
UNION
SELECT
    'purchases' AS variable,
    value
FROM beta;

RETURN ref;

END;
$$ LANGUAGE plpgsql;

-- execute main procedure
SELECT SLinReg_Main('cursor');
FETCH ALL IN "cursor";
