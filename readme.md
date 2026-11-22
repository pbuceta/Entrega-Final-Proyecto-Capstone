# Análisis Exploratorio de Datos (EDA) en PostgreSQL — DataCorp E-Commerce

## 1. Contexto y Problema de Negocio
**DataCorp** es una tienda de comercio electrónico especializada en equipamiento de audio, video y periféricos para creadores de contenido y empresas en el Cono Sur. 

A medida que el volumen de operaciones creció durante el primer semestre de 2026, la gerencia comercial identificó la necesidad de pasar de reportes operativos básicos a un análisis estructurado que responda cuatro preguntas estratégicas:
1. **Concentración de ingresos:** ¿Quiénes son nuestros clientes más rentables y qué segmento lidera la facturación?
2. **Estacionalidad y rentabilidad:** ¿Cómo evolucionan las ventas mes a mes y qué margen bruto real estamos reteniendo?
3. **Eficiencia de catálogo:** ¿Qué productos tienen baja rotación y están inmovilizando capital?
4. **Liderazgo por vertical:** ¿Qué artículos dominan las ventas dentro de cada categoría?

---

## 2. Arquitectura y Flujo de Trabajo (Pipeline)
El proyecto implementa un flujo completo de ingeniería y análisis de datos directamente en **PostgreSQL**:

1. **Modelado Relacional (`estructura.sql`):** Diseño normalizado en 4 tablas (`clientes`, `productos`, `pedidos`, `detalle_pedidos`) con integridad referencial e índices estratégicos en llaves foráneas y filtros temporales.
2. **Limpieza y Transformación (Data Cleaning):**
   * **Estandarización de texto:** Unificación de categorías duplicadas por errores de tipeo (`'audio '` → `'Audio'`, `'Perifericos'` → `'Periféricos'`).
   * **Gestión de nulos (`COALESCE`):** Imputación de precios faltantes en catálogo y detalles de venta utilizando una regla de margen estándar ($1.5\times$ sobre costo unitario), y normalización de descuentos nulos a `$0.00`.
   * **Tipado estricto:** Conversión de fechas ingestadas como cadenas de texto (`VARCHAR`) hacia el tipo nativo `DATE` mediante `TO_DATE()`.
   * **Filtro de calidad comercial:** Exclusión explícita de órdenes con estado `'Cancelado'` para evitar distorsiones en los indicadores financieros.
3. **Análisis Avanzado (`analisis.sql`):** Uso de Common Table Expressions (CTEs), agregaciones multinivel (`GROUP BY`), lógica condicional (`CASE`) y Funciones de Ventana (`RANK()`, `LAG()`, `SUM() OVER()`).

---

## 3. Hallazgos Principales y Recomendaciones Ejecutivas

### A. Alta concentración de ingresos en el segmento Corporativo (Pareto)
* **Hallazgo:** Los clientes corporativos **Martín Rodríguez** ($1,617.00 USD en 4 órdenes) y **Lucas Méndez** ($1,770.00 USD en 2 órdenes) representan más del **55% de la facturación neta total** del semestre.
* **Acción recomendada:** Implementar un programa de cuentas clave (Key Account Management) con beneficios por volumen y reposición programada para el segmento Corporativo/Pyme en Uruguay y Argentina.

### B. Estacionalidad con picos en Enero y Febrero, y margen saludable
* **Hallazgo:** El margen bruto promedio se mantiene sólido por encima del **44%**, con picos de facturación en **Enero ($1,040 USD)** y **Febrero ($1,250 USD)** impulsados por compras de equipamiento completo (monitores + interfaces), seguidos de una estabilización en el segundo trimestre.
* **Acción recomendada:** Replicar las campañas de paquetes completos (*bundles*) utilizadas en el primer bimestre durante los meses de menor demanda (Marzo/Mayo).

### C. Baja rotación en accesorios de entrada
* **Hallazgo:** El **Panel Acústico Pack x6** (1 unidad), **Mouse Ergonómico Inalámbrico** (3 unidades) y **Brazo Articulado Micrófono** (2 unidades) presentan la menor rotación del catálogo.
* **Acción recomendada:** En lugar de liquidar el *Brazo Articulado* o el *Panel Acústico* con descuentos agresivos, ofrecerlos como *cross-selling* (venta cruzada con 15% de descuento) en el carrito cuando un usuario agregue un *Micrófono Condensador USB*.

### D. Dominio claro por categoría
* **Hallazgo:** En la vertical **Audio**, los *Auriculares Estudio Pro* y la *Interfaz de Audio 2x2* concentran más del 70% de los ingresos de la categoría, mientras que en **Monitores** un solo SKU concentra el 100% de la vertical.
* **Acción recomendada:** Ampliar la oferta de monitores con una gama media para capturar clientes del segmento *Consumidor* que hoy no acceden al modelo de $350 USD.

---

## 4. Cómo Ejecutar el Proyecto

### Requisitos previos
* PostgreSQL 14 o superior instalado.
* Cliente SQL (`psql`, pgAdmin 4 o DBeaver).

### Pasos de ejecución
1. Clonar este repositorio:
   ```bash
   git clone [https://github.com/tu-usuario/capstone_project.git](https://github.com/tu-usuario/capstone_project.git)
   cd capstone_project