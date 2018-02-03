-- Lösche die bestehende Prozedur, falls vorhanden.
DROP PROCEDURE IF EXISTS simple_linear_regression;

DELIMITER ;;

-- Erstelle die Prozedur für einfache lineare Regression.
CREATE PROCEDURE `simple_linear_regression`(IN number_datapoints INT(11))
BEGIN

-- Deklariere die verwendeten Variablen.
DECLARE purchases_mean DECIMAL(40, 20);
DECLARE money_mean DECIMAL(40, 20);
DECLARE alpha DECIMAL(40, 20);
DECLARE beta DECIMAL(40, 20);

-- Erstelle eine temporäre Tabelle für die zu verwendenden Datenpunkte.
DROP TEMPORARY TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  purchases INT(11),
  money INT(11)
);

-- Füge die gewünschte Anzahl der Datenpunkte in die temporäre Tabelle ein.
INSERT INTO datapoints
SELECT purchases, money
FROM sample
LIMIT number_datapoints;

-- Berechne die Mittelwerte der abhängigen und unabhängigen Variable.
SET purchases_mean = (
  SELECT AVG(purchases)
  FROM datapoints
);
SET money_mean = (
  SELECT AVG(money)
  FROM datapoints
);

-- Berechne beta.
SET beta = (
  SELECT SUM((purchases - purchases_mean) * (money - money_mean))
  FROM datapoints
);
SET beta = beta / (
  SELECT SUM(POWER(purchases - purchases_mean, 2))
  FROM datapoints
);

-- Berechne alpha.
SET alpha = money_mean - (beta * purchases_mean);

-- Gib eine Tabelle mit Parametername und zugehörigem Wert zurück.
SELECT 'alpha' AS `variable`, alpha AS `value`
UNION
SELECT 'beta' AS `variable`, beta AS `value`;

-- Lösche die temporäre Tabelle mit den Datenpunkten wieder.
DROP TEMPORARY TABLE IF EXISTS datapoints;

END;;

DELIMITER ;
