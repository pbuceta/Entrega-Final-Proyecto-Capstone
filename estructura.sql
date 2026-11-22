-- ============================================================================
-- PROYECTO CAPSTONE: ANÁLISIS EXPLORATORIO DE DATOS (EDA) EN POSTGRESQL
-- Archivo: estructura.sql
-- Descripción: Creación de esquema, carga de datos crudos (con anomalías)
--              y pipeline de limpieza y normalización.
-- ============================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS
-- Nota: Ejecutar esta línea conectándose primero a la base 'postgres'
CREATE DATABASE capstone_project;

-- Conectarse a capstone_project antes de continuar (\c capstone_project)

-- ============================================================================
-- 2. MODELADO DE TABLAS (Esquema E-Commerce DataCorp)
-- ============================================================================

DROP TABLE IF EXISTS detalle_pedidos CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- Tabla maestra de clientes
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    pais VARCHAR(50),
    segmento VARCHAR(30),
    fecha_registro DATE NOT NULL
);

-- Tabla maestra de productos
-- Se permite NULL en precio_lista inicialmente para simular datos sucios de carga
CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(120) NOT NULL,
    categoria VARCHAR(50),
    precio_lista NUMERIC(10, 2),
    costo_unitario NUMERIC(10, 2) NOT NULL
);

-- Tabla de cabecera de órdenes
-- fecha_pedido se ingesta inicialmente como VARCHAR para limpiar formatos inconsistentes
CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(cliente_id),
    fecha_pedido_raw VARCHAR(20),
    fecha_pedido DATE,
    estado VARCHAR(20) NOT NULL,
    descuento_aplicado NUMERIC(10, 2)
);

-- Tabla transaccional de ítems por pedido
CREATE TABLE detalle_pedidos (
    detalle_id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(pedido_id),
    producto_id INT REFERENCES productos(producto_id),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_venta_unitario NUMERIC(10, 2)
);

-- ============================================================================
-- 3. INSERCIÓN DE DATOS (Incluye valores NULL y formatos sucios intencionales)
-- ============================================================================

INSERT INTO clientes (nombre, email, pais, segmento, fecha_registro) VALUES
('Martín Rodríguez', 'martin.r@email.com', 'Uruguay', 'Corporativo', '2025-01-15'),
('Sofía Fernández', 'sofia.f@email.com', 'Argentina', 'Consumidor', '2025-02-10'),
('Lucas Méndez', 'lucas.m@email.com', 'Uruguay', 'Corporativo', '2025-02-22'),
('Valentina Silva', 'valen.s@email.com', 'Chile', NULL, '2025-03-05'),
('Diego Torres', 'diego.t@email.com', 'Uruguay', 'Consumidor', '2025-03-18'),
('Camila Gómez', 'camila.g@email.com', 'Argentina', 'Pyme', '2025-04-02'),
('Sebastián Acosta', 'seba.a@email.com', 'Uruguay', 'Pyme', '2025-04-19'),
('Lucía Pereira', 'lucia.p@email.com', NULL, 'Consumidor', '2025-05-01');

INSERT INTO productos (nombre_producto, categoria, precio_lista, costo_unitario) VALUES
('Auriculares Estudio Pro', 'Audio', 180.00, 95.00),
('Micrófono Condensador USB', 'audio ', 145.00, 70.00),       -- Categoría sucia (minúscula y espacio)
('Interfaz de Audio 2x2', 'Audio', 220.00, 115.00),
('Monitor Curvo 27"', 'Monitores', 350.00, 210.00),
('Teclado Mecánico RGB', 'Periféricos', 110.00, 52.00),
('Mouse Ergonómico Inalámbrico', 'Perifericos', NULL, 28.00), -- Categoría sin tilde + precio NULL
('Webcam 4K Streaming', 'Video', 160.00, 85.00),
('Brazo Articulado Micrófono', 'Accesorios', 45.00, 18.00),
('Cable XLR Balanceado 3m', 'Accesorios', 20.00, 6.00),
('Panel Acústico Pack x6', 'Accesorios', NULL, 30.00);          -- Precio NULL

INSERT INTO pedidos (cliente_id, fecha_pedido_raw, estado, descuento_aplicado) VALUES
(1, '2026-01-10', 'Completado', 20.00),
(1, '2026-01-25', 'Completado', NULL),
(2, '2026-02-04', 'Completado', 0.00),
(3, '2026-02-14', 'Completado', 50.00),
(1, '2026-03-02', 'Completado', NULL),
(4, '2026-03-15', 'Completado', 10.00),
(5, '2026-03-28', 'Cancelado', 0.00),   -- Pedido cancelado para filtrar en análisis de ingresos reales
(6, '2026-04-08', 'Completado', NULL),
(7, '2026-04-19', 'Completado', 15.00),
(2, '2026-05-03', 'Completado', NULL),
(3, '2026-05-12', 'Completado', 30.00),
(8, '2026-05-20', 'Completado', 0.00),
(1, '2026-06-05', 'Completado', 25.00),
(6, '2026-06-18', 'Completado', NULL);

INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_venta_unitario) VALUES
-- Pedido 1 (Martín - Ene)
(1, 1, 2, 180.00), (1, 3, 1, 220.00),
-- Pedido 2 (Martín - Ene)
(2, 4, 1, 350.00), (2, 5, 1, 110.00),
-- Pedido 3 (Sofía - Feb)
(3, 2, 1, 145.00), (3, 8, 1, 45.00),
-- Pedido 4 (Lucas - Feb)
(4, 4, 2, 350.00), (4, 1, 2, 180.00),
-- Pedido 5 (Martín - Mar)
(5, 7, 1, 160.00), (5, 6, 2, NULL), -- Precio NULL heredado del catálogo
-- Pedido 6 (Valentina - Mar)
(6, 5, 1, 110.00), (6, 9, 2, 20.00),
-- Pedido 7 (Diego - Mar - Cancelado)
(7, 4, 3, 350.00),
-- Pedido 8 (Camila - Abr)
(8, 3, 2, 220.00), (8, 2, 2, 145.00),
-- Pedido 9 (Sebastián - Abr)
(9, 7, 1, 160.00), (9, 10, 1, NULL), -- Precio NULL heredado del catálogo
-- Pedido 10 (Sofía - May)
(10, 1, 1, 180.00),
-- Pedido 11 (Lucas - May)
(11, 3, 2, 220.00), (11, 4, 1, 350.00),
-- Pedido 12 (Lucía - May)
(12, 6, 1, NULL), (12, 8, 1, 45.00),
-- Pedido 13 (Martín - Jun)
(13, 2, 2, 145.00), (13, 9, 3, 20.00),
-- Pedido 14 (Camila - Jun)
(14, 5, 2, 110.00), (14, 7, 1, 160.00);

-- ============================================================================
-- 4. ETAPA DE LIMPIEZA Y TRANSFORMACIÓN DE DATOS (Data Cleaning)
-- ============================================================================

-- 4.1 Normalizar categorías duplicadas por espacios o falta de tildes
-- Evita que 'Audio' y 'audio ' se agrupen por separado en reportes ejecutivos
UPDATE productos
SET categoria = CASE
    WHEN TRIM(LOWER(categoria)) = 'audio' THEN 'Audio'
    WHEN TRIM(LOWER(categoria)) IN ('perifericos', 'periféricos') THEN 'Periféricos'
    ELSE TRIM(categoria)
END;

-- 4.2 Imputar precios nulos en el catálogo usando margen estándar del 50% sobre costo
-- Evita subestimar ingresos por registros incompletos del proveedor
UPDATE productos
SET precio_lista = COALESCE(precio_lista, ROUND(costo_unitario * 1.50, 2))
WHERE precio_lista IS NULL;

-- 4.3 Propagar precios limpios hacia los detalles de pedido con valores NULL
UPDATE detalle_pedidos dp
SET precio_venta_unitario = p.precio_lista
FROM productos p
WHERE dp.producto_id = p.producto_id
  AND dp.precio_venta_unitario IS NULL;

-- 4.4 Convertir fechas de texto a tipo DATE nativo y limpiar descuentos nulos
UPDATE pedidos
SET fecha_pedido = TO_DATE(fecha_pedido_raw, 'YYYY-MM-DD'),
    descuento_aplicado = COALESCE(descuento_aplicado, 0.00);

-- 4.5 Imputar valores faltantes en dimensiones de clientes para no perder filas en GROUP BY
UPDATE clientes
SET pais = COALESCE(pais, 'No especificado'),
    segmento = COALESCE(segmento, 'Consumidor');

-- Creación de índices en llaves foráneas y columnas frecuentes de filtrado
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_fecha_estado ON pedidos(fecha_pedido, estado);
CREATE INDEX idx_detalle_pedido ON detalle_pedidos(pedido_id);
CREATE INDEX idx_detalle_producto ON detalle_pedidos(producto_id);