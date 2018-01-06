-- drop possibly existing procedures
DROP PROCEDURE IF EXISTS simple_linear_regression;

DELIMITER ;;

-- main procedure for regression analysis
CREATE PROCEDURE `simple_linear_regression`(IN number_datapoints INT(11))
BEGIN

-- declare variables
DECLARE purchases_mean DECIMAL(40, 20);
DECLARE money_mean DECIMAL(40, 20);
DECLARE alpha DECIMAL(40, 20);
DECLARE beta DECIMAL(40, 20);

-- create temporary table with datapoints
DROP TEMPORARY TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
    purchases INT(11),
    money INT(11)
);
INSERT INTO datapoints
SELECT purchases, money
FROM sample
LIMIT number_datapoints;

-- calculate means
SET purchases_mean = (
    SELECT AVG(purchases)
    FROM datapoints
);
SET money_mean = (
    SELECT AVG(money)
    FROM datapoints
);

-- calculate beta
SET beta = (
    SELECT SUM((purchases - purchases_mean) * (money - money_mean))
    FROM datapoints
);
SET beta = beta / (
    SELECT SUM(POWER(purchases - purchases_mean, 2))
    FROM datapoints
);

-- calculate alpha
SET alpha = money_mean - (beta * purchases_mean);

-- print parameters alpha and beta
SELECT 'bias' AS `variable`, alpha AS `value`
UNION
SELECT 'purchases' AS `variable`, beta AS `value`;

DROP TEMPORARY TABLE IF EXISTS datapoints;

END;;

DELIMITER ;

-- execute main procedure
CALL simple_linear_regression(100000);
