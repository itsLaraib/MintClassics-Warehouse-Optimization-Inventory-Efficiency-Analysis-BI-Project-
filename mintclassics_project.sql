CREATE TEMPORARY TABLE mintclassics.temp_data AS
SELECT 
	p.productCode,
    p.productName,
	p.productLine, 
	p.productScale,
	p.productVendor, 
	p.productDescription,
	p.quantityInStock,
	p.buyPrice, 
	p.MSRP,
    
	w.warehouseCode,
    w.warehouseName,
    w.warehousePctCap,
    
	od.orderNumber,
	od.quantityOrdered,
	od.priceEach,
	od.orderLineNumber
FROM mintclassics.products p
LEFT JOIN mintclassics.warehouses w
	ON p.warehouseCode=w.warehouseCode
LEFT JOIN mintclassics.orderdetails od
	ON p.productCode=od.productCode
LEFT JOIN mintclassics.orders o
	ON o.orderNumber=od.orderNumber
LEFT JOIN mintclassics.customers c
	ON c.customerNumber=o.customerNumber;
    
SELECT *
FROM mintclassics.temp_data;

-- Most selling product
SELECT productName,
	   productLine,
	   quantityOrdered
FROM mintclassics.temp_data
ORDER BY quantityOrdered DESC;

-- Most quantity in warehouse 
SELECT 
	warehouseName,
	SUM(quantityInStock)
FROM mintclassics.temp_data
GROUP BY warehouseName
ORDER BY SUM(quantityInStock) DESC;

-- revenue from each warehouse 
SELECT 
	warehouseName,
    SUM(quantityOrdered*priceEach) as total_rev
FROM mintclassics.temp_data
GROUP BY warehouseName
ORDER BY total_rev DESC;


-- %age sales from each warehouse
SELECT
    t.warehouseName,
    t.total_rev,
    CONCAT(ROUND((t.total_rev / SUM(t.total_rev) OVER () )*100,0),'%') AS revenue_share
FROM (
    SELECT
        warehouseName,
        SUM(quantityOrdered * priceEach) AS total_rev
    FROM mintclassics.temp_data
    GROUP BY warehouseName
) t
ORDER BY revenue_share DESC;

-- Demand vs Capacity Analysis
WITH demand AS (
    SELECT
        w.warehouseName,
        SUM(od.quantityOrdered) AS total_demand
    FROM mintclassics.orderdetails od
    JOIN mintclassics.products p
        ON od.productCode = p.productCode
    JOIN mintclassics.warehouses w
        ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseName
),
capacity AS (
    SELECT
        w.warehouseName,
        SUM(p.quantityInStock) AS total_stock
    FROM mintclassics.products p
    JOIN mintclassics.warehouses w
        ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseName
)
SELECT
    d.warehouseName,
    c.total_stock,
    d.total_demand,
    c.total_stock - d.total_demand AS capacity_gap,
    d.total_demand / c.total_stock AS inventory_turnover
FROM demand d
JOIN capacity c
    ON d.warehouseName = c.warehouseName
ORDER BY inventory_turnover DESC;


SELECT DISTINCT(ProductLine),
		WarehouseName
FROM mintclassics.temp_data;


SELECT
    p.productLine,
    SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM mintclassics.products p
JOIN mintclassics.orderdetails od
    ON p.productCode = od.productCode
JOIN mintclassics.warehouses w
    ON p.warehouseCode = w.warehouseCode
WHERE w.warehouseName = 'West'
GROUP BY p.productLine;

SELECT
    w.warehouseName,
    SUM(od.quantityOrdered) AS units_sold
FROM mintclassics.orderdetails od
JOIN mintclassics.products p
    ON od.productCode = p.productCode
JOIN mintclassics.warehouses w
    ON p.warehouseCode = w.warehouseCode
GROUP BY w.warehouseName;