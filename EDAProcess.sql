
	
	
		
	
	
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

-- Si la columna es tipo intero, flotante o cuántitativa, calculamos las medidas de tendencia central comenzando por:
/*máximo valor, minimimo valor, media, moda y promedio
	despues calculamos: varianza, desviación estándar.
	
*/
--Primeramente creamos u bloque que me guarde en una variable las columnas que son tipo enteros.

DO $$
DECLARE
    metadatos CURSOR FOR 
        SELECT column_name, data_type FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'marzo2024';
    columnas RECORD;
    tipo_datos VARCHAR;
    col VARCHAR;
    columnas_entero VARCHAR[] := ARRAY[]::VARCHAR[];
    consulta_dinamica TEXT;
BEGIN 
    OPEN metadatos;
    LOOP
        FETCH metadatos INTO columnas;
        EXIT WHEN NOT FOUND;
        
        tipo_datos = columnas.data_type;
        col = columnas.column_name;
        
        IF tipo_datos = 'integer' THEN
            columnas_entero := columnas_entero || col;
        END IF;
    END LOOP;

    CLOSE metadatos;

    -- Construir la consulta dinámica para obtener los datos de las columnas tipo entero
    consulta_dinamica := 'CREATE TEMP TABLE resultado_temp AS SELECT ' || array_to_string(columnas_entero, ', ') || ' FROM marzo2024';
    
    -- Ejecutar la consulta dinámica
    EXECUTE consulta_dinamica;

END;
$$;
--la tabla temporal se borra una vez ejecutando otra transacción
--La tabla temporal es resultado_temp
	---Calculamos las medias estadísticas para las columnas enteras;
	
DO $$
DECLARE
    headers CURSOR FOR
        SELECT column_name FROM information_schema.columns
        WHERE table_name = 'resultado_temp';
    encabezados RECORD;
    querie TEXT;
	maximo INT;
	minimo INT;
	promedio INT;
	mediana INT;
	cantidad INT;
BEGIN
    OPEN headers;
    LOOP
        FETCH headers INTO encabezados;
        EXIT WHEN NOT FOUND;
        
        -- Construir la consulta dinámica para calcular las medidas estadísticas
        querie := 'WITH ranges AS (
                        SELECT MAX(' || encabezados.column_name || ') AS max_,
                               MIN(' || encabezados.column_name || ') AS min_			--Bloque independiente correcto
                        FROM resultado_temp
                   ),
                   average AS (
                        SELECT AVG(' || encabezados.column_name || ') AS promedio		--Bloque independiente correcto
                        FROM resultado_temp
                   ),
                   median AS (
                        SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ' || encabezados.column_name || ') AS mediana
                        FROM resultado_temp					--Bloque independiente correcto
                   ),
                   trend AS (
                        SELECT ' || encabezados.column_name || ' AS columna,
                               COUNT(' || encabezados.column_name || ') AS contador		--Bloque independiente correcto
                        FROM resultado_temp												--se repiten valores máximos
                        GROUP BY ' || encabezados.column_name || '
                   )
                   SELECT ranges.max_ AS maximo, ranges.min_ AS minimo,
                          average.promedio AS promedio, median.mediana AS mediana,
                          MAX(trend.contador) AS cantidad
                   FROM ranges, average, median, trend
				   GROUP BY maximo, minimo, promedio, mediana;';

        -- Ejecutar la consulta dinámica
        EXECUTE querie INTO maximo, minimo, promedio, mediana, cantidad;
        
        -- Realizar operaciones o mostrar resultados según necesites
        RAISE NOTICE 'Para la columna %: Maximo: %, Minimo: %, Promedio: %, Mediana: %, Cantidad: %',
                     encabezados.column_name, maximo, minimo, promedio, mediana, cantidad;
    END LOOP;
    CLOSE headers;
END;
$$; --Se optimizaria más en ves de obtener la información en raise notice, en una tabla temporal.

--Variables centrales

SELECT( SELECT MAX(peso) AS max_kg, MIN(peso) AS min_kg FROM marzo2024 			--rangos
	   	SELECT AVG(peso) AS Promedio FROM marzo2024					--promedios		
		SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peso) AS mediana FROM marzo2024;	--mediana
	   WITH moda AS (
	   		SELECT peso, COUNT(peso) AS contador FROM marzo2024 
			GROUP BY peso) 
	   SELECT peso, MAX(contador) AS quantity FROM moda GROUP BY peso 
	   ORDER BY quantity DESC
	   LIMIT 1;
	   )