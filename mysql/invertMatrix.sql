DROP PROCEDURE IF EXISTS Main;

DELIMITER ;;
CREATE PROCEDURE `Main`()
BEGIN

DECLARE counter INT(11);
DECLARE counter2 INT(11);
DECLARE counter3 INT(11);
DECLARE pivot DECIMAL(40, 20);
DECLARE dimensions INT(11);

SET dimensions = 2;

DROP TEMPORARY TABLE IF EXISTS Matrix;
CREATE TEMPORARY TABLE Matrix (
    `Row` INT(11),
    `Column` INT(11),
    `Value` DECIMAL(40, 20)
);

INSERT INTO Matrix VALUES
    (1, 1, 1),
    (1, 2, 0),
    (2, 1, 0),
    (2, 2, 1);

SET counter = 0;

WHILE counter < dimensions DO

    SET counter = counter + 1;

    DROP TEMPORARY TABLE IF EXISTS PivotRow;
    CREATE TEMPORARY TABLE PivotRow (
        `Column` INT(11),
        `Value` DECIMAL(40, 20)
    );

    INSERT INTO PivotRow
    SELECT `Column`, `Value`
    FROM Matrix
    WHERE `Row` = counter;

    SET pivot = (
        SELECT `Value`
        FROM Matrix
        WHERE `Row` = counter AND `Column` = counter
    );

    UPDATE Matrix
    SET `Value` = `Value` / pivot
    WHERE `Row` = counter AND `Column` <> counter;

    UPDATE Matrix
    SET `Value` = - `Value` / pivot
    WHERE `Row` <> counter AND `Column` = counter;

    SET counter2 = 1;

    WHILE counter2 <= dimensions DO

        IF counter2 <> counter THEN

            SET counter3 = 1;

            WHILE counter3 <= dimensions DO

                IF counter3 <> counter THEN

                    SET pivot = (
                        SELECT `Value`
                        FROM PivotRow
                        WHERE `Column` = counter3
                    ) * (
                        SELECT `Value`
                        FROM Matrix
                        WHERE `Row` = counter2 AND `Column` = counter
                    );

                    UPDATE Matrix
                    SET `Value` = `Value` + pivot
                    WHERE `Row` = counter2 AND `Column` = counter3;

                END IF;

                SET counter3 = counter3 + 1;

            END WHILE;

        END IF;

        SET counter2 = counter2 + 1;

    END WHILE;

    UPDATE Matrix
    SET `Value` = 1 / `Value`
    WHERE `Row` = counter AND `Column` = counter;

END WHILE;

SELECT * FROM Matrix;

END;;
DELIMITER ;

CALL Main();
