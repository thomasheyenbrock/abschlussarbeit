-- Lösche die bestehende Prozedur, falls vorhanden.
DROP PROCEDURE IF EXISTS multiple_linear_regression;

DELIMITER ;;

-- Erstelle die Prozedur für multiple lineare Regression.
CREATE PROCEDURE multiple_linear_regression(IN number_datapoints INT(11))
BEGIN

-- Deklariere die verwendeten Variablen.
DECLARE m INT(11);
DECLARE n INT(11);
DECLARE counter_1 INT(11);
DECLARE counter_2 INT(11);
DECLARE counter_3 INT(11);
DECLARE pivot DECIMAL(40, 20);

-- Bestimme die Dimensionsn für die Matrix X.
SET m = number_datapoints;
SET n = 3;

-- Lösche vorhandene temporäre Tabellen.
DROP TEMPORARY TABLE IF EXISTS matrix_X;
DROP TEMPORARY TABLE IF EXISTS matrix_transposed;
DROP TEMPORARY TABLE IF EXISTS matrix_product_1;
DROP TEMPORARY TABLE IF EXISTS matrix_inverse;
DROP TEMPORARY TABLE IF EXISTS matrix_product_2;
DROP TEMPORARY TABLE IF EXISTS matrix_y;
DROP TEMPORARY TABLE IF EXISTS matrix_result;

-- Erstelle temporäre Tabellen für die zu berechnenden Matrizen.
CREATE TEMPORARY TABLE matrix_X (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_transposed (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_product_1 (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_inverse (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_product_2 (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_y (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE matrix_result (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(40, 20)
);

-- Füge Werte der unabhängigen Variablen in die Tabelle matrix_X ein.
SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  1 AS `column`,
  1 AS `value`
FROM sample
LIMIT number_datapoints;

SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  2 AS `column`,
  purchases AS `value`
FROM sample
LIMIT number_datapoints;

SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  3 AS `column`,
  age AS `value`
FROM sample
LIMIT number_datapoints;

-- Füge Werte der abhängigen Variable in die Tabelle matrix_y ein.
SET @id = 0;

INSERT INTO matrix_y
SELECT
  @id := (@id + 1) AS `row`,
  1 AS `column`,
  money AS `value`
FROM sample
LIMIT number_datapoints;

-- Berechne matrix_transposed.
INSERT INTO matrix_transposed
SELECT
  `column` AS `row`,
  `row` AS `column`,
  `value` AS `value`
FROM matrix_X;

-- Berechne matrix_product_1. Iteriere dazu über alle Zeilen und Spalten der Ergebnismatrix.
SET counter_1 = 1;

WHILE counter_1 <= n DO

  SET counter_2 = 1;

  WHILE counter_2 <= n DO

    -- Berechne den Wert des aktuellen Matrixelements.
    INSERT INTO matrix_product_1 VALUES (
      counter_1,
      counter_2,
      (
        SELECT SUM(matrix_X.`value` * matrix_transposed.`value`)
        FROM matrix_X, matrix_transposed
        WHERE matrix_X.`column` = counter_2
          AND matrix_transposed.`row` = counter_1
          AND matrix_transposed.`column` = matrix_X.`row`
      )
    );

    SET counter_2 = counter_2 + 1;

  END WHILE;

  SET counter_1 = counter_1 + 1;

END WHILE;

-- Berechne matrix_inverse. Verwende dazu den in der Arbeit referenzierten Algorithmus.
INSERT INTO matrix_inverse
SELECT *
FROM matrix_product_1;

SET counter_1 = 0;

WHILE counter_1 < n DO

  SET counter_1 = counter_1 + 1;

  DROP TEMPORARY TABLE IF EXISTS pivot_row;
  CREATE TEMPORARY TABLE pivot_row (
      `column` INT(11),
      `value` DECIMAL(40, 20)
  );

  INSERT INTO pivot_row
  SELECT `column`, `value`
  FROM matrix_inverse
  WHERE `row` = counter_1;

  SET pivot = (
      SELECT `value`
      FROM matrix_inverse
      WHERE `row` = counter_1 AND `column` = counter_1
  );

  UPDATE matrix_inverse
  SET `value` = `value` / pivot
  WHERE `row` = counter_1 AND `column` <> counter_1;

  UPDATE matrix_inverse
  SET `value` = - `value` / pivot
  WHERE `row` <> counter_1 AND `column` = counter_1;

  SET counter_2 = 1;

  WHILE counter_2 <= n DO

    IF counter_2 <> counter_1 THEN

      SET counter_3 = 1;

      WHILE counter_3 <= n DO

        IF counter_3 <> counter_1 THEN

          SET pivot = (
            SELECT `value`
            FROM pivot_row
            WHERE `column` = counter_3
          ) * (
            SELECT `value`
            FROM matrix_inverse
            WHERE `row` = counter_2 AND `column` = counter_1
          );

          UPDATE matrix_inverse
          SET `value` = `value` + pivot
          WHERE `row` = counter_2 AND `column` = counter_3;

        END IF;

        SET counter_3 = counter_3 + 1;

      END WHILE;

    END IF;

    SET counter_2 = counter_2 + 1;

  END WHILE;

  UPDATE matrix_inverse
  SET `value` = 1 / `value`
  WHERE `row` = counter_1 AND `column` = counter_1;

END WHILE;

-- Berechne matrix_product_2. Iteriere dazu über alle Zeilen der Ergebnismatrix.
SET counter_1 = 1;

WHILE counter_1 <= n DO

  -- Berechne den Wert des aktuellen Matrixelements.
  INSERT INTO matrix_product_2 VALUES (
    counter_1,
    1,
    (
      SELECT SUM(matrix_y.`value` * matrix_transposed.`value`)
      FROM matrix_y, matrix_transposed
      WHERE matrix_transposed.`row` = counter_1
        AND matrix_transposed.`column` = matrix_y.`row`
    )
  );

  SET counter_1 = counter_1 + 1;

END WHILE;

-- Berechne matrix_result. Iteriere dazu über alle Zeilen der Ergebnismatrix.
SET counter_1 = 1;

WHILE counter_1 <= n DO

  -- Berechne den Wert des aktuellen Matrixelements.
  INSERT INTO matrix_result VALUES (
    counter_1,
    1,
    (
      SELECT SUM(matrix_product_2.`value` * matrix_inverse.`value`)
      FROM matrix_product_2, matrix_inverse
      WHERE matrix_inverse.`row` = counter_1
        AND matrix_inverse.`column` = matrix_product_2.`row`
    )
  );

  SET counter_1 = counter_1 + 1;

END WHILE;

-- Gib eine Tabelle mit Parameternamen und zugehörigen Werten zurück.
SELECT
  CASE row
    WHEN 1 THEN 'alpha'
    WHEN 2 THEN 'beta_purchases'
    WHEN 3 THEN 'beta_age'
  END AS `variable`,
  value
FROM matrix_result;

-- Lösche die temporären Tabelle wieder.
DROP TEMPORARY TABLE IF EXISTS matrix_X;
DROP TEMPORARY TABLE IF EXISTS matrix_transposed;
DROP TEMPORARY TABLE IF EXISTS matrix_product_1;
DROP TEMPORARY TABLE IF EXISTS matrix_inverse;
DROP TEMPORARY TABLE IF EXISTS matrix_product_2;
DROP TEMPORARY TABLE IF EXISTS matrix_y;
DROP TEMPORARY TABLE IF EXISTS matrix_result;

END;;

DELIMITER ;
