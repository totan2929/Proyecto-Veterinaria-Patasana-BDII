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