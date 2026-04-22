use  interviewpractice;
----------------------------------------------
-- PART 1: 1. Basic to Intermediate Analysis
----------------------------------------------
-- 1. What is the total revenue generated each year?
SELECT 
        Year, Round(SUM(Net_Revenue_USD),2) AS Total_Revenue
        FROM fmcg_revenue_dataset
GROUP BY Year;

-- 2. What is the monthly revenue trend across all regions?
SELECT 
       Region, Month, ROUND(SUM(Net_Revenue_USD),2) AS Monthly_Revenue
FROM fmcg_revenue_dataset
GROUP BY Region, Month
ORDER BY Month DESC;

-- 3. Which top 5 countries generate the highest revenue?
SELECT 
		Country, ROUND(SUM(Net_Revenue_USD),2) AS Highest_Revenue 
FROM fmcg_revenue_dataset
GROUP BY Country
ORDER BY Highest_Revenue DESC
LIMIT 5;

-- 4. What is the total profit by brand?
SELECT 
      Brand, ROUND(SUM(Profit_Margin_Pct),2) AS Total_Profit
FROM fmcg_revenue_dataset
GROUP BY Brand;

-- 5. Which product category contributes the most to revenue?
SELECT 
       Product_Category, ROUND(SUM(Net_Revenue_USD),2) AS Total_Revenue
FROM fmcg_revenue_dataset
GROUP BY Product_Category
ORDER BY Total_Revenue DESC 
LIMIT 1;

-- 6. What is the average revenue per transaction?
SELECT 
    ROUND(SUM(Net_Revenue_USD) / COUNT(DISTINCT Order_ID), 2) AS Avg_Revenue_Per_Transaction
FROM fmcg_revenue_dataset;

-- 7. What is the total number of orders per region?
SELECT 
       Region, COUNT(*) AS Total_Order 
FROM fmcg_revenue_dataset
GROUP BY Region;

-- 8. Which region has the highest profit margin?
SELECT 
    Region,
    ROUND(SUM(Profit_USD) * 100 / SUM(Net_Revenue_USD), 2) AS Profit_Margin_Pct
FROM fmcg_revenue_dataset
GROUP BY Region
ORDER BY Profit_Margin_Pct DESC
LIMIT 1;

-- 9. What is the revenue contribution (%) by each brand?
SELECT 
    Brand,
    ROUND(SUM(Net_Revenue_USD), 2) AS Total_Revenue,
    ROUND(
        SUM(Net_Revenue_USD) * 100.0 / SUM(SUM(Net_Revenue_USD)) OVER (), 
    2) AS Revenue_Contribution_Pct
FROM fmcg_revenue_dataset
GROUP BY Brand
ORDER BY Revenue_Contribution_Pct DESC;

-- 10. Which are the bottom 5 performing products?
SELECT 
    Product_Name,
    ROUND(SUM(Net_Revenue_USD), 2) AS Total_Revenue
FROM fmcg_revenue_dataset
GROUP BY Product_Name
ORDER BY Total_Revenue ASC
LIMIT 5;
------------------------------------------
-- PART 2: Time Series & Trend Analysis
--------------------------------------------
-- 11. What is the month-over-month (MoM) growth in revenue?
WITH monthly_data AS (
    SELECT 
        Year, Month, SUM(Net_Revenue_USD) AS Monthly_Revenue
FROM fmcg_revenue_dataset
GROUP BY Year, Month
)
SELECT 
    Year, Month,
    ROUND(Monthly_Revenue, 2) AS Monthly_Revenue,
    ROUND((Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Year, Month)) 
        / LAG(Monthly_Revenue) OVER (ORDER BY Year, Month) * 100,2) AS MoM_Growth_Pct
FROM monthly_data;

-- 12. Calculate year-over-year (YoY) growth for each region.
WITH yearly_data AS (
    SELECT 
        Region, Year, SUM(Net_Revenue_USD) AS Yearly_Revenue
    FROM fmcg_revenue_dataset
    GROUP BY Region, Year
)
SELECT 
    Region, Year, ROUND(Yearly_Revenue, 2) AS Yearly_Revenue,
    ROUND((Yearly_Revenue - LAG(Yearly_Revenue) OVER (PARTITION BY Region ORDER BY Year)) 
        / LAG(Yearly_Revenue) OVER (PARTITION BY Region ORDER BY Year) * 100,2) AS YoY_Growth_Pct
FROM yearly_data
ORDER BY Region, Year;

-- 13. Identify seasonal trends in sales (peak months).
SELECT 
    Month, Month_Name,
    ROUND(SUM(Net_Revenue_USD), 2) AS Total_Revenue
FROM fmcg_revenue_dataset
GROUP BY Month, Month_Name
ORDER BY Total_Revenue DESC
LIMIT 3;

-- 14. Which month had the highest drop in revenue?
SELECT * FROM fmcg_revenue_dataset;
WITH monthly_data AS (
    SELECT 
        Year, Month, Month_Name,
        SUM(Net_Revenue_USD) AS Monthly_Revenue
    FROM fmcg_revenue_dataset
    GROUP BY Year, Month, Month_Name
),
revenue_change AS (
    SELECT Year, Month, Month_Name, Monthly_Revenue,
        Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Year, Month) AS Revenue_Change
    FROM monthly_data
)
SELECT *
FROM revenue_change
WHERE Revenue_Change IS NOT NULL
ORDER BY Revenue_Change ASC
LIMIT 1;

-- 15. Find rolling 3-month average revenue.
WITH monthly_data AS (
    SELECT 
        Year, Month, SUM(Net_Revenue_USD) AS Monthly_Revenue
    FROM fmcg_revenue_dataset
    GROUP BY Year, Month
)
SELECT 
    Year, Month, ROUND(Monthly_Revenue, 2) AS Monthly_Revenue,
    ROUND(AVG(Monthly_Revenue) OVER (ORDER BY Year, Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS Rolling_3M_Avg
FROM monthly_data
ORDER BY Year, Month;
------------------------------------------
-- PART 3:  Profitability & Cost Analysis
------------------------------------------
-- 16. Which products have negative profit?
SELECT * FROM fmcg_revenue_dataset;
SELECT 
	  Product_Name , Profit_USD
FROM fmcg_revenue_dataset
WHERE Profit_USD < 0;

-- 17. What is the profit margin per product/category?
SELECT 
    Product_Name,
    ROUND(SUM(Profit_USD), 2) AS Total_Profit,
    ROUND(SUM(Net_Revenue_USD), 2) AS Total_Revenue,
    ROUND(SUM(Profit_USD) * 100.0 / SUM(Net_Revenue_USD), 2) AS Profit_Margin_Pct
FROM fmcg_revenue_dataset
GROUP BY Product_Name
ORDER BY Profit_Margin_Pct DESC;

-- 18. Which region has the highest cost-to-revenue ratio?
SELECT 
    Region,
    ROUND((SUM(COGS_USD) + SUM(Logistics_Cost_USD) + SUM(Marketing_Spend_USD)) * 100.0 / SUM(Net_Revenue_USD), 2) AS Cost_to_Revenue_Pct
FROM fmcg_revenue_dataset
GROUP BY Region
ORDER BY Cost_to_Revenue_Pct DESC
LIMIT 1;

-- 19. Identify products where cost increased but revenue decreased.
WITH product_trends AS (
    SELECT Product_Name, Year, Month,
        ROUND(SUM(Net_Revenue_USD),2) AS Revenue,
        ROUND(SUM(COGS_USD + Logistics_Cost_USD + Marketing_Spend_USD),2) AS Cost
    FROM fmcg_revenue_dataset
    GROUP BY Product_Name, Year, Month
),
comparison AS (
    SELECT Product_Name, Year, Month, Revenue, Cost,
        LAG(Revenue) OVER (PARTITION BY Product_Name ORDER BY Year, Month) AS Prev_Revenue,
        LAG(Cost) OVER (PARTITION BY Product_Name ORDER BY Year, Month) AS Prev_Cost
    FROM product_trends
)
SELECT *
FROM comparison
WHERE 
    Revenue < Prev_Revenue   -- revenue decreased
    AND Cost > Prev_Cost;    -- cost increased
    
-- 20. Find top 10 products with highest profit margins.
SELECT * FROM fmcg_revenue_dataset;
SELECT 
    Product_Name,
    ROUND(SUM(Profit_USD), 2) AS Total_Profit,
    ROUND(SUM(Net_Revenue_USD), 2) AS Total_Revenue,
    ROUND(SUM(Profit_USD) * 100.0 / NULLIF(SUM(Net_Revenue_USD), 0),2) AS Profit_Margin_Pct
FROM fmcg_revenue_dataset
GROUP BY Product_Name
ORDER BY Profit_Margin_Pct DESC
LIMIT 10;
------------------------------------------
-- PART 4: Product & Brand Analysis
-------------------------------------------
-- 21: Which brand dominates each country?
SELECT * FROM fmcg_revenue_dataset;
WITH brand_country AS (
    SELECT Country, Brand, SUM(Net_Revenue_USD) AS Total_Revenue
    FROM fmcg_revenue_dataset
    GROUP BY Country, Brand
),
ranked AS (
    SELECT Country, Brand, Total_Revenue,
        DENSE_RANK() OVER(PARTITION BY Country ORDER BY Total_Revenue DESC) AS rnk
    FROM brand_country
)
SELECT Country, Brand,
    ROUND(Total_Revenue, 2) AS Total_Revenue
FROM ranked WHERE rnk = 1
ORDER BY Country;

-- 22. Find the best-selling product in each region.
WITH product_region AS (
    SELECT Region, Product_Name,
        SUM(Net_Revenue_USD) AS Total_Revenue
    FROM fmcg_revenue_dataset
    GROUP BY Region, Product_Name
),
ranked AS (
    SELECT Region, Product_Name, Total_Revenue,
        DENSE_RANK() OVER(PARTITION BY Region ORDER BY Total_Revenue DESC) AS rnk
    FROM product_region
)
SELECT Region, Product_Name,
    ROUND(Total_Revenue, 2) AS Total_Revenue
FROM ranked WHERE rnk = 1
ORDER BY Region;

-- 23: What is the revenue share of each product category over time?
SELECT * FROM fmcg_revenue_dataset;
SELECT 
    Year, Month, Product_Category,
    ROUND(SUM(Net_Revenue_USD), 2) AS Category_Revenue,
    ROUND(SUM(Net_Revenue_USD) * 100.0 / SUM(SUM(Net_Revenue_USD)) OVER (PARTITION BY Year, Month),2) AS Revenue_Share_Pct
FROM fmcg_revenue_dataset
GROUP BY Year, Month, Product_Category
ORDER BY Year, Month, Revenue_Share_Pct DESC;

-- 24: Identify underperforming brands across all regions.
SELECT 
    Brand,
    ROUND(SUM(Profit_USD), 2) AS Total_Profit
FROM fmcg_revenue_dataset
GROUP BY Brand
HAVING SUM(Profit_USD) < 0
ORDER BY Total_Profit ASC;
-------------------------------------------------------------------------------------------------------