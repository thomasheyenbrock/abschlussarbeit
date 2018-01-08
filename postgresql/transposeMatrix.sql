-- main procedure for regression analysis
CREATE OR REPLACE FUNCTION transpose_matrix(a INTEGER[][])
RETURNS INTEGER[][] AS $$
DECLARE
  rows_a INTEGER := array_length(a, 1);
  columns_a INTEGER := array_length(a, 2);
  i INTEGER;
  j INTEGER;
  c INTEGER[][];
  new_row INTEGER[];
BEGIN

i := 1;

WHILE i <= columns_a LOOP

  j := 1;

  WHILE j <= rows_a LOOP

    new_row[j] := a[j][i];

    j := j + 1;

  END LOOP;

  c := array_cat(c, array[new_row]);

  i := i + 1;

END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;
