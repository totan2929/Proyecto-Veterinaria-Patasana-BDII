-- =====================================================================
-- CASO 02 · Veterinaria PataSana
-- Proyecto Final Integrador | Bases de Datos II (30%)
-- Veterinaria de barrio que agenda citas de consulta, vacunación y peluquería canina.
-- Integrantes: Jonathan Cañola Salazar, Jorge Andrés García Mojica, Rubén Darío Gaspar
-- =====================================================================

DROP DATABASE IF EXISTS checkpoint_caso_02;
CREATE DATABASE checkpoint_caso_02;
USE checkpoint_caso_02;

CREATE TABLE servicio (
    id_servicio INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0)
) ENGINE=InnoDB;

CREATE TABLE cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100),
    telefono VARCHAR(20)
) ENGINE=InnoDB;

CREATE TABLE cita (
    id_cita INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATE NOT NULL,
    id_cliente INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE detalle_cita (
    id_detalle_cita INT PRIMARY KEY AUTO_INCREMENT,
    id_cita INT NOT NULL,
    id_servicio INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0),
    FOREIGN KEY (id_cita) REFERENCES cita(id_cita),
    FOREIGN KEY (id_servicio) REFERENCES servicio(id_servicio)
) ENGINE=InnoDB;

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

-- CTE movida después de los INSERT y corregida para ONLY_FULL_GROUP_BY
WITH totales_por_cita AS (
    SELECT c.id_cita, c.id_cliente, c.fecha, SUM(dc.cantidad * dc.precio_unitario) AS total_cita
    FROM cita c
    JOIN detalle_cita dc ON c.id_cita = dc.id_cita
    GROUP BY c.id_cita, c.id_cliente, c.fecha
)
SELECT id_cita, id_cliente, fecha, total_cita,
  SUM(total_cita) OVER (PARTITION BY id_cliente ORDER BY fecha) AS acumulado_servicio
FROM totales_por_cita
ORDER BY id_cliente, fecha;

-- =====================================================================
-- CONSULTAS INTEGRADORAS (CORTE 1 Y 2)
-- =====================================================================

-- JOIN multi-tabla – Total pagado por servicio
SELECT ci.id_cita, c.nombre AS cliente, s.nombre AS servicio, dci.cantidad AS cantidad_servicios, dci.precio_unitario, (dci.cantidad * dci.precio_unitario) AS total_cancelado_servicio
FROM cita ci
INNER JOIN cliente c ON ci.id_cliente = c.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio;

-- JOIN multi-tabla – Derecho a descuento
SELECT ci.id_cita, c.nombre AS cliente, dci.cantidad AS total_citas_por_servicio, (dci.cantidad > 2) AS derecho_descuento
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'consulta' AND dci.cantidad > 2;

-- Subconsulta correlacionada – Clientes con más de una cita
SELECT c.id_cliente, c.nombre
FROM cliente c
WHERE (SELECT COUNT(*) FROM cita ci
WHERE ci.id_cliente = c.id_cliente) > 1;

-- UNION – Listado de precios
SELECT precio, 'servicio' AS tipo FROM servicio
UNION
SELECT precio_unitario, 'precio_unitario' AS tipo FROM detalle_cita;

-- JOIN multi-tabla - Consumo de Servicios de Estética
SELECT ci.id_cita, c.nombre AS cliente, ci.fecha AS fecha_cita, s.nombre AS servicio_estetica, dci.cantidad, (dci.cantidad * dci.precio_unitario) AS total_gastado_estetica
FROM cliente c
JOIN cita ci ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'estetica';

-- Subconsulta correlacionada - Clientes con Pagos por Encima del Promedio
SELECT DISTINCT c.id_cliente, c.nombre AS cliente, c.telefono
FROM cliente c
WHERE EXISTS (
    SELECT 1 
    FROM cita ci 
    JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
    WHERE ci.id_cliente = c.id_cliente 
        AND dci.precio_unitario > (SELECT AVG(precio) FROM servicio)
);

-- UNION – Directorio Unificado de Canales de Contacto
SELECT nombre AS cliente, correo AS dato_contacto, 'Correo Electrónico' AS tipo_canal
FROM cliente
WHERE correo IS NOT NULL
UNION
SELECT nombre AS cliente, telefono AS dato_contacto, 'Teléfono / WhatsApp' AS tipo_canal
FROM cliente
WHERE telefono IS NOT NULL;

-- JOIN multi-tabla – Seguimiento de Vacunación
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

-- Subconsulta correlacionada - Última fecha de visita por cliente
SELECT 
    c.id_cliente,
    c.nombre AS cliente,
    (SELECT MAX(ci.fecha) 
     FROM cita ci 
     WHERE ci.id_cliente = c.id_cliente) AS ultima_fecha_cita
FROM cliente c;

-- UNION - Clasificación de Servicios por Rango de Precios (Económicos vs. Premium)
SELECT nombre AS servicio, precio, 'Económico' AS tipo_precio
FROM servicio
WHERE precio < 40000
UNION
SELECT nombre AS servicio, precio, 'Premium' AS tipo_precio
FROM servicio
WHERE precio >= 40000;


-- =====================================================================
-- FUNCIONES Y PROCEDIMIENTOS ALMACENADOS (CORTE 2)
-- Nota: Las llamadas CALL de prueba que modifican/borran datos se dejan
-- comentadas para mantener limpios los conteos de la sección final.
-- =====================================================================

-- Función 1: fn_total_cita
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

-- Función 2: fn_clasificar_precio_servicio
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

-- Función 3: fn_nivel_fidelidad_cliente
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

-- Función 4: fn_subtotal_servicio_cita
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

-- Función 5: fn_derecho_descuento
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

-- Función 6: fn_total_estetica_cita
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

-- Función 7: fn_cliente_supera_promedio
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

-- Función 8: fn_obtener_contacto_cliente
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
        SELECT correo INTO v_contacto FROM cliente WHERE id_cliente = p_id_cliente;
    ELSEIF LOWER(p_tipo_canal) IN ('telefono', 'teléfono', 'whatsapp') THEN
        SELECT telefono INTO v_contacto FROM cliente WHERE id_cliente = p_id_cliente;
    ELSE
        SET v_contacto = 'Canal no válido';
    END IF;
    RETURN COALESCE(v_contacto, 'Sin registro');
END$$
DELIMITER ;

-- Función 9: fn_gasto_historico_cliente
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

-- Función 10: fn_clasificacion_cliente
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

-- Función 11: fn_tipo_servicio
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

-- Procedimiento 1: sp_agendar_cita
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
-- CALL sp_agendar_cita(6, '2026-11-15', @nueva_cita_id);

-- Procedimiento 2: sp_agregar_servicio_cita
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

    SELECT COUNT(*) INTO v_existe_cita FROM cita WHERE id_cita = p_id_cita;
    SELECT precio INTO v_precio_actual FROM servicio WHERE id_servicio = p_id_servicio;

    IF v_existe_cita = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cita indicada no existe en el sistema';
    ELSEIF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio solicitado no existe en el catálogo';
    ELSEIF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cantidad de servicios debe ser mayor a cero';
    ELSE
        INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario)
        VALUES (p_id_cita, p_id_servicio, p_cantidad, v_precio_actual);
    END IF;
END$$
DELIMITER ;
-- CALL sp_agregar_servicio_cita(@nueva_cita_id, 1, 1);

-- Procedimiento 3: sp_actualizar_precio_servicio
DROP PROCEDURE IF EXISTS sp_actualizar_precio_servicio;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_precio_servicio(
    IN p_id_servicio INT,
    IN p_porcentaje_cambio DECIMAL(5,2)
)
BEGIN
    DECLARE v_precio_actual DECIMAL(10,2);
    DECLARE v_nuevo_precio DECIMAL(10,2);

    SELECT precio INTO v_precio_actual FROM servicio WHERE id_servicio = p_id_servicio;

    IF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio que intenta actualizar no existe';
    ELSE
        SET v_nuevo_precio = v_precio_actual * (1 + (p_porcentaje_cambio / 100));
        IF v_nuevo_precio <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El porcentaje ingresado produce un precio inválido (menor o igual a 0)';
        ELSE
            UPDATE servicio SET precio = v_nuevo_precio WHERE id_servicio = p_id_servicio;
        END IF;
    END IF;
END$$
DELIMITER ;
-- CALL sp_actualizar_precio_servicio(6, 10.00);

-- Procedimiento 4: sp_registrar_cliente
DROP PROCEDURE IF EXISTS sp_registrar_cliente;
DELIMITER $$
CREATE PROCEDURE sp_registrar_cliente(
    IN  p_nombre VARCHAR(100),
    IN  p_correo VARCHAR(100),
    IN  p_telefono VARCHAR(20),
    OUT p_id_cliente_nuevo INT
)
BEGIN
    DECLARE v_correo_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO v_correo_existe FROM cliente WHERE correo = p_correo;

    IF v_correo_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Ya existe un cliente registrado con ese correo.';
    ELSE
        INSERT INTO cliente (nombre, correo, telefono) VALUES (p_nombre, p_correo, p_telefono);
        SET p_id_cliente_nuevo = LAST_INSERT_ID();
    END IF;
END$$
DELIMITER ;
-- CALL sp_registrar_cliente('Camilo Restrepo', 'camilo.restrepo@mail.com', '3000200006', @nuevo_cliente);

-- Procedimiento 5: sp_actualizar_contacto_cliente
DROP PROCEDURE IF EXISTS sp_actualizar_contacto_cliente;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_contacto_cliente(
    IN p_id_cliente INT,
    IN p_nuevo_correo VARCHAR(100),
    IN p_nuevo_telefono VARCHAR(20)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO v_existe FROM cliente WHERE id_cliente = p_id_cliente;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El cliente indicado no existe.';
    ELSE
        UPDATE cliente SET correo = p_nuevo_correo, telefono = p_nuevo_telefono WHERE id_cliente = p_id_cliente;
    END IF;
END$$
DELIMITER ;
-- CALL sp_actualizar_contacto_cliente(3, 'isabella.nueva@mail.com', '3115558899');

-- Procedimiento 6: sp_cancelar_cita
DROP PROCEDURE IF EXISTS sp_cancelar_cita;
DELIMITER $$
CREATE PROCEDURE sp_cancelar_cita(IN p_id_cita INT)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO v_existe FROM cita WHERE id_cita = p_id_cita;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cita que intenta cancelar no existe.';
    ELSE
        DELETE FROM detalle_cita WHERE id_cita = p_id_cita;
        DELETE FROM cita WHERE id_cita = p_id_cita;
    END IF;
END$$
DELIMITER ;
-- CALL sp_cancelar_cita(7);

-- Procedimiento 7: sp_aplicar_descuento_volumen
DROP PROCEDURE IF EXISTS sp_aplicar_descuento_volumen;
DELIMITER $$
CREATE PROCEDURE sp_aplicar_descuento_volumen(
    IN  p_id_cita INT,
    IN  p_porcentaje_desc DECIMAL(5,2),
    OUT p_nuevo_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_total_unidades INT;
    SELECT COALESCE(SUM(cantidad), 0) INTO v_total_unidades FROM detalle_cita WHERE id_cita = p_id_cita;

    IF v_total_unidades > 2 THEN
        UPDATE detalle_cita
           SET precio_unitario = precio_unitario - (precio_unitario * (p_porcentaje_desc / 100))
         WHERE id_cita = p_id_cita;
    END IF;

    SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
      INTO p_nuevo_total
      FROM detalle_cita
     WHERE id_cita = p_id_cita;
END$$
DELIMITER ;
-- CALL sp_aplicar_descuento_volumen(2, 10, @total_con_descuento);

-- Procedimiento 8: sp_registrar_servicio_cita
DROP PROCEDURE IF EXISTS sp_registrar_servicio_cita;
DELIMITER $$
CREATE PROCEDURE sp_registrar_servicio_cita(
    IN p_id_cita INT,
    IN p_id_servicio INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_precio_actual DECIMAL(10,2);
    SELECT precio INTO v_precio_actual FROM servicio WHERE id_servicio = p_id_servicio;

    IF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El servicio indicado no existe en el catálogo.';
    ELSE
        INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario)
        VALUES (p_id_cita, p_id_servicio, p_cantidad, v_precio_actual);
    END IF;
END$$
DELIMITER ;
-- CALL sp_registrar_servicio_cita(@nueva_cita, 1, 1);

-- Procedimiento 9: sp_actualizar_precios_categoria
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
-- CALL sp_actualizar_precios_categoria('estetica', 10);
-- -----------------------------------------------------------------------------------------

-- =====================================================================
-- =====================================================================
-- SOLUCIÓN CORTE II / PROYECTO FINAL BD II
-- =====================================================================
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TRANSACCIÓN - Jonathan
-- Objetivo: Garantizar atomicidad ("todo o nada") al agendar una cita completa.
-- Esta operación modifica DOS tablas a la vez:
--   - Tabla 1: 'cita' (encabezado con fecha y cliente)
--   - Tabla 2: 'detalle_cita' (servicio contratado, cantidad y precio vigente)
-- Si el Paso 2 falla (ej. servicio inexistente o cantidad <= 0), el ROLLBACK
-- revierte el Paso 1 para que NO queden citas huérfanas sin servicios.
-- ---------------------------------------------------------------------

-- Borra el procedimiento si ya existía, asegurando que el script se pueda reejecutar sin error
DROP PROCEDURE IF EXISTS sp_registrar_cita_completa;

-- Cambia temporalmente el delimitador de ';' a '$$' para que MySQL lea todo el cuerpo del procedimiento como un solo bloque
DELIMITER $$

-- Define el procedimiento con 4 parámetros de entrada (IN) y 1 de salida (OUT)
CREATE PROCEDURE sp_registrar_cita_completa(
    IN  p_id_cliente       INT,    -- Entrada: ID del cliente que solicita la cita
    IN  p_fecha            DATE,   -- Entrada: Fecha programada para la cita
    IN  p_id_servicio      INT,    -- Entrada: ID del servicio del catálogo (tabla 'servicio')
    IN  p_cantidad         INT,    -- Entrada: Cantidad de unidades del servicio
    OUT p_id_cita_generada INT     -- Salida: Devuelve el ID creado en 'cita' (o NULL si hubo ROLLBACK)
)
BEGIN
    -- Variable local para verificar si el cliente existe en la tabla 'cliente' (inicia en 0)
    DECLARE v_existe_cliente INT DEFAULT 0;
    -- Variable local para almacenar el precio vigente del servicio obtenido desde 'servicio'
    DECLARE v_precio_actual  DECIMAL(10,2);

    -- Manejador automático de errores (EXIT HANDLER):
    -- Si ocurre CUALQUIER excepción SQL (error de FK, CHECK, o un SIGNAL nuestro), MySQL salta aquí inmediatamente:
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;                      -- Deshace TODOS los cambios hechos desde START TRANSACTION (revierte el Paso 1)
        SET p_id_cita_generada = NULL; -- Asigna NULL a la salida porque la cita no quedó guardada
        RESIGNAL;                      -- Relanza el error para que Workbench muestre el mensaje rojo original al usuario
    END;

    -- Inicia la transacción: desactiva el guardado automático (autocommit) para este bloque.
    -- Todo lo que pase a partir de aquí es temporal hasta que se ejecute COMMIT o ROLLBACK.
    START TRANSACTION;

    -- Validación previa: cuenta si existe algún registro con ese id_cliente
    SELECT COUNT(*) INTO v_existe_cliente
      FROM cliente
     WHERE id_cliente = p_id_cliente;

    -- Si el conteo es 0, el cliente no existe; lanzamos un error controlado con SIGNAL
    IF v_existe_cliente = 0 THEN
        -- SQLSTATE '45000' es el código reservado en SQL para errores personalizados de reglas de negocio
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El cliente indicado no existe en el sistema.';
    END IF;

    -- PASO 1 (Modifica Tabla 1: 'cita'): Inserta el encabezado de la cita.
    -- Aunque este INSERT se ejecuta aquí, todavía NO es definitivo hasta el COMMIT.
    INSERT INTO cita (fecha, id_cliente)
    VALUES (p_fecha, p_id_cliente);

    -- Captura el ID recién generado por el AUTO_INCREMENT de la tabla 'cita'
    SET p_id_cita_generada = LAST_INSERT_ID();

    -- Busca el precio actual del servicio en el catálogo para guardarlo como precio histórico en detalle_cita
    SELECT precio INTO v_precio_actual
      FROM servicio
     WHERE id_servicio = p_id_servicio;

    -- Si v_precio_actual es NULL, significa que el id_servicio no existe en el catálogo
    IF v_precio_actual IS NULL THEN
        -- Al lanzar SIGNAL, se activa el EXIT HANDLER -> ejecuta ROLLBACK -> borra la cita del Paso 1
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: El servicio no existe. Se revierte la cita creada.';
    END IF;

    -- Valida que la cantidad sea mayor a cero (regla de negocio y coherencia con el CHECK)
    IF p_cantidad <= 0 THEN
        -- Al lanzar SIGNAL, se activa el EXIT HANDLER -> ejecuta ROLLBACK -> borra la cita del Paso 1
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cantidad debe ser mayor a cero. Se revierte la cita creada.';
    END IF;

    -- PASO 2 (Modifica Tabla 2: 'detalle_cita'): Inserta el servicio asociado a la cita recién creada
    INSERT INTO detalle_cita (id_cita, id_servicio, cantidad, precio_unitario)
    VALUES (p_id_cita_generada, p_id_servicio, p_cantidad, v_precio_actual);

    -- Si ambos pasos y todas las validaciones terminaron sin errores, confirma los cambios permanentemente
    COMMIT;
END$$

-- Restaura el delimitador estándar de MySQL a punto y coma (;)
DELIMITER ;

-- ---------------------------------------------------------------------
-- Prueba exitosa (COMMIT)
-- Demuestra que con datos válidos ambas tablas aumentan en +1 fila.
-- ---------------------------------------------------------------------
-- Conteo ANTES de la transacción (esperado: 7 citas, 14 detalles)
SELECT (SELECT COUNT(*) FROM cita)         AS total_citas_antes,
       (SELECT COUNT(*) FROM detalle_cita) AS total_detalles_antes;

-- Ejecuta la transacción con datos válidos: cliente 6 (Nicolás Vélez), servicio 1 (Consulta general, $60.000), cantidad 1
CALL sp_registrar_cita_completa(6, '2026-11-25', 1, 1, @id_cita_ok);

-- Verifica el ID generado (8) y reutiliza la función fn_total_cita del Corte 2 para comprobar el total ($60.000)
SELECT @id_cita_ok AS id_cita_creada, fn_total_cita(@id_cita_ok) AS total_cita;

-- Conteo DESPUÉS del COMMIT (esperado: 8 citas, 15 detalles -> ambos pasos quedaron guardados)
SELECT (SELECT COUNT(*) FROM cita)         AS total_citas_despues,
       (SELECT COUNT(*) FROM detalle_cita) AS total_detalles_despues;

-- ---------------------------------------------------------------------
--  Prueba fallida (ROLLBACK)
-- Demuestra que si falla el Paso 2, el Paso 1 se deshace y no queda nada a medias.
-- Nota: El AUTO_INCREMENT no se devuelve con ROLLBACK (el ID 9 se "quema"), pero la fila NO se guarda.
-- ---------------------------------------------------------------------
-- Conteo ANTES de provocar el fallo (esperado: 8 citas, 15 detalles)
SELECT (SELECT COUNT(*) FROM cita)         AS citas_antes_fallo,
       (SELECT COUNT(*) FROM detalle_cita) AS detalles_antes_fallo;

-- Se deja comentado para que el script maestro corra de arriba a abajo sin detenerse.
-- Para tomar la captura de evidencia en Workbench, descomentar y ejecutar con Ctrl+Enter:
-- CALL sp_registrar_cita_completa(6, '2026-11-26', 999, 1, @id_cita_fail);
-- Error esperado: "Error: El servicio no existe. Se revierte la cita creada."

-- Conteo DESPUÉS del fallo (esperado: sigue en 8 citas, 15 detalles -> no quedó ninguna cita huérfana)
SELECT (SELECT COUNT(*) FROM cita)         AS citas_despues_fallo,
       (SELECT COUNT(*) FROM detalle_cita) AS detalles_despues_fallo;
-- -----------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------

-- 2 ÍNDICE JUSTIFICADO CON EXPLAIN - Jorge
-- Prueba de rendimiento sobre tabla auxiliar sin llaves foráneas

-- Preparación de la tabla de práctica (sin FK para evitar índices automáticos)
DROP TABLE IF EXISTS practica_cita;

CREATE TABLE practica_cita (
    id_cita    INT PRIMARY KEY AUTO_INCREMENT,
    fecha      DATE NOT NULL,
    id_cliente INT NOT NULL,
    total_cita DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

-- Carga masiva de 20.000 registros (1.000 clientes, 20 citas por cliente)
SET SESSION cte_max_recursion_depth = 20000;

INSERT INTO practica_cita (fecha, id_cliente, total_cita)
WITH RECURSIVE n AS (
    SELECT 1 AS i
    UNION ALL
    SELECT i + 1 FROM n WHERE i < 20000
)
SELECT DATE_ADD('2025-01-01', INTERVAL MOD(i, 365) DAY),
        MOD(i, 1000) + 1,
        ROUND(15000 + MOD(i * 37, 150000))
FROM n;

-- Verificación de filas cargadas
SELECT COUNT(*) AS total_filas, COUNT(DISTINCT id_cliente) AS total_clientes
FROM practica_cita;

-- Escenario 1: Consulta SIN índice (esperado: type = ALL, key = NULL, rows ≈ 20000)
SHOW INDEX FROM practica_cita;
EXPLAIN SELECT * FROM practica_cita WHERE id_cliente = 250;

-- Creación del índice sobre la columna de búsqueda
CREATE INDEX idx_practica_cita_cliente ON practica_cita (id_cliente);

-- Escenario 2: Consulta CON índice (esperado: type = ref, key = idx_practica_cita_cliente, rows ≈ 20)
SHOW INDEX FROM practica_cita;
EXPLAIN SELECT * FROM practica_cita WHERE id_cliente = 250;

-- ----------------------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 3. ROLES Y PERMISOS - Rubén
-- Objetivo: Aplicar el principio del mínimo privilegio en Veterinaria PataSana.
-- Cada rol agrupa SOLO los permisos estrictamente necesarios para su cargo,
-- evitando que un usuario borre datos o altere precios por error o abuso.
-- ---------------------------------------------------------------------

-- 3.1 Crea los 3 roles (paquetes de permisos) si no existen previamente en el servidor
CREATE ROLE IF NOT EXISTS 'rol_consulta_patasana', 'rol_operacion_patasana', 'rol_admin_patasana';

-- Rol 1 (Consulta / Recepción): solo puede leer (SELECT) agenda, clientes y precios; no modifica nada
GRANT SELECT ON checkpoint_caso_02.* TO 'rol_consulta_patasana';

-- Rol 2 (Operación / Veterinario): lee información general y agenda citas ÚNICAMENTE mediante
-- el procedimiento transaccional validado (no puede hacer INSERT/UPDATE/DELETE directo en tablas)
GRANT SELECT ON checkpoint_caso_02.* TO 'rol_operacion_patasana';
GRANT EXECUTE ON PROCEDURE checkpoint_caso_02.sp_registrar_cita_completa TO 'rol_operacion_patasana';
GRANT EXECUTE ON FUNCTION  checkpoint_caso_02.fn_total_cita              TO 'rol_operacion_patasana';

-- Rol 3 (Administrador): control total únicamente sobre la base de datos de PataSana (sin acceso a otros esquemas)
GRANT ALL PRIVILEGES ON checkpoint_caso_02.* TO 'rol_admin_patasana';

-- 3.2 Crea los 3 usuarios locales con sus credenciales si no existen previamente
CREATE USER IF NOT EXISTS 'recepcion_patasana'@'localhost' IDENTIFIED BY 'PataSana_123';
CREATE USER IF NOT EXISTS 'vet_patasana'@'localhost'       IDENTIFIED BY 'PataSana_123';
CREATE USER IF NOT EXISTS 'admin_patasana'@'localhost'     IDENTIFIED BY 'PataSana_123';

-- 3.3 Asigna cada rol al usuario correspondiente según su cargo en la veterinaria
GRANT 'rol_consulta_patasana'  TO 'recepcion_patasana'@'localhost';
GRANT 'rol_operacion_patasana' TO 'vet_patasana'@'localhost';
GRANT 'rol_admin_patasana'     TO 'admin_patasana'@'localhost';

-- 3.4 Activa el rol por defecto al iniciar sesión.
-- En MySQL 8.0+, un rol asignado con GRANT NO queda activo automáticamente al conectarse;
-- sin SET DEFAULT ROLE, el usuario entraría sin permisos efectivos.
SET DEFAULT ROLE 'rol_consulta_patasana'  TO 'recepcion_patasana'@'localhost';
SET DEFAULT ROLE 'rol_operacion_patasana' TO 'vet_patasana'@'localhost';
SET DEFAULT ROLE 'rol_admin_patasana'     TO 'admin_patasana'@'localhost';

-- 3.5 Evidencia de permisos (tomar captura de cada SHOW GRANTS para el documento):
-- Muestra los privilegios efectivos de cada usuario al operar con su rol asignado
SHOW GRANTS FOR 'recepcion_patasana'@'localhost' USING 'rol_consulta_patasana';
SHOW GRANTS FOR 'vet_patasana'@'localhost'       USING 'rol_operacion_patasana';
SHOW GRANTS FOR 'admin_patasana'@'localhost'     USING 'rol_admin_patasana';