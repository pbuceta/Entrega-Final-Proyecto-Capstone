-- ============================================================================
-- PROYECTO CAPSTONE: ANÁLISIS EXPLORATORIO DE DATOS (EDA) EN POSTGRESQL
-- Archivo: analisis.sql
-- Descripción: Consultas analíticas para responder preguntas clave de negocio
--              sobre comportamiento de clientes, estacionalidad y catálogo.
-- ============================================================================

-- Verificación previa de integridad: confirmar que no quedan nulos en columnas críticas
SELECT 
    COUNT(*) AS total_detalles,
    COUNT(*) FILTER (WHERE precio_venta_unitario IS NULL) AS precios_nulos
FROM detalle_pedidos;


-- ============================================================================
-- CONSULTA 1: Top 5 Clientes por Gasto Total (LTV y Segmentación)
-- Objetivo de negocio: Identificar a los clientes de mayor valor para diseñar
-- programas de fidelización VIP y detectar dependencia de ingresos (Pareto).
-- ============================================================================
WITH ingresos_por_pedido AS (
    -- Calculamos el neto real por orden restando descuentos y excluyendo cancelaciones
    -- para no inflar artificialmente el valor del cliente
    SELECT 
        p.pedido_id,
        p.cliente_id,
        SUM(dp.cantidad * dp.precio_venta_unitario) - COALESCE(p.descuento_aplicado, 0) AS neto_pedido
    FROM pedidos p
    INNER JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
    WHERE p.estado = 'Completado'
    GROUP BY p.pedido_id, p.cliente_id, p.descuento_aplicado
)
SELECT 
    c.cliente_id,
    c.nombre AS cliente,
    c.pais,
    c.segmento,
    COUNT(ipp.pedido_id) AS ordenes_completadas,
    SUM(ipp.neto_pedido) AS gasto_total_usd,
    ROUND(AVG(ipp.neto_pedido), 2) AS ticket_promedio_usd,
    -- Clasificamos el nivel de lealtad según frecuencia y volumen de compra
    CASE 
        WHEN SUM(ipp.neto_pedido) >= 1200 THEN 'Tier 1 - VIP'
        WHEN SUM(ipp.neto_pedido) >= 500 THEN 'Tier 2 - Recurrente'
        ELSE 'Tier 3 - Estándar'
    END AS nivel_fidelidad
FROM clientes c
INNER JOIN ingresos_por_pedido ipp ON c.cliente_id = ipp.cliente_id
GROUP BY c.cliente_id, c.nombre, c.pais, c.segmento
ORDER BY gasto_total_usd DESC
LIMIT 5;


-- ============================================================================
-- CONSULTA 2: Evolución de Ventas Totales y Margen Bruto por Mes
-- Objetivo de negocio: Detectar estacionalidad, crecimiento mensual (MoM)
-- y evaluar si las promociones están erosionando la rentabilidad.
-- ============================================================================
WITH resumen_mensual AS (
    -- Agrupamos a nivel de mes calendario usando DATE_TRUNC para facilitar series temporales
    SELECT 
        DATE_TRUNC('month', p.fecha_pedido)::DATE AS mes,
        COUNT(DISTINCT p.pedido_id) AS cantidad_pedidos,
        SUM(dp.cantidad * dp.precio_venta_unitario) AS venta_bruta,
        SUM(dp.cantidad * pr.costo_unitario) AS costo_total
    FROM pedidos p
    INNER JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
    INNER JOIN productos pr ON dp.producto_id = pr.producto_id
    WHERE p.estado = 'Completado'
    GROUP BY DATE_TRUNC('month', p.fecha_pedido)
)
SELECT 
    TO_CHAR(mes, 'YYYY-MM') AS periodo,
    cantidad_pedidos,
    venta_bruta AS ingresos_brutos_usd,
    (venta_bruta - costo_total) AS margen_bruto_usd,
    ROUND(((venta_bruta - costo_total) / NULLIF(venta_bruta, 0)) * 100, 2) AS porcentaje_margen,
    -- Comparamos contra el mes anterior usando LAG() para medir tracción de ventas
    ROUND(
        ((venta_bruta - LAG(venta_bruta) OVER (ORDER BY mes)) 
        / NULLIF(LAG(venta_bruta) OVER (ORDER BY mes), 0)) * 100, 
    2) AS variacion_mensual_pct
FROM resumen_mensual
ORDER BY mes ASC;


-- ============================================================================
-- CONSULTA 3: Los 3 Productos Menos Vendidos (Rotación de Inventario)
-- Objetivo de negocio: Identificar capital inmovilizado o falta de tracción
-- comercial para decidir liquidaciones, combos (bundling) o descontinuación.
-- ============================================================================
SELECT 
    pr.producto_id,
    pr.nombre_producto,
    pr.categoria,
    pr.precio_lista,
    -- Usamos LEFT JOIN + COALESCE para incluir productos con cero ventas históricas
    COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas,
    COALESCE(SUM(dp.cantidad * dp.precio_venta_unitario), 0) AS ingresos_generados_usd
FROM productos pr
LEFT JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
LEFT JOIN pedidos p ON dp.pedido_id = p.pedido_id AND p.estado = 'Completado'
GROUP BY pr.producto_id, pr.nombre_producto, pr.categoria, pr.precio_lista
ORDER BY unidades_vendidas ASC, ingresos_generados_usd ASC
LIMIT 3;


-- ============================================================================
-- CONSULTA 4: Ranking de Pedidos/Productos por Categoría con RANK()
-- Objetivo de negocio: Determinar qué productos lideran la facturación dentro
-- de cada vertical de negocio sin perder el desglose por categoría.
-- ============================================================================
WITH ventas_por_producto_categoria AS (
    SELECT 
        pr.categoria,
        pr.nombre_producto,
        COUNT(DISTINCT p.pedido_id) AS presencia_en_ordenes,
        SUM(dp.cantidad) AS total_unidades,
        SUM(dp.cantidad * dp.precio_venta_unitario) AS facturacion_total
    FROM productos pr
    INNER JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
    INNER JOIN pedidos p ON dp.pedido_id = p.pedido_id
    WHERE p.estado = 'Completado'
    GROUP BY pr.categoria, pr.nombre_producto
)
SELECT 
    categoria,
    -- RANK() particiona por categoría para identificar al producto estrella de cada línea
    RANK() OVER (PARTITION BY categoria ORDER BY facturacion_total DESC) AS ranking_categoria,
    nombre_producto,
    presencia_en_ordenes,
    total_unidades,
    facturacion_total AS facturacion_usd,
    -- Calculamos el peso porcentual del producto sobre el total de su propia categoría
    ROUND(
        (facturacion_total / SUM(facturacion_total) OVER (PARTITION BY categoria)) * 100, 
    2) AS participacion_categoria_pct
FROM ventas_por_producto_categoria
ORDER BY categoria ASC, ranking_categoria ASC;