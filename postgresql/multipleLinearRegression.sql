-- Erstelle Funktion für die Berechnung der transponierten Matrix.
CREATE OR REPLACE FUNCTION matrix_transpose(a NUMERIC(65, 30)[][])
RETURNS NUMERIC(65, 30)[][] AS $$
DECLARE
  rows_a INTEGER := array_length(a, 1);
  columns_a INTEGER := array_length(a, 2);
  i INTEGER;
  j INTEGER;
  c NUMERIC(65, 30)[][];
  new_row NUMERIC(65, 30)[];
BEGIN

-- Iteriere über alle Zeilen und Spalten der ursprüglichen Matrix.
i := 1;
WHILE i <= columns_a LOOP

  j := 1;
  WHILE j <= rows_a LOOP
    -- Erzeuge ein Array mit der neuen Zeile der transponierten Matrix aus der Spalte der ursprünglichen Matrix.
    new_row[j] := a[j][i];
    j := j + 1;
  END LOOP;

  -- Füge die Zeile in die Ergebnismatrix ein.
  c := array_cat(c, array[new_row]);
  i := i + 1;
END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- Erstelle Funktion für die Berechnung des Produktes zweier Matrizen.
CREATE OR REPLACE FUNCTION matrix_multiplication(a NUMERIC(65, 30)[][], b NUMERIC(65, 30)[][])
RETURNS NUMERIC(65, 30)[][] AS $$
DECLARE
  rows_a INTEGER := array_length(a, 1);
  columns_a INTEGER := array_length(a, 2);
  columns_b INTEGER := array_length(b, 2);
  new_row NUMERIC(65, 30)[];
  c NUMERIC(65, 30)[][];
  counter_1 INTEGER;
  counter_2 INTEGER;
  counter_3 INTEGER;
BEGIN

-- Iteriere über die Zeilen und Spalten der Ergebnismatrix.
counter_1 := 1;
WHILE counter_1 <= rows_a LOOP

  counter_2 := 1;
  WHILE counter_2 <= columns_b LOOP

    -- Initiiere den Wert des aktuellen Elementes der Ergebnismatrix mit 0.
    new_row[counter_2] := 0;

    -- Iteriere über die Summanden zur Berechnung des aktuellen Matrixelements.
    counter_3 := 1;
    WHILE counter_3 <= columns_a LOOP
      -- Addiere den aktuellen Summanden zum Wert des aktuellen Elementes.
      new_row[counter_2] := new_row[counter_2] + a[counter_1][counter_3] * b[counter_3][counter_2];
      counter_3 := counter_3 + 1;
    END LOOP;

    counter_2 := counter_2 + 1;
  END LOOP;

  c := array_cat(c, array[new_row]);
  counter_1 := counter_1 + 1;
END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- Erstelle Funktion für die Berechnung der inversen Matrix.
CREATE OR REPLACE FUNCTION matrix_inversion(a NUMERIC(65, 30)[][])
RETURNS NUMERIC(65, 30)[][] AS $$
DECLARE
  n INTEGER := array_length(a, 1);
  p INTEGER := 0;
  i INTEGER;
  j INTEGER;
  c NUMERIC(65, 30)[][] := a;
  o NUMERIC(65, 30)[][];
BEGIN

-- Verwende den in der Arbeit referenzierten Algorithmus.
WHILE p < n LOOP

  p := p + 1;

  o := c;

  j := 1;
  WHILE j <= n LOOP
    IF j <> p THEN
      c[p][j] := c[p][j] / c[p][p];
    END IF;
    j := j + 1;
  END LOOP;

  i := 1;
  WHILE i <= n LOOP
    IF i <> p THEN
      c[i][p] := - c[i][p] / c[p][p];
    END IF;
    i := i + 1;
  END LOOP;

  i := 1;
  WHILE i <= n LOOP
    IF i <> p THEN
      j := 1;
      WHILE j <= n LOOP
        IF j <> p THEN
          c[i][j] := c[i][j] + o[p][j] * c[i][p];
        END IF;
        j := j + 1;
      END LOOP;
    END IF;
    i := i + 1;
  END LOOP;

  c[p][p] := 1 / c[p][p];

END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- Erstelle die Funktion für multiple lineare Regression.
CREATE OR REPLACE FUNCTION multiple_linear_regression(number_datapoints INTEGER)
RETURNS TABLE (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
) AS $$
DECLARE
  -- Erzeuge die Matrix X mit der gewünschten Anzahl an Datenpunkten.
  x INTEGER[][]:= (
    SELECT ARRAY(
      SELECT ARRAY[1, purchases, age]
      FROM sample
      LIMIT number_datapoints
    )
  );
  -- Erzeuge die Matrix y mit der gewünschten Anzahl an Datenpunkten.
  y INTEGER[]:= (
    SELECT ARRAY(
      SELECT ARRAY[money]
      FROM sample
      LIMIT number_datapoints
    )
  );
  b NUMERIC(65, 30)[][];
BEGIN

-- Berechne die Lösungsformel unter Verwendung der zuvor definierten Funktionen.
b := matrix_multiplication(
  matrix_inversion(
    matrix_multiplication(
      matrix_transpose(x),
      x
    )
  ),
  matrix_multiplication(
    matrix_transpose(x),
    y
  )
);

-- Gib eine Relation mit Parameternamen und zugehörigen Werten zurück.
RETURN QUERY
SELECT 'alpha'::VARCHAR(50) AS variable, b[1][1] AS value
UNION
SELECT 'beta_purchases'::VARCHAR(50) AS variable, b[2][1] AS value
UNION
SELECT 'beta_age'::VARCHAR(50) AS variable, b[3][1] AS value;

END;
$$ LANGUAGE plpgsql;
