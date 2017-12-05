-- drop possibly existing procedures
DROP PROCEDURE IF EXISTS SLinReg_Main;

DELIMITER ;;

-- main procedure for regression analysis
CREATE PROCEDURE `SLinReg_Main`()
BEGIN

-- declare variables
DECLARE purchasesMean DECIMAL(40, 20);
DECLARE moneyMean DECIMAL(40, 20);
DECLARE alpha DECIMAL(40, 20);
DECLARE beta DECIMAL(40, 20);

-- calculate means
SET purchasesMean = (
    SELECT AVG(purchases)
    FROM regression
);
SET moneyMean = (
    SELECT AVG(money)
    FROM regression
);

-- calculate beta
SET beta = (
    SELECT SUM((purchases - purchasesMean) * (money - moneyMean))
    FROM regression
);
SET beta = beta / (
    SELECT SUM(POWER(purchases - purchasesMean, 2))
    FROM regression
);

-- calculate alpha
SET alpha = moneyMean - (beta * purchasesMean);

-- print parameters alpha and beta
SELECT 'bias' AS `variable`, alpha AS `value`
UNION
SELECT 'purchases' AS `variable`, beta AS `value`;

END;;

DELIMITER ;

-- execute main procedure
CALL SLinReg_Main();
