-- drop possibly existing procedures
DROP PROCEDURE IF EXISTS multiple_linear_regression;

DELIMITER ;;

-- main procedure for regression analysis
CREATE PROCEDURE multiple_linear_regression(IN number_datapoints INT(11))
BEGIN

-- declare variables
DECLARE m INT(11);
DECLARE n INT(11);
DECLARE counter_1 INT(11);
DECLARE counter_2 INT(11);
DECLARE counter_3 INT(11);
DECLARE pivot DECIMAL(65, 30);

-- set matrix dimensions
SET m = number_datapoints;
SET n = 3;

-- drop temporary tables if existing
DROP TEMPORARY TABLE IF EXISTS matrix_X;
DROP TEMPORARY TABLE IF EXISTS matrix_transposed;
DROP TEMPORARY TABLE IF EXISTS matrix_product_1;
DROP TEMPORARY TABLE IF EXISTS matrix_inverse;
DROP TEMPORARY TABLE IF EXISTS matrix_product_2;
DROP TEMPORARY TABLE IF EXISTS matrix_y;
DROP TEMPORARY TABLE IF EXISTS matrix_result;

-- create temporary tables
CREATE TEMPORARY TABLE matrix_X (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_transposed (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_product_1 (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_inverse (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_product_2 (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_y (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);
CREATE TEMPORARY TABLE matrix_result (
  `row` INT(11),
  `column` INT(11),
  `value` DECIMAL(65, 30)
);

-- insert constant values in matrix_X
SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  1 AS `column`,
  1 AS `value`
FROM sample
LIMIT number_datapoints;

-- insert values for purchases in matrix_X
SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  2 AS `column`,
  purchases AS `value`
FROM sample
LIMIT number_datapoints;

-- insert values for age in matrix_X
SET @id = 0;

INSERT INTO matrix_X
SELECT
  @id := (@id + 1) AS `row`,
  3 AS `column`,
  age AS `value`
FROM sample
LIMIT number_datapoints;

-- insert values for money in matrix_y
SET @id = 0;

INSERT INTO matrix_y
SELECT
  @id := (@id + 1) AS `row`,
  1 AS `column`,
  money AS `value`
FROM sample
LIMIT number_datapoints;

-- calculate matrix_transposed
INSERT INTO matrix_transposed
SELECT
  `column` AS `row`,
  `row` AS `column`,
  `value` AS `value`
FROM matrix_X;

-- calculate Matrix_Product1
INSERT INTO matrix_product_1
SELECT
  matrix_transposed.`row`,
  matrix_X.`column`,
  SUM(matrix_transposed.`value` * matrix_X.`value`)
FROM matrix_transposed, matrix_X
WHERE matrix_transposed.`column` = matrix_X.`row`
GROUP BY matrix_transposed.`row`, matrix_X.`column`;

-- calculate matrix_inverse
INSERT INTO matrix_inverse
SELECT *
FROM matrix_product_1;

SET counter_1 = 0;

WHILE counter_1 < n DO

  SET counter_1 = counter_1 + 1;

  DROP TEMPORARY TABLE IF EXISTS pivot_row;
  CREATE TEMPORARY TABLE pivot_row (
      `column` INT(11),
      `value` DECIMAL(65, 30)
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

-- calculate matrix_product_2
INSERT INTO matrix_product_2
SELECT
  matrix_transposed.`row`,
  matrix_y.`column`,
  SUM(matrix_transposed.`value` * matrix_y.`value`)
FROM matrix_transposed, matrix_y
WHERE matrix_transposed.`column` = matrix_y.`row`
GROUP BY matrix_transposed.`row`, matrix_y.`column`;

-- calculate matrix_result
INSERT INTO matrix_result
SELECT
  matrix_inverse.`row`,
  matrix_product_2.`column`,
  SUM(matrix_inverse.`value` * matrix_product_2.`value`)
FROM matrix_inverse, matrix_product_2
WHERE matrix_inverse.`column` = matrix_product_2.`row`
GROUP BY matrix_inverse.`row`, matrix_product_2.`column`;

SELECT
  CASE row
    WHEN 1 THEN 'alpha'
    WHEN 2 THEN 'beta_purchases'
    WHEN 3 THEN 'beta_age'
  END AS `variable`,
  value
FROM matrix_result;

END;;

DELIMITER ;
