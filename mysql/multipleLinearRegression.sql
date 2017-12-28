-- drop possibly existing procedures
DROP PROCEDURE IF EXISTS MLinReg_Main;

DELIMITER ;;

-- main procedure for regression analysis
CREATE PROCEDURE MLinReg_Main(IN number_datapoints INT(11))
BEGIN

-- declare variables
DECLARE m INT(11);
DECLARE n INT(11);
DECLARE counter1 INT(11);
DECLARE counter2 INT(11);
DECLARE counter3 INT(11);
DECLARE pivot DECIMAL(40, 20);

-- set matrix dimensions
SET m = number_datapoints;
SET n = 2;

-- drop temporary tables if existing
DROP TEMPORARY TABLE IF EXISTS Matrix_X;
DROP TEMPORARY TABLE IF EXISTS Matrix_Transposed;
DROP TEMPORARY TABLE IF EXISTS Matrix_Product1;
DROP TEMPORARY TABLE IF EXISTS Matrix_Inverse;
DROP TEMPORARY TABLE IF EXISTS Matrix_Product2;
DROP TEMPORARY TABLE IF EXISTS Matrix_y;
DROP TEMPORARY TABLE IF EXISTS Matrix_Result;

-- create temporary tables
CREATE TEMPORARY TABLE Matrix_X (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_Transposed (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_Product1 (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_Inverse (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_Product2 (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_y (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);
CREATE TEMPORARY TABLE Matrix_Result (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);

-- insert constant values in Matrix_X
SET @id = 0;

INSERT INTO Matrix_X
SELECT @id := (@id + 1) AS `Row`, 1 AS `Column`, 1 AS `Value`
FROM regression
LIMIT number_datapoints;

-- insert values for purchases in Matrix_X
SET @id = 0;

INSERT INTO Matrix_X
SELECT @id := (@id + 1) AS `Row`, 2 AS `Column`, purchases AS `Value`
FROM regression
LIMIT number_datapoints;

-- insert values for money in Matrix_y
SET @id = 0;

INSERT INTO Matrix_y
SELECT @id := (@id + 1) AS `Row`, 1 AS `Column`, money AS `Value`
FROM regression
LIMIT number_datapoints;

-- calculate Matrix_Transposed
INSERT INTO Matrix_Transposed
SELECT `Column` AS `Row`, `Row` AS `Column`, `Value` AS `Value`
FROM Matrix_X;

-- calculate Matrix_Product1
SET counter1 = 1;

WHILE counter1 <= n DO

    SET counter2 = 1;

    WHILE counter2 <= n DO

        INSERT INTO Matrix_Product1 VALUES (
            counter1,
            counter2,
            (
                SELECT SUM(T1.`Value` * T2.`Value`)
                FROM (
                    SELECT * FROM Matrix_X WHERE `Column` = counter2
                ) T1
                JOIN (
                    SELECT * FROM Matrix_Transposed WHERE `Row` = counter1
                ) T2
                ON T2.`Column` = T1.`Row`
            )
        );

        SET counter2 = counter2 + 1;

    END WHILE;

    SET counter1 = counter1 + 1;

END WHILE;

-- calculate Matrix_Inverse
INSERT INTO Matrix_Inverse
SELECT *
FROM Matrix_Product1;

SET counter1 = 0;

WHILE counter1 < n DO

    SET counter1 = counter1 + 1;

    DROP TEMPORARY TABLE IF EXISTS PivotRow;
    CREATE TEMPORARY TABLE PivotRow (
        `Column` INT(11),
        `Value` DECIMAL(40, 20)
    );

    INSERT INTO PivotRow
    SELECT `Column`, `Value`
    FROM Matrix_Inverse
    WHERE `Row` = counter1;

    SET pivot = (
        SELECT `Value`
        FROM Matrix_Inverse
        WHERE `Row` = counter1 AND `Column` = counter1
    );

    UPDATE Matrix_Inverse
    SET `Value` = `Value` / pivot
    WHERE `Row` = counter1 AND `Column` <> counter1;

    UPDATE Matrix_Inverse
    SET `Value` = - `Value` / pivot
    WHERE `Row` <> counter1 AND `Column` = counter1;

    SET counter2 = 1;

    WHILE counter2 <= n DO

        IF counter2 <> counter1 THEN

            SET counter3 = 1;

            WHILE counter3 <= n DO

                IF counter3 <> counter1 THEN

                    SET pivot = (
                        SELECT `Value`
                        FROM PivotRow
                        WHERE `Column` = counter3
                    ) * (
                        SELECT `Value`
                        FROM Matrix_Inverse
                        WHERE `Row` = counter2 AND `Column` = counter1
                    );

                    UPDATE Matrix_Inverse
                    SET `Value` = `Value` + pivot
                    WHERE `Row` = counter2 AND `Column` = counter3;

                END IF;

                SET counter3 = counter3 + 1;

            END WHILE;

        END IF;

        SET counter2 = counter2 + 1;

    END WHILE;

    UPDATE Matrix_Inverse
    SET `Value` = 1 / `Value`
    WHERE `Row` = counter1 AND `Column` = counter1;

END WHILE;

-- calculate Matrix_Product2
SET counter1 = 1;

WHILE counter1 <= n DO

    SET counter2 = 1;

    WHILE counter2 <= m DO

        INSERT INTO Matrix_Product2 VALUES (
            counter1,
            counter2,
            (
                SELECT SUM(T1.`Value` * T2.`Value`)
                FROM (
                    SELECT * FROM Matrix_Transposed WHERE `Column` = counter2
                ) T1
                JOIN (
                    SELECT * FROM Matrix_Inverse WHERE `Row` = counter1
                ) T2
                ON T2.`Column` = T1.`Row`
            )
        );

        SET counter2 = counter2 + 1;

    END WHILE;

    SET counter1 = counter1 + 1;

END WHILE;

-- calculate Matrix_Result
SET counter1 = 1;

WHILE counter1 <= n DO

    INSERT INTO Matrix_Result VALUES (
        counter1,
        1,
        (
            SELECT SUM(T1.`Value` * T2.`Value`)
            FROM (
                SELECT * FROM Matrix_y
            ) T1
            JOIN (
                SELECT * FROM Matrix_Product2 WHERE `Row` = counter1
            ) T2
            ON T2.`Column` = T1.`Row`
        )
    );

    SET counter1 = counter1 + 1;

END WHILE;

SELECT * FROM Matrix_Result;

END;;

DELIMITER ;

-- execute main procedure
CALL MLinReg_Main(100000);
