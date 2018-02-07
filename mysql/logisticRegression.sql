-- Lösche die bestehenden Prozeduren, falls vorhanden.
DROP PROCEDURE IF EXISTS lr_calculate_gradient;
DROP PROCEDURE IF EXISTS lr_calculate_new_parameters;
DROP PROCEDURE IF EXISTS lr_calculate_logit;
DROP PROCEDURE IF EXISTS logistic_regression;

DELIMITER ;;
-- Erstelle eine Prozedur zur Berechnung der Werte der logistischen Funktion.
CREATE PROCEDURE `lr_calculate_logit`()
BEGIN

-- Deklariere die benötigten Variablen.
DECLARE alpha_old DECIMAL(65, 30);
DECLARE alpha_new DECIMAL(65, 30);

-- Bestimme den alten und neuen Wert von alpha.
SET alpha_old = (
  SELECT old
  FROM lr_parameters
  WHERE variable = 'alpha'
);
SET alpha_new = (
  SELECT new
  FROM lr_parameters
  WHERE variable = 'alpha'
);

-- Berechne die Werte der logistischen Funktion für alle Datenpunkte.
DELETE FROM lr_logits;
INSERT INTO lr_logits
  SELECT
    d.id,
    1 / (1 + exp(- SUM(d.value * p.old) - alpha_old)) AS `old`,
    1 / (1 + exp(- SUM(d.value * p.new) - alpha_new)) AS `new`
  FROM lr_datapoints d
  JOIN lr_parameters p ON p.variable = d.variable
  GROUP BY d.id;

END;;

-- Erstelle eine Prozedur zur Berechnung des Gradienten.
CREATE PROCEDURE `lr_calculate_gradient`()
BEGIN

DELETE FROM lr_gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO lr_gradient
SELECT 'alpha' AS `variable`, SUM(dv.value - l.old) AS `value`
FROM lr_logits l
JOIN lr_dependent_values dv ON dv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO lr_gradient
SELECT d.variable, SUM(d.value * (dv.value - l.old)) AS `value`
FROM lr_logits l
JOIN lr_dependent_values dv ON dv.id = l.id
JOIN lr_datapoints d ON d.id = l.id
GROUP BY d.variable;

END;;

-- Erzeuge eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE PROCEDURE `lr_calculate_new_parameters`(IN step DECIMAL(65, 30))
BEGIN

UPDATE lr_parameters
JOIN lr_gradient ON lr_gradient.variable = lr_parameters.variable
SET lr_parameters.new = lr_parameters.old + step * lr_gradient.value;

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
DROP TEMPORARY TABLE IF EXISTS lr_datapoints;
CREATE TEMPORARY TABLE lr_datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (id, variable)
);

-- Berechne Minimum und Maximum der unabhängigen Variable.
SET min = (SELECT MIN(money) FROM sample);
SET max = (SELECT MAX(money) FROM sample);

-- Füge die linear transformierten Werte der unabhängigen Variablen in die Relation lr_datapoints ein.
SET @counter = 0;
INSERT INTO lr_datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_money' AS `variable`,
  (money - min) / (max - min) AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die (binären) Werte der abhängigen Variablen.
DROP TEMPORARY TABLE IF EXISTS lr_dependent_values;
CREATE TEMPORARY TABLE lr_dependent_values (
  id INT(11),
  value INT(1),
  PRIMARY KEY (id)
);

-- Füge die Werte der abhängingen Variable ein.
SET @counter = 0;
INSERT INTO lr_dependent_values
SELECT
  @counter := @counter + 1 AS `id`,
  premium AS `value`
FROM sample
LIMIT number_datapoints;

-- Erstelle eine temporäre Relation für die alten und neuen Parameterwerte.
DROP TEMPORARY TABLE IF EXISTS lr_parameters;
CREATE TEMPORARY TABLE lr_parameters (
  variable VARCHAR(32),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO lr_parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- Erstelle eine temporäre Relation für die Werte der logistischen Funktion für alle Datenpunkte.
DROP TEMPORARY TABLE IF EXISTS lr_logits;
CREATE TEMPORARY TABLE lr_logits (
  id INT(11),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (id)
);

-- Befülle die Relation für die Werte der logistischen Funktion.
CALL lr_calculate_logit();

-- Erstelle eine teporäre Relation für den Gradienten.
DROP TEMPORARY TABLE IF EXISTS lr_gradient;
CREATE TEMPORARY TABLE lr_gradient (
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
SET counter = 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 DO

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  CALL lr_calculate_gradient();
  CALL lr_calculate_new_parameters(step);
  CALL lr_calculate_logit();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE (
    SELECT
      SUM(LOG(dv.value * l.new + (1 - dv.value) * (1 - l.new))) >
      SUM(LOG(dv.value * l.old + (1 - dv.value) * (1 - l.old)))
    FROM lr_logits l
    JOIN lr_dependent_values dv ON dv.id = l.id
  ) = 0 AND step > 0.000000000000000000000000000001 DO

    SET step = step / 2;
    CALL lr_calculate_new_parameters(step);
    CALL lr_calculate_logit();

  END WHILE;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE lr_parameters
  SET lr_parameters.old = lr_parameters.new;

  UPDATE lr_logits
  SET lr_logits.old = lr_logits.new;

  SET counter = counter + 1;

END WHILE;

-- Transformiere die Parameter linear, um den originalen Daten zu entsprechen.
UPDATE lr_parameters
SET old = old / (max - min)
WHERE variable = 'beta_money';

SET transform = (SELECT old FROM lr_parameters WHERE variable = 'beta_money');

UPDATE lr_parameters
SET old = old - transform * min
WHERE variable = 'alpha';

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
SELECT variable, old AS `value`
FROM lr_parameters;

-- Lösche die temporären Relationen wieder.
DROP TEMPORARY TABLE IF EXISTS lr_datapoints;
DROP TEMPORARY TABLE IF EXISTS lr_dependent_values;
DROP TEMPORARY TABLE IF EXISTS lr_parameters;
DROP TEMPORARY TABLE IF EXISTS lr_logits;
DROP TEMPORARY TABLE IF EXISTS lr_gradient;

END;;
DELIMITER ;
