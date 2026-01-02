# MintClassics Warehouse Analysis

## Project Overview

This project analyzes MintClassics’ warehouse operations to identify potential optimization opportunities, including the possibility of eliminating one warehouse without affecting the 24-hour delivery SLA. Historical product, order, and warehouse data were analyzed to calculate KPIs such as revenue, units sold, inventory, and inventory turnover.

![alt text](image.png)
---

## Data Sources

- **Products**: Product details, stock levels, vendor, and pricing.
- **Warehouses**: Warehouse codes, capacity percentages, and names.
- **OrderDetails**: Quantity ordered, price per unit, and order lines.
- **Orders**: Customer orders with order numbers.
- **Customers**: Customer information linked to orders.

---

## Approach & Queries

### 1. Create Temporary Table
```sql
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
LEFT JOIN mintclassics.warehouses w ON p.warehouseCode=w.warehouseCode
LEFT JOIN mintclassics.orderdetails od ON p.productCode=od.productCode
LEFT JOIN mintclassics.orders o ON o.orderNumber=od.orderNumber
LEFT JOIN mintclassics.customers c ON c.customerNumber=o.customerNumber;
```

### 2. Preview Temp Table
```sql
SELECT * FROM mintclassics.temp_data;
```

### 3. Most Selling Products
```sql
SELECT productName, productLine, quantityOrdered
FROM mintclassics.temp_data
ORDER BY quantityOrdered DESC;
```

### 4. Total Quantity in Stock per Warehouse
```sql
SELECT warehouseName, SUM(quantityInStock) AS total_stock
FROM mintclassics.temp_data
GROUP BY warehouseName
ORDER BY total_stock DESC;
```

### 5. Revenue per Warehouse
```sql
SELECT warehouseName, SUM(quantityOrdered*priceEach) AS total_rev
FROM mintclassics.temp_data
GROUP BY warehouseName
ORDER BY total_rev DESC;
```

### 6. Revenue Share % per Warehouse
```sql
SELECT t.warehouseName, t.total_rev,
       CONCAT(ROUND((t.total_rev / SUM(t.total_rev) OVER () )*100,0),'%') AS revenue_share
FROM (
    SELECT warehouseName, SUM(quantityOrdered * priceEach) AS total_rev
    FROM mintclassics.temp_data
    GROUP BY warehouseName
) t
ORDER BY revenue_share DESC;
```

### 7. Demand vs Capacity Analysis
```sql
WITH demand AS (
    SELECT w.warehouseName, SUM(od.quantityOrdered) AS total_demand
    FROM mintclassics.orderdetails od
    JOIN mintclassics.products p ON od.productCode = p.productCode
    JOIN mintclassics.warehouses w ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseName
),
capacity AS (
    SELECT w.warehouseName, SUM(p.quantityInStock) AS total_stock
    FROM mintclassics.products p
    JOIN mintclassics.warehouses w ON p.warehouseCode = w.warehouseCode
    GROUP BY w.warehouseName
)
SELECT d.warehouseName, c.total_stock, d.total_demand,
       c.total_stock - d.total_demand AS capacity_gap,
       d.total_demand / c.total_stock AS inventory_turnover
FROM demand d
JOIN capacity c ON d.warehouseName = c.warehouseName
ORDER BY inventory_turnover DESC;
```

### 8. Distinct Product Lines per Warehouse
```sql
SELECT DISTINCT(ProductLine), WarehouseName
FROM mintclassics.temp_data;
```

### 9. Revenue of West Warehouse Product Line
```sql
SELECT p.productLine, SUM(od.quantityOrdered * od.priceEach) AS revenue
FROM mintclassics.products p
JOIN mintclassics.orderdetails od ON p.productCode = od.productCode
JOIN mintclassics.warehouses w ON p.warehouseCode = w.warehouseCode
WHERE w.warehouseName = 'West'
GROUP BY p.productLine;
```

### 10. Units Sold per Warehouse
```sql
SELECT w.warehouseName, SUM(od.quantityOrdered) AS units_sold
FROM mintclassics.orderdetails od
JOIN mintclassics.products p ON od.productCode = p.productCode
JOIN mintclassics.warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY w.warehouseName;
```

---

## Key Findings

- **Revenue Distribution:** East (40%), North (22%), South (20%), West (19%)
- **Inventory Turnover:** South highest (0.28), East lowest (0.16), West low (0.18)
- **Units Sold:** West = 22,933, which can be absorbed by other warehouses without exceeding stock
- **Unique Product Lines:** West has Vintage Cars, can be redistributed

---

## Recommendation

**Eliminate the West Warehouse**:

- Lowest revenue contribution and low inventory turnover indicate underutilization.
- Remaining warehouses (East, North, South) have sufficient capacity to absorb West’s demand.
- Vintage Cars stock will be redistributed to East and North warehouses to maintain 24-hour delivery.
- Monitor inventory after closure to mitigate operational risk.

---

## Conclusion

Closing West optimizes warehouse operations, reduces costs, and maintains SLA compliance. This data-driven approach uses KPIs such as revenue, inventory turnover, and demand vs capacity analysis to justify the decision.

