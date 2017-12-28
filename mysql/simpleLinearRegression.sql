-- drop possibly existing procedures
DROP PROCEDURE IF EXISTS SLinReg_Main;

DELIMITER ;;

-- main procedure for regression analysis
CREATE PROCEDURE `SLinReg_Main`(IN number_datapoints INT(11))
BEGIN

-- declare variables
DECLARE purchasesMean DECIMAL(40, 20);
DECLARE moneyMean DECIMAL(40, 20);
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
FROM regression
LIMIT number_datapoints;

-- calculate means
SET purchasesMean = (
    SELECT AVG(purchases)
    FROM datapoints
);
SET moneyMean = (
    SELECT AVG(money)
    FROM datapoints
);

-- calculate beta
SET beta = (
    SELECT SUM((purchases - purchasesMean) * (money - moneyMean))
    FROM datapoints
);
SET beta = beta / (
    SELECT SUM(POWER(purchases - purchasesMean, 2))
    FROM datapoints
);

-- calculate alpha
SET alpha = moneyMean - (beta * purchasesMean);

-- print parameters alpha and beta
SELECT 'bias' AS `variable`, alpha AS `value`
UNION
SELECT 'purchases' AS `variable`, beta AS `value`;

DROP TEMPORARY TABLE IF EXISTS datapoints;

END;;

DELIMITER ;

-- execute main procedure
CALL SLinReg_Main(100000);
