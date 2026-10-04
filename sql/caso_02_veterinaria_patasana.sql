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

-- La consulta me permite determinar en una cita por cada cliente el total pagado por servicio, de acuerdo a la cantidad de servicios contratados según su tipo.
-- Es decir, además responde a la pregunta ¿Cuánto se pagó por cada servicio contratado en cada cita y qué cliente lo recibió?
SELECT ci.id_cita, c.nombre AS cliente, s.nombre AS servicio, dci.cantidad AS cantidad_servicios, dci.precio_unitario, (dci.cantidad * dci.precio_unitario) AS total_cancelado_servicio
FROM cita ci
INNER JOIN cliente c ON ci.id_cliente = c.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio;


-- La consulta permite identificar las citas en las que un cliente contrató más de 2 unidades de un servicio de la categoría 'consulta'
-- y mostrar 1 en Derecho_Descuento cuando aplica.
SELECT ci.id_cita, c.nombre AS cliente, dci.cantidad AS total_citas_por_servicio, (dci.cantidad > 2) AS derecho_descuento
FROM cita ci
JOIN cliente c ON c.id_cliente = ci.id_cliente
JOIN detalle_cita dci ON ci.id_cita = dci.id_cita
JOIN servicio s ON dci.id_servicio = s.id_servicio
WHERE s.categoria = 'consulta' AND dci.cantidad > 2;

-- La consulta busca mostrar los clientes que tienen más de una cita registrada
SELECT c.id_cliente, c.nombre
FROM cliente c
WHERE (SELECT COUNT(*) FROM cita ci
WHERE ci.id_cliente = c.id_cliente) > 1;

-- La consulta permite combinar en un solo listado los precios registrados en servicio y los precios unitarios registrados
-- en detalle_cita, indicando el origen de cada valor.
SELECT precio, 'servicio' AS tipo FROM servicio
UNION
SELECT precio_unitario, 'precio_unitario' AS tipo FROM detalle_cita;



