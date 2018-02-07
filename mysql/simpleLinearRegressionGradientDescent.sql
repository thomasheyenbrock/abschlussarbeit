-- Lösche die bestehenden Prozeduren, falls vorhanden.
DROP PROCEDURE IF EXISTS slr_calculate_gradient;
DROP PROCEDURE IF EXISTS slr_calculate_new_parameters;
DROP PROCEDURE IF EXISTS slr_calculate_linears;
DROP PROCEDURE IF EXISTS simple_linear_regression_gradient_descent;

DELIMITER ;;
-- Erstelle eine Prozedur zur Berechnung der linearen Funktion.
CREATE PROCEDURE `slr_calculate_linears`()
BEGIN

-- Deklariere die benötigten Variablen.
DECLARE alpha_old DECIMAL(65, 30);
DECLARE alpha_new DECIMAL(65, 30);

-- Bestimme den alten und neuen Wert von alpha.
SET alpha_old = (
  SELECT old
  FROM slr_parameters
  WHERE variable = 'alpha'
);
SET alpha_new = (
  SELECT new
  FROM slr_parameters
  WHERE variable = 'alpha'
);

-- Berechne die lineare Funktion für alle Datenpunkte.
DELETE FROM slr_linears;
INSERT INTO slr_linears
  SELECT
    d.id,
    SUM(d.value * p.old) + alpha_old AS `old`,
    SUM(d.value * p.new) + alpha_new AS `new`
  FROM slr_datapoints d
  JOIN slr_parameters p ON p.variable = d.variable
  GROUP BY d.id;

END;;

-- Erstelle eine Prozedur zur Berechnung des Gradienten.
CREATE PROCEDURE `slr_calculate_gradient`()
BEGIN

DELETE FROM slr_gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO slr_gradient
SELECT 'alpha' AS `variable`, - 2 * SUM(dv.value - l.old) AS `value`
FROM slr_linears l
JOIN slr_dependent_values dv ON dv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO slr_gradient
SELECT d.variable, - 2 * SUM(d.value * (dv.value - l.old)) AS `value`
FROM slr_linears l
JOIN slr_dependent_values dv ON dv.id = l.id
JOIN slr_datapoints d ON d.id = l.id
GROUP BY d.variable;

END;;

-- Erzeuge eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE PROCEDURE `slr_calculate_new_parameters`(IN step DECIMAL(65, 30))
BEGIN

UPDATE slr_parameters
JOIN slr_gradient ON slr_gradient.variable = slr_parameters.variable
SET slr_parameters.new = slr_parameters.old - step * slr_gradient.value;

END;;

-- Erstelle die Prozedur für lineare Regression mit Verwendung des Gradientenverfahrens.
CREATE PROCEDURE `simple_linear_regression_gradient_descent`(IN number_datapoints INT(11), IN rounds INT(11), step DECIMAL(65, 30))
BEGIN

-- Deklariere die verwendeten Variablen.
DECLARE counter INT(11);

-- Erstelle eine temporäre Relation für die Werte der unabhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS slr_datapoints;
CREATE TEMPORARY TABLE slr_datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (id, variable)
);

-- Füge Werte der unabhängigen Variablen in die Relation slr_datapoints ein.
SET @counter = 0;
INSERT INTO slr_datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_purchases' AS `variable`,
  purchases AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die (binären) Werte der abhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS slr_dependent_values;
CREATE TEMPORARY TABLE slr_dependent_values (
  id INT(11),
  value INT(1),
  PRIMARY KEY (id)
);

-- Füge die Werte der abhängingen Variable ein.
SET @counter = 0;
INSERT INTO slr_dependent_values
SELECT
  @counter := @counter + 1 AS `id`,
  money AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die alten und neuen Parameterwerte.
DROP TEMPORARY TABLE IF EXISTS slr_parameters;
CREATE TEMPORARY TABLE slr_parameters (
  variable VARCHAR(32),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO slr_parameters VALUES
  ('alpha', 0, 0),
  ('beta_purchases', 0, 0);

-- Erstelle eine temporäre Relation für die Werte der linearen Funktion für alle Datenpunkte.
DROP TEMPORARY TABLE IF EXISTS slr_linears;
CREATE TEMPORARY TABLE slr_linears (
  id INT(11),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (id)
);

-- Befülle die Relation für die Werte der linearen Funktion.
CALL slr_calculate_linears();

-- Erstelle eine teporäre Relation für den Gradienten.
DROP TEMPORARY TABLE IF EXISTS slr_gradient;
CREATE TEMPORARY TABLE slr_gradient (
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
  CALL slr_calculate_gradient();
  CALL slr_calculate_new_parameters(step);
  CALL slr_calculate_linears();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE (
    SELECT
      SUM(POWER(dv.value - l.new, 2)) <
      SUM(POWER(dv.value - l.old, 2))
    FROM slr_linears l
    JOIN slr_dependent_values dv ON dv.id = l.id
  ) = 0 AND step > 0.000000000000000000000000000001 DO

    SET step = step / 2;
    INSERT INTO debug VALUES (counter, step);
    CALL slr_calculate_new_parameters(step);
    CALL slr_calculate_linears();

  END WHILE;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE slr_parameters
  SET slr_parameters.old = slr_parameters.new;

  UPDATE slr_linears
  SET slr_linears.old = slr_linears.new;

  SET counter = counter + 1;

END WHILE;

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
SELECT variable, old AS `value`
FROM slr_parameters;

-- Lösche die temporären Relationen wieder.
DROP TEMPORARY TABLE IF EXISTS slr_datapoints;
DROP TEMPORARY TABLE IF EXISTS slr_dependent_values;
DROP TEMPORARY TABLE IF EXISTS slr_parameters;
DROP TEMPORARY TABLE IF EXISTS slr_linears;
DROP TEMPORARY TABLE IF EXISTS slr_gradient;

END;;
DELIMITER ;
