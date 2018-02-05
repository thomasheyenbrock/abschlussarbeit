-- Lösche die bestehenden Prozeduren, falls vorhanden.
DROP PROCEDURE IF EXISTS calculate_gradient;
DROP PROCEDURE IF EXISTS calculate_new_parameters;
DROP PROCEDURE IF EXISTS calculate_logit;
DROP PROCEDURE IF EXISTS are_new_parameters_better;
DROP PROCEDURE IF EXISTS logistic_regression;

DELIMITER ;;
-- Erstelle eine Prozedur zur Berechnung der Werte der logistischen Funktion.
CREATE PROCEDURE `calculate_logit`()
BEGIN

-- Deklariere die benötigten Variablen.
DECLARE alpha_old DECIMAL(65, 30);
DECLARE alpha_new DECIMAL(65, 30);

-- Bestimme den alten und neuen Wert von alpha.
SET alpha_old = (
  SELECT old
  FROM parameters
  WHERE variable = 'alpha'
);
SET alpha_new = (
  SELECT new
  FROM parameters
  WHERE variable = 'alpha'
);

-- Berechne die Werte der logistischen Funktion für alle Datenpunkte.
DELETE FROM logits;
INSERT INTO logits
  SELECT
    d.id,
    1 / (1 + exp(- SUM(d.value * p.old) - alpha_old)) AS `old`,
    1 / (1 + exp(- SUM(d.value * p.new) - alpha_new)) AS `new`
  FROM datapoints d
  JOIN parameters p ON p.variable = d.variable
  GROUP BY d.id;

END;;

-- Erstelle eine Prozedur zur Berechnung des Gradienten.
CREATE PROCEDURE `calculate_gradient`()
BEGIN

DELETE FROM gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO gradient
SELECT 'alpha' AS `variable`, SUM(bv.value - l.old) AS `value`
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO gradient
SELECT d.variable, SUM(d.value * (bv.value - l.old)) AS `value`
FROM logits l
JOIN binary_values bv ON bv.id = l.id
JOIN datapoints d ON d.id = l.id
GROUP BY d.variable;

END;;

-- Erzeuge eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE PROCEDURE `calculate_new_parameters`(IN step DECIMAL(65, 30))
BEGIN

UPDATE parameters
JOIN gradient ON gradient.variable = parameters.variable
SET parameters.new = parameters.old + step * gradient.value;

END;;

-- Erzeuge eine Prozedur, um herauszufinden, ob die neuen Parameterwerte besser sind als die alten.
CREATE PROCEDURE `are_new_parameters_better`(OUT better INT(1))
BEGIN

-- Berechne und vergleiche die Werte der Likelihoodfunktion für die alten und neuen Parameterwerte.
SET better = (
  SELECT
    SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
    SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
  FROM logits l
  JOIN binary_values bv ON bv.id = l.id
);

END;;

-- Erstelle die Prozedur für logistische Regression.
CREATE PROCEDURE `logistic_regression`(IN number_datapoints INT(11), IN rounds INT(11), step DECIMAL(65, 30))
BEGIN

-- Deklariere die verwendeten Variablen.
DECLARE min INT(11);
DECLARE max INT(11);
DECLARE transform DECIMAL(65, 30);
DECLARE better INT(1);
DECLARE counter INT(11);

-- Erstelle eine temporäre Relation für die Werte der unabhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (id, variable)
);

-- Berechne Minimum und Maximum der unabhängigen Variable.
SET min = (SELECT MIN(money) FROM sample);
SET max = (SELECT MAX(money) FROM sample);

-- Füge die linear transformierten Werte der unabhängigen Variablen in die Relation datapoints ein.
SET @counter = 0;
INSERT INTO datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_money' AS `variable`,
  (money - min) / (max - min) AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die (binären) Werte der abhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS binary_values;
CREATE TEMPORARY TABLE binary_values (
  id INT(11),
  value INT(1),
  PRIMARY KEY (id)
);

-- Füge die Werte der abhängingen Variable ein.
SET @counter = 0;
INSERT INTO binary_values
SELECT
  @counter := @counter + 1 AS `id`,
  premium AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die alten und neuen Parameterwerte.
DROP TEMPORARY TABLE IF EXISTS parameters;
CREATE TEMPORARY TABLE parameters (
  variable VARCHAR(32),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- Erstelle eine temporäre Relation für die Werte der logistischen Funktion für alle Datenpunkte.
DROP TEMPORARY TABLE IF EXISTS logits;
CREATE TEMPORARY TABLE logits (
  id INT(11),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (id)
);

-- Befülle die Relation für die Werte der logistischen Funktion.
CALL calculate_logit();

-- Erstelle eine teporäre Relation für den Gradienten.
DROP TEMPORARY TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
SET counter = 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 DO

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  CALL calculate_gradient();
  CALL calculate_new_parameters(step);
  CALL calculate_logit();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE (
    SELECT
      SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
      SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
    FROM logits l
    JOIN binary_values bv ON bv.id = l.id
  ) = 0 AND step > 0.000000000000000000000000000001 DO

    SET step = step / 2;
    CALL calculate_new_parameters(step);
    CALL calculate_logit();

  END WHILE;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE parameters
  SET parameters.old = parameters.new;

  UPDATE logits
  SET logits.old = logits.new;

  SET counter = counter + 1;

END WHILE;

-- Transformiere die Parameter linear, um den originalen Daten zu entsprechen.
UPDATE parameters
SET old = old / (max - min)
WHERE variable = 'beta_money';

SET transform = (SELECT old FROM parameters WHERE variable = 'beta_money');

UPDATE parameters
SET old = old - transform * min
WHERE variable = 'alpha';

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
SELECT variable, old AS `value`
FROM parameters;

-- Lösche die temporären Relationen wieder.
DROP TEMPORARY TABLE IF EXISTS datapoints;
DROP TEMPORARY TABLE IF EXISTS binary_values;
DROP TEMPORARY TABLE IF EXISTS parameters;
DROP TEMPORARY TABLE IF EXISTS logits;
DROP TEMPORARY TABLE IF EXISTS gradient;

END;;
DELIMITER ;
