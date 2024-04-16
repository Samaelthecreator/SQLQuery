--Realizaremos una query general para el proceso de exploración, previo a la transformación.
--La tabla en este contexto es: marzo2024
SELECT * FROM marzo2024
							--Dimension del dataframe
SELECT 
	(SELECT COUNT(*) FROM marzo2024 m) AS num_registros, 
	(SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'marzo2024') AS num_columnas;
	
							--Metadata de los objetos:
	/* INFORMATION_SCHEMA:
	Es un esquema el cual muestra información sobre los objetos de las bases de datos (tablas, coolumnas, llaves primarias y foraneas).
	Cumple con los estandares NASI SQL (portabilidad y compatibilidad.)
	-Las vistas son los objetos a los cuales consultar, como ejemplom estan:
			TABLES , COLUMNS , CONSTRAINTS, KEY_COLUMN_USAGE etc.
	*/
SELECT * FROM INFORMATION_SCHEMA.TABLES,INFORMATION_SCHEMA.KEY_COLUMN_USAGE;
	/* pg_catalog:
	Este esquema es unicamente de PostgreSQL y almacena informacion detallada sobre objetos internos de la base de datos,
	como catálogos de sistema, estadísitcas, indices, roles, etc.
	Guarda de forma detallada la implementación de las bases dentro de Postgre, como ejemplos estan: 
		pg_indexes,pg_roles etc.
	*/	
	
SELECT * FROM  pg_indexes, pg_roles

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
					---Espacios en blanco
--para un campo
SELECT COUNT(folio), folio AS folio_null_values FROM marzo2024
WHERE folio IS NULL
GROUP BY folio;
--Todos los campos

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
			IF valores_nulos !=0 THEN
				raise notice 'columna: % , valores nulos: %', columna_actual, valores_nulos;
			ELSE
				
			END IF;
	END LOOP;
	
END;
$$;	

				--Análisis cuántitativos & estadistica general