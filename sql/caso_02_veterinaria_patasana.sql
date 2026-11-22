-- =====================================================================
-- CASO 02 · Veterinaria PataSana
-- Proyecto Final Integrador | Bases de Datos II (30%)
-- Veterinaria de barrio que agenda citas de consulta, vacunación y peluquería canina.
-- Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]
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

-- ---------------------------------------------------------------------
-- 3. ROLES Y PERMISOS (5%)
-- Objetivo: Aplicar el principio del mínimo privilegio en Veterinaria PataSana.
-- Cada rol agrupa SOLO los permisos estrictamente necesarios para su cargo,
-- evitando que un usuario borre datos o altere precios por error o abuso.
-- ---------------------------------------------------------------------

-- 3.1 Crea los 3 roles (paquetes de permisos) si no existen previamente en el servidor
CREATE ROLE IF NOT EXISTS &#39;rol_consulta_patasana&#39;, &#39;rol_operacion_patasana&#39;,
&#39;rol_admin_patasana&#39;;

-- Rol 1 (Consulta / Recepción): solo puede leer (SELECT) agenda, clientes y precios; no
modifica nada
GRANT SELECT ON checkpoint_caso_02.* TO &#39;rol_consulta_patasana&#39;;

-- Rol 2 (Operación / Veterinario): lee información general y agenda citas ÚNICAMENTE
mediante
-- el procedimiento transaccional validado (no puede hacer INSERT/UPDATE/DELETE directo
en tablas)
GRANT SELECT ON checkpoint_caso_02.* TO &#39;rol_operacion_patasana&#39;;
GRANT EXECUTE ON PROCEDURE checkpoint_caso_02.sp_registrar_cita_completa TO
&#39;rol_operacion_patasana&#39;;
GRANT EXECUTE ON FUNCTION checkpoint_caso_02.fn_total_cita TO
&#39;rol_operacion_patasana&#39;;

-- Rol 3 (Administrador): control total únicamente sobre la base de datos de PataSana (sin
acceso a otros esquemas)
GRANT ALL PRIVILEGES ON checkpoint_caso_02.* TO &#39;rol_admin_patasana&#39;;

-- 3.2 Crea los 3 usuarios locales con sus credenciales si no existen previamente
CREATE USER IF NOT EXISTS &#39;recepcion_patasana&#39;@&#39;localhost&#39; IDENTIFIED BY
&#39;PataSana_123&#39;;
CREATE USER IF NOT EXISTS &#39;vet_patasana&#39;@&#39;localhost&#39; IDENTIFIED BY
&#39;PataSana_123&#39;;
CREATE USER IF NOT EXISTS &#39;admin_patasana&#39;@&#39;localhost&#39; IDENTIFIED BY
&#39;PataSana_123&#39;;

-- 3.3 Asigna cada rol al usuario correspondiente según su cargo en la veterinaria
GRANT &#39;rol_consulta_patasana&#39; TO &#39;recepcion_patasana&#39;@&#39;localhost&#39;;
GRANT &#39;rol_operacion_patasana&#39; TO &#39;vet_patasana&#39;@&#39;localhost&#39;;
GRANT &#39;rol_admin_patasana&#39; TO &#39;admin_patasana&#39;@&#39;localhost&#39;;

-- 3.4 Activa el rol por defecto al iniciar sesión.
-- En MySQL 8.0+, un rol asignado con GRANT NO queda activo automáticamente al
conectarse;
-- sin SET DEFAULT ROLE, el usuario entraría sin permisos efectivos.
SET DEFAULT ROLE &#39;rol_consulta_patasana&#39; TO &#39;recepcion_patasana&#39;@&#39;localhost&#39;;
SET DEFAULT ROLE &#39;rol_operacion_patasana&#39; TO &#39;vet_patasana&#39;@&#39;localhost&#39;;
SET DEFAULT ROLE &#39;rol_admin_patasana&#39; TO &#39;admin_patasana&#39;@&#39;localhost&#39;;

-- 3.5 Evidencia de permisos (tomar captura de cada SHOW GRANTS para el documento):
-- Muestra los privilegios efectivos de cada usuario al operar con su rol asignado
SHOW GRANTS FOR &#39;recepcion_patasana&#39;@&#39;localhost&#39; USING &#39;rol_consulta_patasana&#39;;
SHOW GRANTS FOR &#39;vet_patasana&#39;@&#39;localhost&#39; USING &#39;rol_operacion_patasana&#39;;
SHOW GRANTS FOR &#39;admin_patasana&#39;@&#39;localhost&#39; USING &#39;rol_admin_patasana&#39;;