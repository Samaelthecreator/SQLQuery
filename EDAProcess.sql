--Realizaremos una query general para el proceso de exploración, previo a la transformación.
--La tabla en este contexto es: marzo2024
SELECT * FROM marzo2024
							--Dimension del dataframe
--numero de registros en la tabla;
SELECT COUNT(*) AS num_registros FROM marzo2024; 
--numero de campos (columnas) en la tabla;
SELECT COUNT(*) AS num_columnas FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'marzo2024';

--Tipos de datos de cada columna
DO $$
DECLARE 
    tipo_dato VARCHAR;
    nombre_columna VARCHAR;
    columnas_cursor CURSOR FOR
        SELECT column_name, data_type 
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'marzo2024';
    columna_rec RECORD;
BEGIN
    OPEN columnas_cursor;
    LOOP
        FETCH columnas_cursor INTO columna_rec;
        EXIT WHEN NOT FOUND;
        
        nombre_columna := columna_rec.column_name;
        tipo_dato := columna_rec.data_type;
        
        RAISE NOTICE 'Columna: %, Tipo de dato: %', nombre_columna, tipo_dato;
    END LOOP;
    CLOSE columnas_cursor;
END;
$$;

-------------
--Existen Primary & Foreign Key?


------------- Espacios en blanco --------------
--para un campo
SELECT COUNT(folio), folio AS folio_null_values FROM marzo2024
WHERE folio IS NULL
GROUP BY folio;

--todos los campos

DO $$
	DECLARE
	columna_actual VARCHAR;
	valores_nulos INTEGER;
BEGIN	
	FOR columna_actual IN 
		SELECT column_name 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'marzo2024'
		
	LOOP 
		EXECUTE 'SELECT COUNT (*) FROM marzo2024 WHERE ' || columna_actual || ' IS NULL'
		INTO valores_nulos;
	
		raise notice 'columna: % , valores nulos: %', columna_actual, valores_nulos;
	END LOOP;
	
END;
$$;		--Podemos eficientizar utilizando un condicional para que muestre unicamente los campos que SI tienen valores nulos