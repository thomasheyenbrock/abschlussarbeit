-- main procedure for regression analysis
CREATE OR REPLACE FUNCTION simple_linear_regression(ref refcursor, number_datapoints int)
RETURNS refcursor AS $$
BEGIN

DROP TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
    purchases INTEGER,
    money INTEGER
);

INSERT INTO datapoints
SELECT purchases, money
FROM sample
LIMIT number_datapoints;

OPEN ref FOR
WITH
    means AS (
        SELECT
            AVG(purchases) AS mean_purchases,
            AVG(money) AS mean_money
        FROM datapoints
    ),
    sums AS (
        SELECT
            SUM((purchases - (SELECT mean_purchases FROM means)) * (money - (SELECT mean_money FROM means))) AS nominator,
            SUM(POWER(purchases - (SELECT mean_purchases FROM means), 2)) AS denominator
        FROM datapoints
    ),
    beta AS (
        SELECT
            'beta' AS variable,
            nominator / denominator AS value
        FROM sums
    ),
    alpha AS (
        SELECT
            'alpha' AS variable,
            mean_money - (SELECT value FROM beta) * mean_purchases AS value
        FROM means
    )
SELECT *
FROM alpha
UNION
SELECT *
FROM beta;

RETURN ref;

END;
$$ LANGUAGE plpgsql;

-- execute main procedure
SELECT simple_linear_regression('cursor', 100000);
FETCH ALL IN "cursor";
