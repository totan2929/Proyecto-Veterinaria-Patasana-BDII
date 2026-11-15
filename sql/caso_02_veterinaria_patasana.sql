-- =====================================================================
-- CASO 02 · Veterinaria PataSana
-- Checkpoint Unidades 2 y 3 | Bases de Datos II
-- Veterinaria de barrio que agenda citas de consulta, vacunación y peluquería canina.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS checkpoint_caso_02;
USE checkpoint_caso_02;

CREATE TABLE servicio (
    id_servicio INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    precio DECIMAL(10,2) NOT NULL
);

CREATE TABLE cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100),
    telefono VARCHAR(20)
);

CREATE TABLE cita (
    id_cita INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    id_cliente INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE detalle_cita (
    id_detalle_cita INT PRIMARY KEY AUTO_INCREMENT,
    id_cita INT NOT NULL,
    id_servicio INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_cita) REFERENCES cita(id_cita),
    FOREIGN KEY (id_servicio) REFERENCES servicio(id_servicio)
);

USE checkpoint_caso_02;
WITH totales_por_cita AS (
    SELECT c.id_cita, c.id_cliente, c.fecha, SUM(dc.cantidad * dc.precio_unitario) AS total_cita
    FROM cita c
    JOIN detalle_cita dc ON c.id_cita = dc.id_cita
    GROUP BY dc.id_cita
)
SELECT id_cita, id_cliente, fecha, total_cita,
  SUM(total_cita) OVER (PARTITION BY id_cliente ORDER BY fecha) AS acumulado_servicio
FROM totales_por_cita
ORDER BY id_cliente, fecha;


INSERT INTO servicio (nombre, categoria, precio) VALUES
('Consulta general', 'consulta', 60000),
('Vacuna antirrábica', 'vacuna', 35000),
('Baño y peluquería', 'estetica', 40000),
('Desparasitación', 'consulta', 25000),
('Vacuna polivalente', 'vacuna', 50000),
('Corte de uñas', 'estetica', 15000);

INSERT INTO cliente (nombre, correo, telefono) VALUES
('Mariana Cárdenas', 'mariana.cárdenas@mail.com', '3000200000'),
('Felipe Zapata', 'felipe.zapata@mail.com', '3000200001'),
('Isabella Correa', 'isabella.correa@mail.com', '3000200002'),
('Daniel Muñoz', 'daniel.muñoz@mail.com', '3000200003'),
('Sara Londoño', 'sara.londoño@mail.com', '3000200004'),
('Nicolás Vélez', 'nicolás.vélez@mail.com', '3000200005');
-- Nota: el último cliente (Nicolás Vélez) queda sin transacciones a propósito,
-- para practicar LEFT JOIN igual que en la Sesión 4.

INSERT INTO cita (fecha, id_cliente) VALUES
('2026-09-02', 1),
('2026-09-05', 2),
('2026-09-08', 3),
('2026-09-11', 4),
('2026-09-14', 5),
('2026-09-17', 1),
('2026-09-20', 2);

INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario) VALUES
(1, 3, 1, 40000),
(1, 4, 2, 25000),
(2, 5, 2, 50000),
(2, 6, 3, 15000),
(3, 1, 3, 60000),
(3, 2, 1, 35000),
(4, 3, 1, 40000),
(4, 4, 2, 25000),
(5, 5, 2, 50000),
(5, 6, 3, 15000),
(6, 1, 3, 60000),
(6, 2, 1, 35000),
(7, 3, 1, 40000),
(7, 4, 2, 25000);


-- JOIN multi-tabla – Total pagado por servicio

-- La consulta me permite determinar en una cita por cada cliente el total pagado por servicio, de acuerdo a la cantidad de servicios contratados según su tipo.
-- Es decir, además responde a la pregunta ¿Cuánto se pagó por cada servicio contratado en cada cita y qué cliente lo recibió?
SELECT ci.id_cita, c.nombre AS cliente, s.nombre AS servicio, dci.cantidad AS cantidad_servicios, dci.precio_unitario, (dci.cantidad * dci.precio_unitario) AS total_cancelado_servicio
FROM cita ci
INNER JOIN cliente c ON ci.id_cliente = c.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio;

--------------------------------------------------------------------------------------------------------------------------------

-- JOIN multi-tabla – Derecho a descuento

-- La consulta permite identificar las citas en las que un cliente contrató más de 2 unidades de un servicio de la categoría 'consulta'
-- y mostrar 1 en Derecho_Descuento cuando aplica.
SELECT ci.id_cita, c.nombre AS cliente, dci.cantidad AS total_citas_por_servicio, (dci.cantidad > 2) AS derecho_descuento
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'consulta' AND dci.cantidad > 2;

-----------------------------------------------------------------------------------------------------------------------------------

-- Subconsulta correlacionada – Clientes con más de una cita

-- La consulta busca mostrar los clientes que tienen más de una cita registrada
SELECT c.id_cliente, c.nombre
FROM cliente c
WHERE (SELECT COUNT(*) FROM cita ci
WHERE ci.id_cliente = c.id_cliente) > 1;

-------------------------------------------------------------------------------------------------------------------------------------

-- UNION – Listado de precios

-- La consulta permite combinar en un solo listado los precios registrados en servicio y los precios unitarios registrados
-- en detalle_cita, indicando el origen de cada valor.
SELECT precio, 'servicio' AS tipo FROM servicio
UNION
SELECT precio_unitario, 'precio_unitario' AS tipo FROM detalle_cita;

-------------------------------------------------------------------------------------------------------------------------------------

-- JOIN multi-tabla - Consumo de Servicios de Estética 

-- Muestra el gasto total en servicios de la categoría 'estetica' por cita y cliente,
-- detallando la fecha, el servicio de belleza aplicado y el costo total del servicio.
SELECT ci.id_cita, c.nombre AS cliente, ci.fecha AS fecha_cita, s.nombre AS servicio_estetica, dci.cantidad, (dci.cantidad * dci.precio_unitario) AS total_gastado_estetica
FROM cliente c
JOIN cita ci ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'estetica';

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Subconsulta correlacionada - Clientes con Pagos por Encima del Promedio 

-- Identifica a los clientes que han realizado al menos un pago individual (por ítem de servicio)
-- superior al precio promedio estándar de catálogo de la veterinaria.
SELECT DISTINCT c.id_cliente, c.nombre AS cliente, c.telefono
FROM cliente c
WHERE EXISTS (
    SELECT 1 
    FROM cita ci 
    JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
    WHERE ci.id_cliente = c.id_cliente 
        AND dci.precio_unitario > (SELECT AVG(precio) FROM servicio)
);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- UNION – Directorio Unificado de Canales de Contacto  


-- Unifica en un solo listado los correos electrónicos y los números telefónicos 
-- de todos los clientes, especificando el tipo de dato para facilidades de contacto o exportación a CRM.
SELECT nombre AS cliente, correo AS dato_contacto, 'Correo Electrónico' AS tipo_canal
FROM cliente
WHERE correo IS NOT NULL

UNION

SELECT nombre AS cliente, telefono AS dato_contacto, 'Teléfono / WhatsApp' AS tipo_canal
FROM cliente
WHERE telefono IS NOT NULL;

-----------------------------------------------------------------------------------------------------

-- JOIN multi-tabla – Seguimiento de Vacunación

-- La consulta permite identificar los clientes y fechas en las que se aplicaron vacunas, 
-- facilitando el seguimiento del esquema de vacunacion de las mascotas.
SELECT 
    c.nombre AS cliente,
    c.telefono,
    ci.fecha AS fecha_vacunacion,
    s.nombre AS vacuna_aplicada
FROM cliente c
INNER JOIN cita ci ON c.id_cliente = ci.id_cliente
INNER JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
INNER JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'vacuna'
ORDER BY ci.fecha DESC;

------------------------------


-- Subconsulta correlacionada - Última fecha de visita por cliente


-- La consulta permite calcular la cantidad total de citas agendadas por cada cliente 
-- utilizando una subconsulta correlacionada para evaluar la frecuencia de visitas.

USE checkpoint_caso_02;

SELECT 
    c.id_cliente,
    c.nombre AS cliente,
    (SELECT MAX(ci.fecha) 
     FROM cita ci 
     WHERE ci.id_cliente = c.id_cliente) AS ultima_fecha_cita
FROM cliente c;

--------------------------------



-----------------------------------------

-- UNION - Clasificación de Servicios por Rango de Precios (Económicos vs. Premium)

-- La consulta permite clasificar y unificar el catálogo de servicios de la veterinaria 
-- en dos niveles de precio: Económico (menos de $40.000) y Premium ($40.000 o mas).

SELECT nombre AS servicio, precio, 'Económico' AS tipo_precio
FROM servicio
WHERE precio < 40000
UNION
SELECT nombre AS servicio, precio, 'Premium' AS tipo_precio
FROM servicio
WHERE precio >= 40000;


--------------------------------------------------------------------------------------
-- FUNCIONES Y PROCEDIMIENTOS ALMACENADOS

-- Función 1
-- fn_total_cita (Función simple):
-- Calcula y retorna el costo total de una cita sumando (cantidad * precio_unitario)
-- de sus servicios asociados.

DROP FUNCTION IF EXISTS fn_total_cita;

DELIMITER $$

CREATE FUNCTION fn_total_cita(p_id_cita INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT SUM(cantidad * precio_unitario)
        INTO v_total
        FROM detalle_cita
        WHERE id_cita = p_id_cita;

    RETURN COALESCE(v_total, 0.00);
END$$

DELIMITER ;


-- Prueba: Uso dentro de un SELECT como columna calculada

SELECT 
    ci.id_cita,
    c.nombre AS cliente,
    ci.fecha,
    fn_total_cita(ci.id_cita) AS total_pagar_cita
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
ORDER BY ci.id_cita;

-- Prueba individual directa para una sola cita
SELECT fn_total_cita(1) AS total_cita_1;
SELECT fn_total_cita(2) AS total_cita_2; 
SELECT fn_total_cita(3) AS total_cita_3;
------------------------------------------------------------------------------

-- Función 2
-- fn_clasificar_precio_servicio (Función con control de flujo):
-- Evalúa el precio de un servicio mediante bloques IF/ELSEIF/ELSE y devuelve 
-- ('Económico', 'Estándar' o 'Premium').


DROP FUNCTION IF EXISTS fn_clasificar_precio_servicio;

DELIMITER $$

CREATE FUNCTION fn_clasificar_precio_servicio(p_precio DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_precio < 30000 THEN
        RETURN 'Económico';
    ELSEIF p_precio < 50000 THEN
        RETURN 'Estándar';
    ELSE
        RETURN 'Premium';
    END IF;
END$$

DELIMITER ;

-- Uso dentro de un SELECT sobre el catálogo de servicios
SELECT 
    id_servicio,
    nombre AS servicio,
    categoria,
    precio,
    fn_clasificar_precio_servicio(precio) AS segmento_tarifa
FROM servicio
ORDER BY precio ASC;


-- Prueba individual directa probando los 3 rangos del condicional
SELECT fn_clasificar_precio_servicio(15000) AS prueba_economico; 
SELECT fn_clasificar_precio_servicio(35000) AS prueba_estandar;
SELECT fn_clasificar_precio_servicio(60000) AS prueba_premium;

----------------------------------------------------------------------------

-- Función 3
-- fn_nivel_fidelidad_cliente (Función propia del negocio):
-- Cuenta el historial de citas de un cliente y lo clasifica ('Sin visitas', 'Cliente Nuevo'
-- o 'Cliente Frecuente').


DROP FUNCTION IF EXISTS fn_nivel_fidelidad_cliente;

DELIMITER $$

CREATE FUNCTION fn_nivel_fidelidad_cliente(p_id_cliente INT)
RETURNS VARCHAR(25)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_citas INT;

    SELECT COUNT(*)
        INTO v_total_citas
        FROM cita
        WHERE id_cliente = p_id_cliente;

    IF v_total_citas = 0 THEN
        RETURN 'Sin visitas';
    ELSEIF v_total_citas = 1 THEN
        RETURN 'Cliente Nuevo';
    ELSE
        RETURN 'Cliente Frecuente';
    END IF;
END$$

DELIMITER ;

-- Uso dentro de un SELECT
SELECT 
    c.id_cliente,
    c.nombre AS cliente,
    c.telefono,
    fn_nivel_fidelidad_cliente(c.id_cliente) AS fidelidad
FROM cliente c
ORDER BY c.id_cliente;


-- Prueba individual directa para cada nivel de fidelidad
SELECT fn_nivel_fidelidad_cliente(1) AS fidelidad_mariana; 
SELECT fn_nivel_fidelidad_cliente(3) AS fidelidad_isabella; 
SELECT fn_nivel_fidelidad_cliente(6) AS fidelidad_nicolas;


-- Prueba filtrando un cliente específico por su id_cliente
SELECT 
    c.id_cliente,
    c.nombre AS cliente,
    c.telefono,
    fn_nivel_fidelidad_cliente(c.id_cliente) AS fidelidad
FROM cliente c
WHERE c.id_cliente = 1; -- Prueba solo con Mariana Cárdenas

---------------------------------------------------------------------------------------------

-- Función 4
-- fn_subtotal_servicio_cita: Función simple – Total pagado por servicio
-- Función basada en el JOIN
-- Permite determinar en una cita, por cada cliente, el total pagado por un
-- servicio específico de acuerdo con la cantidad contratada y su precio unitario.
-- Responde a la pregunta: ¿Cuánto se pagó por cada servicio contratado en cada cita?

USE checkpoint_caso_02;

DROP FUNCTION IF EXISTS fn_subtotal_servicio_cita;

DELIMITER $$

CREATE FUNCTION fn_subtotal_servicio_cita(p_id_detalle_cita INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(10,2);

    SELECT (cantidad * precio_unitario)
      INTO v_subtotal
      FROM detalle_cita
      WHERE id_detalle_cita = p_id_detalle_cita;

    RETURN COALESCE(v_subtotal, 0.00);
END$$

DELIMITER ;

-- Prueba 1: Llamada individual directa para un ítem específico
SELECT fn_subtotal_servicio_cita(1) AS subtotal_item_1; -- esperado: 40000.00 (1 * 40000)
SELECT fn_subtotal_servicio_cita(2) AS subtotal_item_2; -- esperado: 50000.00 (2 * 25000)

-- Prueba 2: Filtrando una sola cita en el JOIN multi-tabla (ej. id_cita = 1)
SELECT 
    ci.id_cita, 
    c.nombre AS cliente, 
    s.nombre AS servicio, 
    dci.cantidad AS cantidad_servicios, 
    dci.precio_unitario, 
    fn_subtotal_servicio_cita(dci.id_detalle_cita) AS total_cancelado_servicio
FROM cita ci
INNER JOIN cliente c ON ci.id_cliente = c.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE ci.id_cita = 1;

-- Prueba 3: Aplicada directamente al listado completo del primer ejercicio de JOIN multi-tabla
SELECT 
    ci.id_cita, 
    c.nombre AS cliente, 
    s.nombre AS servicio, 
    dci.cantidad AS cantidad_servicios, 
    dci.precio_unitario, 
    fn_subtotal_servicio_cita(dci.id_detalle_cita) AS total_cancelado_servicio
FROM cita ci
INNER JOIN cliente c ON ci.id_cliente = c.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
ORDER BY ci.id_cita;
---------------------------------------------------------------------------------------------

-- Función 5
-- fn_derecho_descuento: Función con control de flujo – Derecho a descuento
-- Se crea esta función basada en el JOIN 2
-- Permite identificar las citas en las que un cliente contrató más de 2 unidades
-- de un servicio de la categoría 'consulta' y evaluar mediante control de flujo
-- (IF/ELSEIF/ELSE) si aplica o no el beneficio de descuento.

USE checkpoint_caso_02;

DROP FUNCTION IF EXISTS fn_derecho_descuento;

DELIMITER $$

CREATE FUNCTION fn_derecho_descuento(
    p_categoria VARCHAR(50),
    p_cantidad INT
)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    IF p_categoria = 'consulta' AND p_cantidad > 2 THEN
        RETURN 'Aplica descuento';
    ELSEIF p_categoria = 'consulta' AND p_cantidad <= 2 THEN
        RETURN 'No aplica (mínimo 3)';
    ELSE
        RETURN 'Categoría sin descuento';
    END IF;
END$$

DELIMITER ;

-- Prueba 1: Llamada individual directa probando los 3 caminos del IF/ELSEIF/ELSE
SELECT fn_derecho_descuento('consulta', 3) AS caso_con_descuento;   -- esperado: 'Aplica descuento'
SELECT fn_derecho_descuento('consulta', 2) AS caso_faltan_unidades; -- esperado: 'No aplica (mínimo 3)'
SELECT fn_derecho_descuento('estetica', 4) AS caso_otra_categoria;  -- esperado: 'Categoría sin descuento'

-- Prueba 2: Aplicada exactamente al segundo ejercicio de JOIN (filtrando los que sí aplican)
SELECT 
    ci.id_cita, 
    c.nombre AS cliente, 
    s.nombre AS servicio,
    s.categoria,
    dci.cantidad AS total_citas_por_servicio, 
    fn_derecho_descuento(s.categoria, dci.cantidad) AS derecho_descuento
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'consulta' AND dci.cantidad > 2;

-- Prueba 3: Listado general en el JOIN para ver cómo clasifica todas las citas
SELECT 
    ci.id_cita, 
    c.nombre AS cliente, 
    s.nombre AS servicio,
    s.categoria,
    dci.cantidad AS total_citas_por_servicio, 
    fn_derecho_descuento(s.categoria, dci.cantidad) AS derecho_descuento
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
ORDER BY ci.id_cita;

---------------------------------------------------------------------------------------------

-- Procedimiento 1
-- sp_agendar_cita: Procedimiento con parámetros IN y OUT

DROP PROCEDURE IF EXISTS sp_agendar_cita;

DELIMITER $$

CREATE PROCEDURE sp_agendar_cita(
    IN  p_id_cliente INT,
    IN  p_fecha DATE,
    OUT p_id_cita_generada INT
)
BEGIN
    INSERT INTO cita (fecha, id_cliente)
    VALUES (p_fecha, p_id_cliente);

    SET p_id_cita_generada = LAST_INSERT_ID();
END$$

DELIMITER ;

-- Antes: ¿Cuántas citas tiene Nicolás Vélez (id_cliente = 6)? (esperado: 0)
SELECT COUNT(*) AS citas_nicolas_antes FROM cita WHERE id_cliente = 6;

-- Ejecución del procedimiento
CALL sp_agendar_cita(6, '2026-11-15', @nueva_cita_id);
SELECT @nueva_cita_id AS id_cita_creada;

-- Después: Verificar que ahora tiene 1 cita registrada
SELECT COUNT(*) AS citas_nicolas_despues FROM cita WHERE id_cliente = 6;
SELECT * FROM cita WHERE id_cliente = 6;

---------------------------------------------------------------------------------------------

-- Procedimiento 2
-- sp_agregar_servicio_cita: Modifica datos + validación con SIGNAL

DROP PROCEDURE IF EXISTS sp_agregar_servicio_cita;

DELIMITER $$

CREATE PROCEDURE sp_agregar_servicio_cita(
    IN p_id_cita INT,
    IN p_id_servicio INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_existe_cita INT;
    DECLARE v_precio_actual DECIMAL(10,2);

    SELECT COUNT(*) INTO v_existe_cita
    FROM cita
    WHERE id_cita = p_id_cita;

    SELECT precio INTO v_precio_actual
    FROM servicio
    WHERE id_servicio = p_id_servicio;

    IF v_existe_cita = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cita indicada no existe en el sistema';
    ELSEIF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El servicio solicitado no existe en el catálogo';
    ELSEIF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cantidad de servicios debe ser mayor a cero';
    ELSE
        INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario)
        VALUES (p_id_cita, p_id_servicio, p_cantidad, v_precio_actual);
    END IF;
END$$

DELIMITER ;

-- Caso válido: Agregar 1 'Consulta general' (id_servicio = 1, $60.000) a la nueva cita de Nicolás (@nueva_cita_id)
SELECT fn_total_cita(@nueva_cita_id) AS total_cita_antes;   -- esperado: 0.00
CALL sp_agregar_servicio_cita(@nueva_cita_id, 1, 1);
SELECT fn_total_cita(@nueva_cita_id) AS total_cita_despues; -- esperado: 60000.00

-- Caso inválido (descomentar para probar que SIGNAL detiene la inserción):
-- CALL sp_agregar_servicio_cita(@nueva_cita_id, 1, 0);
-- Error esperado: "Error: La cantidad de servicios debe ser mayor a cero"

---------------------------------------------------------------------------------------------

-- Procedimiento 3
-- sp_actualizar_precio_servicio: Procedimiento propio con lógica y SIGNAL

DROP PROCEDURE IF EXISTS sp_actualizar_precio_servicio;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_precio_servicio(
    IN p_id_servicio INT,
    IN p_porcentaje_cambio DECIMAL(5,2)
)
BEGIN
    DECLARE v_precio_actual DECIMAL(10,2);
    DECLARE v_nuevo_precio DECIMAL(10,2);

    SELECT precio INTO v_precio_actual
    FROM servicio
    WHERE id_servicio = p_id_servicio;

    IF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El servicio que intenta actualizar no existe';
    ELSE
        SET v_nuevo_precio = v_precio_actual * (1 + (p_porcentaje_cambio / 100));

        IF v_nuevo_precio <= 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Error: El porcentaje ingresado produce un precio inválido (menor o igual a 0)';
        ELSE
            UPDATE servicio
               SET precio = v_nuevo_precio
             WHERE id_servicio = p_id_servicio;
        END IF;
    END IF;
END$$

DELIMITER ;

-- Caso válido: Incrementar en 10% el precio de 'Corte de uñas' (id_servicio = 6, precio original 15000)
SELECT id_servicio, nombre, precio AS precio_antes FROM servicio WHERE id_servicio = 6;   -- esperado: 15000.00
CALL sp_actualizar_precio_servicio(6, 10.00);
SELECT id_servicio, nombre, precio AS precio_despues FROM servicio WHERE id_servicio = 6; -- esperado: 16500.00

-- Caso inválido (descomentar para probar que SIGNAL protege el precio):
-- CALL sp_actualizar_precio_servicio(6, -120.00);
-- Error esperado: "Error: El porcentaje ingresado produce un precio inválido (menor o igual a 0)"
---------------------------------------------------------------------------------------------------------



-- fn_total_estetica_cita
-- Calcula el gasto total en servicios de categoría 'estetica' para una cita específica.

DROP FUNCTION IF EXISTS fn_total_estetica_cita;
DELIMITER $$

CREATE FUNCTION fn_total_estetica_cita(p_id_cita INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT SUM(dci.cantidad * dci.precio_unitario)
        INTO v_total
        FROM detalle_cita dci
        JOIN servicio s ON dci.id_servicio = s.id_servicio
        WHERE dci.id_cita = p_id_cita 
        AND s.categoria = 'estetica';

    RETURN COALESCE(v_total, 0.00);
END$$

DELIMITER ;

-- consulta para ejecutar la funcion fn_total_estetica_cita
SELECT 
    ci.id_cita,
    c.nombre AS cliente,
    ci.fecha AS fecha_cita,
    s.nombre AS servicio_estetica,
    dci.cantidad,
    fn_total_estetica_cita(ci.id_cita) AS total_gastado_estetica
FROM cliente c
JOIN cita ci ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'estetica';

---------------------------------------------------------------------------------------------
-- fn_cliente_supera_promedio
-- Devuelve 1 si el cliente ha realizado algún pago individual superior
-- al precio promedio del catálogo de servicios, o 0 en caso contrario.

DROP FUNCTION IF EXISTS fn_cliente_supera_promedio;
DELIMITER $$

CREATE FUNCTION fn_cliente_supera_promedio(p_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_supera INT DEFAULT 0;

    SELECT IF(COUNT(*) > 0, 1, 0)
        INTO v_supera
        FROM cita ci
        JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
        WHERE ci.id_cliente = p_id_cliente
        AND dci.precio_unitario > (SELECT AVG(precio) FROM servicio);

    RETURN v_supera;
END$$

DELIMITER ;

-- consulta para ejecutar la funcion fn_cliente_supera_promedio

SELECT c.id_cliente, c.nombre AS cliente, c.telefono
FROM cliente c
WHERE fn_cliente_supera_promedio(c.id_cliente) = 1;


----------------------------------------------------------------------------------------------------


-- fn_obtener_contacto_cliente
-- Retorna el correo electrónico o teléfono de un cliente según
-- el canal de contacto especificado.

DROP FUNCTION IF EXISTS fn_obtener_contacto_cliente;
DELIMITER $$

CREATE FUNCTION fn_obtener_contacto_cliente(
    p_id_cliente INT, 
    p_tipo_canal VARCHAR(20)
)
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_contacto VARCHAR(100);

    IF LOWER(p_tipo_canal) = 'correo' THEN
            SELECT correo INTO v_contacto 
            FROM cliente 
            WHERE id_cliente = p_id_cliente;
    ELSEIF LOWER(p_tipo_canal) IN ('telefono', 'teléfono', 'whatsapp') THEN
            SELECT telefono INTO v_contacto 
            FROM cliente 
            WHERE id_cliente = p_id_cliente;
    ELSE
        SET v_contacto = 'Canal no válido';
    END IF;

    RETURN COALESCE(v_contacto, 'Sin registro');
END$$

DELIMITER ;

-- consulta para ejecutar la funcion fn_obtener_contacto_cliente

SELECT 
    nombre AS cliente,
    fn_obtener_contacto_cliente(id_cliente, 'correo') AS correo_contacto,
    fn_obtener_contacto_cliente(id_cliente, 'telefono') AS telefono_contacto
FROM cliente;



-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

/*
fn_gasto_historico_cliente (Función almacenada)
- Qué hace o decide: Calcula el gasto histórico acumulado de un cliente sumando el subtotal 
  (cantidad * precio_unitario) de todos los servicios consumidos a lo largo de todas sus citas, 
  devolviendo 0 si el cliente aún no registra consumos.
*/

USE checkpoint_caso_02;

DROP FUNCTION IF EXISTS fn_gasto_historico_cliente;
DELIMITER $$
CREATE FUNCTION fn_gasto_historico_cliente(p_id_cliente INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gasto_total DECIMAL(10,2);
    
    SELECT SUM(dci.cantidad * dci.precio_unitario)
      INTO v_gasto_total
      FROM cita ci
      JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
     WHERE ci.id_cliente = p_id_cliente;
      
    RETURN COALESCE(v_gasto_total, 0);
END$$
DELIMITER ;

-- Prueba : Consultar el gasto histórico de todos los clientes (incluyendo los que tienen $0)
SELECT id_cliente, 
       nombre AS cliente, 
       fn_gasto_historico_cliente(id_cliente) AS gasto_historico
FROM cliente
ORDER BY gasto_historico DESC;

------------------------------------------------------------------------------------------
/*
fn_clasificacion_cliente (Función almacenada)
- Qué hace o decide: Evalúa el monto total gastado mediante estructuras condicionales 
  (IF/ELSEIF/ELSE) y clasifica al cliente en 'Cliente Estrella', 'Cliente Frecuente' o 'Cliente Ocasional'.
*/

DROP FUNCTION IF EXISTS fn_clasificacion_cliente;
DELIMITER $$
CREATE FUNCTION fn_clasificacion_cliente(p_total_gastado DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_total_gastado >= 100000 THEN
        RETURN 'Cliente Estrella';
    ELSEIF p_total_gastado >= 50000 THEN
        RETURN 'Cliente Frecuente';
    ELSE
        RETURN 'Cliente Ocasional';
    END IF;
END$$
DELIMITER ;

SELECT c.nombre AS cliente, 
       fn_total_cita(ci.id_cita) AS gasto_cita,
       fn_clasificacion_cliente(fn_total_cita(ci.id_cita)) AS clasificacion
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente;

----------------------------------------------------------------------------------------------
/*
fn_tipo_servicio (Función almacenada)
- Qué hace o decide: Evalúa el precio base de un servicio del catálogo y decide si 
  pertenece a la categoría 'Premium' ($40.000 o más) o 'Económico' (menos de $40.000).
*/

DROP FUNCTION IF EXISTS fn_tipo_servicio;
DELIMITER $$
CREATE FUNCTION fn_tipo_servicio(p_precio DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_precio >= 40000 THEN
        RETURN 'Premium';
    ELSE
        RETURN 'Económico';
    END IF;
END$$
DELIMITER ;

-- Prueba : Según el precio se clasifican los clientes
SELECT nombre AS servicio, precio, fn_tipo_servicio(precio) AS tipo_precio
FROM servicio
ORDER BY precio DESC;

------------------------------------------------------------------------------------------
/*
sp_aplicar_descuento_volumen (Procedimiento almacenado)
- Qué hace o decide: Verifica si una cita acumula más de 2 unidades de servicio contratadas; 
  si cumple la regla de volumen, aplica un porcentaje de descuento sobre el precio_unitario de sus 
  ítems en detalle_cita y devuelve el nuevo total recalculado mediante un parámetro OUT.
*/

USE checkpoint_caso_02;

DROP PROCEDURE IF EXISTS sp_aplicar_descuento_volumen;
DELIMITER $$
CREATE PROCEDURE sp_aplicar_descuento_volumen(
    IN  p_id_cita INT,
    IN  p_porcentaje_desc DECIMAL(5,2),
    OUT p_nuevo_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_total_unidades INT;

    -- Contar cuántas unidades de servicio tiene la cita
    SELECT COALESCE(SUM(cantidad), 0)
      INTO v_total_unidades
      FROM detalle_cita
     WHERE id_cita = p_id_cita;

    -- Aplicar el descuento solo si supera las 2 unidades (regla de volumen)
    IF v_total_unidades > 2 THEN
        UPDATE detalle_cita
           SET precio_unitario = precio_unitario - (precio_unitario * (p_porcentaje_desc / 100))
         WHERE id_cita = p_id_cita;
    END IF;

    -- Calcular el total final de la cita para devolverlo en el parámetro OUT
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
      INTO p_nuevo_total
      FROM detalle_cita
     WHERE id_cita = p_id_cita;
END$$
DELIMITER ;

-- Prueba : La cita 2 (Felipe Zapata) tiene 5 unidades de servicio y suma $145.000
SELECT * FROM detalle_cita WHERE id_cita = 2;

CALL sp_aplicar_descuento_volumen(2, 10, @total_con_descuento);
SELECT @total_con_descuento AS total_final_cita; -- Esperado: 130500.00
SELECT * FROM detalle_cita WHERE id_cita = 2;

--------------------------------------------------------------------------------------------
/*
sp_registrar_servicio_cita (Procedimiento almacenado)
- Qué hace o decide: Consulta el precio actual del servicio en el catálogo y valida si existe; 
  si no existe, cancela la operación lanzando un error controlado con SIGNAL, y si es válido, 
  inserta el registro en detalle_cita conservando el precio vigente del momento.
*/

CALL sp_agendar_cita(1, '2026-11-14', @nueva_cita);
SELECT @nueva_cita AS id_cita_generada;
SELECT * FROM cita WHERE id_cita = @nueva_cita;


-- 2.2 sp_registrar_servicio_cita (Procedimiento con validación SIGNAL)
DROP PROCEDURE IF EXISTS sp_registrar_servicio_cita;
DELIMITER $$
CREATE PROCEDURE sp_registrar_servicio_cita(
    IN p_id_cita INT,
    IN p_id_servicio INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_precio_actual DECIMAL(10,2);
    
    -- Obtener el precio actual del catálogo
    SELECT precio INTO v_precio_actual
    FROM servicio
    WHERE id_servicio = p_id_servicio;
    
    -- Validar si el servicio existe
    IF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El servicio indicado no existe en el catálogo.';
    ELSE
        -- Insertar el detalle con el precio histórico
        INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario)
        VALUES (p_id_cita, p_id_servicio, p_cantidad, v_precio_actual);
    END IF;
END$$
DELIMITER ;

-- Prueba : Caso Válido: 
CALL sp_registrar_servicio_cita(@nueva_cita, 1, 1);
SELECT * FROM detalle_cita WHERE id_cita = @nueva_cita;

-------------------------------------------------------------------------------------------
/*
sp_actualizar_precios_categoria (Procedimiento almacenado)
- Qué hace o decide: Actualiza de forma masiva el precio de todos los servicios pertenecientes 
  a una categoría específica (como 'estetica') aplicando un porcentaje de incremento recibido por parámetro.
*/

DROP PROCEDURE IF EXISTS sp_actualizar_precios_categoria;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_precios_categoria(
    IN p_categoria VARCHAR(50),
    IN p_porcentaje_aumento DECIMAL(5,2)
)
BEGIN
    UPDATE servicio
    SET precio = precio + (precio * (p_porcentaje_aumento / 100))
    WHERE categoria = p_categoria;
END$$
DELIMITER ;

-- Prueba : 
SELECT * FROM servicio WHERE categoria = 'estetica';
CALL sp_actualizar_precios_categoria('estetica', 10);
SELECT * FROM servicio WHERE categoria = 'estetica';

-- 1. Desactivar el modo seguro
SET SQL_SAFE_UPDATES = 0;

-- 2. Ejecutar la prueba
SELECT * FROM servicio WHERE categoria = 'estetica';
CALL sp_actualizar_precios_categoria('estetica', 10);
SELECT * FROM servicio WHERE categoria = 'estetica';

-- 3. Volver a activarlo (opcional, pero buena práctica)
SET SQL_SAFE_UPDATES = 1;