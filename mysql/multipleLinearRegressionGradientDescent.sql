-- Lösche die bestehenden Prozeduren, falls vorhanden.
DROP PROCEDURE IF EXISTS mlr_calculate_gradient;
DROP PROCEDURE IF EXISTS mlr_calculate_new_parameters;
DROP PROCEDURE IF EXISTS mlr_calculate_linears;
DROP PROCEDURE IF EXISTS multiple_linear_regression_gradient_descent;

DELIMITER ;;
-- Erstelle eine Prozedur zur Berechnung der linearen Funktion.
CREATE PROCEDURE `mlr_calculate_linears`()
BEGIN

-- Deklariere die benötigten Variablen.
DECLARE alpha_old DECIMAL(65, 30);
DECLARE alpha_new DECIMAL(65, 30);

-- Bestimme den alten und neuen Wert von alpha.
SET alpha_old = (
  SELECT old
  FROM mlr_parameters
  WHERE variable = 'alpha'
);
SET alpha_new = (
  SELECT new
  FROM mlr_parameters
  WHERE variable = 'alpha'
);

-- Berechne die lineare Funktion für alle Datenpunkte.
DELETE FROM mlr_linears;
INSERT INTO mlr_linears
  SELECT
    d.id,
    SUM(d.value * p.old) + alpha_old AS `old`,
    SUM(d.value * p.new) + alpha_new AS `new`
  FROM mlr_datapoints d
  JOIN mlr_parameters p ON p.variable = d.variable
  GROUP BY d.id;

END;;

-- Erstelle eine Prozedur zur Berechnung des Gradienten.
CREATE PROCEDURE `mlr_calculate_gradient`()
BEGIN

DELETE FROM gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO gradient
SELECT 'alpha' AS `variable`, - 2 * SUM(bv.value - l.old) AS `value`
FROM mlr_linears l
JOIN mlr_binary_values bv ON bv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO gradient
SELECT d.variable, - 2 * SUM(d.value * (bv.value - l.old)) AS `value`
FROM mlr_linears l
JOIN mlr_binary_values bv ON bv.id = l.id
JOIN mlr_datapoints d ON d.id = l.id
GROUP BY d.variable;

END;;

-- Erzeuge eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE PROCEDURE `mlr_calculate_new_parameters`(IN step DECIMAL(65, 30))
BEGIN

UPDATE mlr_parameters
JOIN gradient ON gradient.variable = mlr_parameters.variable
SET mlr_parameters.new = mlr_parameters.old - step * gradient.value;

END;;

-- Erstelle die Prozedur für lineare Regression mit Verwendung des Gradientenverfahrens.
CREATE PROCEDURE `multiple_linear_regression_gradient_descent`(IN number_datapoints INT(11), IN rounds INT(11), step DECIMAL(65, 30))
BEGIN

-- Deklariere die verwendeten Variablen.
DECLARE counter INT(11);

-- Erstelle eine temporäre Relation für die Werte der unabhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS mlr_datapoints;
CREATE TEMPORARY TABLE mlr_datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (id, variable)
);

-- Füge Werte der unabhängigen Variablen in die Relation mlr_datapoints ein.
SET @counter = 0;
INSERT INTO mlr_datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_purchases' AS `variable`,
  purchases AS `value`
FROM sample
LIMIT number_datapoints;

SET @counter = 0;
INSERT INTO mlr_datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_age' AS `variable`,
  age AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die (binären) Werte der abhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS mlr_binary_values;
CREATE TEMPORARY TABLE mlr_binary_values (
  id INT(11),
  value INT(1),
  PRIMARY KEY (id)
);

-- Füge die Werte der abhängingen Variable ein.
SET @counter = 0;
INSERT INTO mlr_binary_values
SELECT
  @counter := @counter + 1 AS `id`,
  money AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die alten und neuen Parameterwerte.
DROP TEMPORARY TABLE IF EXISTS mlr_parameters;
CREATE TEMPORARY TABLE mlr_parameters (
  variable VARCHAR(32),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO mlr_parameters VALUES
  ('alpha', 0, 0),
  ('beta_purchases', 0, 0),
  ('beta_age', 0, 0);

-- Erstelle eine temporäre Relation für die Werte der linearen Funktion für alle Datenpunkte.
DROP TEMPORARY TABLE IF EXISTS mlr_linears;
CREATE TEMPORARY TABLE mlr_linears (
  id INT(11),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (id)
);

-- Befülle die Relation für die Werte der linearen Funktion.
CALL mlr_calculate_linears();

-- Erstelle eine teporäre Relation für den Gradienten.
DROP TEMPORARY TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

DROP TEMPORARY TABLE IF EXISTS debug;
CREATE TEMPORARY TABLE debug (
  round INT(11),
  step DECIMAL(65, 30)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
SET counter = 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 DO

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  CALL mlr_calculate_gradient();
  CALL mlr_calculate_new_parameters(step);
  CALL mlr_calculate_linears();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE (
    SELECT
      SUM(POWER(bv.value - l.new, 2)) <
      SUM(POWER(bv.value - l.old, 2))
    FROM mlr_linears l
    JOIN mlr_binary_values bv ON bv.id = l.id
  ) = 0 AND step > 0.000000000000000000000000000001 DO

    SET step = step / 2;
    INSERT INTO debug VALUES (counter, step);
    CALL mlr_calculate_new_parameters(step);
    CALL mlr_calculate_linears();

  END WHILE;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE mlr_parameters
  SET mlr_parameters.old = mlr_parameters.new;

  UPDATE mlr_linears
  SET mlr_linears.old = mlr_linears.new;

  SET counter = counter + 1;

END WHILE;

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
SELECT variable, old AS `value`
FROM mlr_parameters;

-- Lösche die temporären Relationen wieder.
-- DROP TEMPORARY TABLE IF EXISTS mlr_datapoints;
-- DROP TEMPORARY TABLE IF EXISTS mlr_binary_values;
-- DROP TEMPORARY TABLE IF EXISTS mlr_parameters;
-- DROP TEMPORARY TABLE IF EXISTS mlr_linears;
-- DROP TEMPORARY TABLE IF EXISTS gradient;

END;;
DELIMITER ;

CALL multiple_linear_regression_gradient_descent(10, 10, 1);
