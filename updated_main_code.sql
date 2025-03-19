-- Create 5 tables :transactions, product_list, inventory, projection, even_list
-- 1. transaction table
CREATE TABLE transactions(
	log_date	VARCHAR
,	asin	VARCHAR
,	sku	VARCHAR
,	country	VARCHAR
,	channel	VARCHAR
,	label_currency	VARCHAR
,	glance_view	VARCHAR
,	ordered_units	VARCHAR
,	orders	VARCHAR
,	ordered_gmv	VARCHAR
,	ordered_revenue	VARCHAR
,	shipped_units	VARCHAR
,	shipped_gmv	VARCHAR
,	sb_impressions	VARCHAR
,	sb_clicks	VARCHAR
,	sb_ordered_units	VARCHAR
,	sb_orders	VARCHAR
,	sb_ordered_gmv	VARCHAR
,	sb_spend	VARCHAR
,	sd_impressions	VARCHAR
,	sd_clicks	VARCHAR
,	sd_ordered_units	VARCHAR
,	sd_orders	VARCHAR
,	sd_ordered_gmv	VARCHAR
,	sd_spend	VARCHAR
,	sp_impressions	VARCHAR
,	sp_clicks	VARCHAR
,	sp_ordered_units	VARCHAR
,	sp_orders	VARCHAR
,	sp_ordered_gmv	VARCHAR
,	sp_spend	VARCHAR
,	sbv_impressions	VARCHAR
,	sbv_clicks	VARCHAR
,	sbv_ordered_units	VARCHAR
,	sbv_orders	VARCHAR
,	sbv_ordered_gmv	VARCHAR
,	sbv_spend	VARCHAR
,	dsp_halo_impressions	VARCHAR
,	dsp_halo_clicks	VARCHAR
,	dsp_halo_ordered_units	VARCHAR
,	dsp_halo_orders	VARCHAR
,	dsp_halo_ordered_gmv	VARCHAR
,	dsp_halo_spend	VARCHAR
,	dsp_promoted_impressions	VARCHAR
,	dsp_promoted_clicks	VARCHAR
,	dsp_promoted_ordered_units	VARCHAR
,	dsp_promoted_orders	VARCHAR
,	dsp_promoted_ordered_gmv	VARCHAR
,	dsp_promoted_spend	VARCHAR
,	coupon_spend	VARCHAR
,	vc_promo_ordered_units	VARCHAR
,	vc_promo_ordered_gmv	VARCHAR
,	vc_promo_spend	VARCHAR
,	vm_promo_ordered_units	VARCHAR
,	vm_promo_ordered_gmv	VARCHAR
,	vm_promo_spend	VARCHAR
,	shipped_gross_profit	VARCHAR
,	ordered_gross_profit	VARCHAR
,	pic_sale	VARCHAR
,	sale_team	VARCHAR
);

--2 product list

CREATE TABLE product_list(
	sku	VARCHAR
,	category	VARCHAR
,	subcategory	VARCHAR
,	launching_date	VARCHAR
,	first_ordered_date	VARCHAR
,	first_di_onboard_date	VARCHAR
,	first_di_ordered_date	VARCHAR
,	first_di_confirmed_date	VARCHAR
,	first_po_di_quantity	VARCHAR
,	first_etd_date	VARCHAR
,	first_atd_date	VARCHAR
,	first_eta_date	VARCHAR
,	first_ata_date	VARCHAR
,	estimated_first_stock_date	VARCHAR
,	first_stock_available_date	VARCHAR
,	first_shipped_date	VARCHAR

);

--3 Inventory
CREATE TABLE inventory(
	sku	VARCHAR
,	country	VARCHAR
,	inventory_UTD	VARCHAR
,	incoming_24	VARCHAR
,	incoming_25	VARCHAR
,	incoming_26	VARCHAR
,	incoming_27	VARCHAR
,	incoming_28	VARCHAR
,	incoming_29	VARCHAR
,	incoming_30	VARCHAR
,	incoming_31	VARCHAR
,	incoming_32	VARCHAR
,	incoming_33	VARCHAR
,	incoming_34	VARCHAR
,	incoming_35	VARCHAR
,	incoming_36	VARCHAR
,	incoming_37	VARCHAR
,	incoming_38	VARCHAR
,	incoming_39	VARCHAR
,	incoming_40	VARCHAR
,	incoming_41	VARCHAR
,	incoming_42	VARCHAR
,	incoming_43	VARCHAR
,	incoming_44	VARCHAR
,	incoming_45	VARCHAR
,	incoming_46	VARCHAR
,	incoming_47	VARCHAR
,	incoming_48	VARCHAR
,	incoming_49	VARCHAR
,	incoming_50	VARCHAR
,	incoming_51	VARCHAR
,	incoming_52	VARCHAR
,	total_incoming	VARCHAR
);

--4 projection
-- Real Sales column is not standardized as PostgreSQL does not allow space in coulumn name
CREATE TABLE projection(
	country	VARCHAR
,	channel	VARCHAR
,	Month	VARCHAR
,	SKU	VARCHAR
,	Real_sales VARCHAR
,	Revenue	VARCHAR
,	GMV	VARCHAR
,	SEM	VARCHAR
,	DSP	VARCHAR
,	Promotion VARCHAR
);


--5. even_list
CREATE TABLE even_list(
	Country	VARCHAR
,	Platform	VARCHAR
,	Event	VARCHAR
,	Start_date	VARCHAR
,	End_date	VARCHAR
);

-- >> Column name can not have space in it
-- >> Need to change data type on date
-- Join table

SELECT *
FROM transactions AS t
LEFT JOIN product_list AS pl ON t.sku = pl.sku
LEFT JOIN projection AS p ON t.sku = p.sku
LEFT JOIN inventory AS i ON t.sku = i.sku;

--CREATE NEW MASTER_DATA
CREATE TABLE master_data AS
SELECT 
    t.*,  -- All columns from transactions
    pl.category, 
    pl.subcategory, 
	p.month,
    p.real_sales, 
    p.revenue, 
    p.gmv, 
    p.sem, 
    p.dsp, 
    p.promotion, 
    i.inventory_UTD, 
    i.total_incoming
FROM transactions AS t
LEFT JOIN product_list AS pl ON t.sku = pl.sku
LEFT JOIN projection AS p ON t.sku = p.sku
LEFT JOIN inventory AS i ON t.sku = i.sku;

-- Master_data show

SELECT * 
FROM master_data;

-- Create spend column by sales channels
ALTER TABLE master_data 
ADD COLUMN ad_spent NUMERIC(10,2),
ADD COLUMN promotion_spent NUMERIC(10,2),
ADD COLUMN spend NUMERIC(10,2),
ADD COLUMN transactions_date DATE;

--Update ad_spend, promo_spend, spend (convert to suitable data type for calculation, also handle null value)
UPDATE master_data
SET ad_spent = COALESCE(sbv_spend::NUMERIC, 0) 
             + COALESCE(sp_spend::NUMERIC, 0) 
             + COALESCE(sd_spend::NUMERIC, 0) 
             + COALESCE(sb_spend::NUMERIC, 0) 
             + COALESCE(dsp_halo_spend::NUMERIC, 0) 
             + COALESCE(dsp_promoted_spend::NUMERIC, 0),

    promotion_spent = COALESCE(coupon_spend::NUMERIC, 0) 
                    + COALESCE(vc_promo_spend::NUMERIC, 0) 
                    + COALESCE(vm_promo_spend::NUMERIC, 0),

    spend = (COALESCE(sbv_spend::NUMERIC, 0) 
           + COALESCE(sp_spend::NUMERIC, 0) 
           + COALESCE(sd_spend::NUMERIC, 0) 
           + COALESCE(sb_spend::NUMERIC, 0) 
           + COALESCE(dsp_halo_spend::NUMERIC, 0) 
           + COALESCE(dsp_promoted_spend::NUMERIC, 0))
           + (COALESCE(coupon_spend::NUMERIC, 0) 
           + COALESCE(vc_promo_spend::NUMERIC, 0) 
           + COALESCE(vm_promo_spend::NUMERIC, 0)),

	transactions_date = log_date :: DATE;
-- Master_data


-- Part 2: Grouping, Summarizing data, analytics functions
--Q1: Sales Trend & Operation
/*
1. (Contribution) Sales contribution by category >> category effectiveness
2. (Trend Over Time) Mon over month growth rate by category >> change over time of each category performance
>> Could break down to even more detail level with subcategory
3. Channel effectiveness
-- Overview the ads (media) channel investment vs promotion channel
4. Top 10 Sub category (by orders sold)
5. How many prodcut have we launch so far
*/

SELECT 
	log_date
	,asin
	,sku
	,country
	,channel
	,orders
	,ordered_gmv
	,promotion_spent
	,ad_spent
	,spend

FROM master_data
WHERe label_currency = 'USD';

-- Query1: Sales contribution by category (in terms of orer and revenue)
-- by revenue, spend by categotry >> seeing how effective our investment is
SELECT category
	, TO_CHAR(SUM(spend:: NUMERIC),'FM999,999,999,999') AS SPEND
	, TO_CHAR(ROUND(SUM(spend:: NUMERIC)/SUM(SUM(spend:: NUMERIC)) OVER() *100,2),'FM999,999,990.00') as spend_allocation
	, TO_CHAR(SUM(ordered_gmv:: NUMERIC),'FM999,999,999,999') AS GMV
	, TO_CHAR(ROUND(SUM(ordered_gmv:: NUMERIC)/SUM(SUM(ordered_gmv:: NUMERIC)) OVER() *100,2),'FM999,999,990.00') as gmv_contribution
	, ROUND(SUM(ordered_gmv::NUMERIC) / NULLIF(SUM(spend::NUMERIC), 0), 2) AS ROI
FROM master_data
GROUP BY category
HAVING SUM(ordered_gmv :: NUMERIC) > 0
ORDER BY gmv_contribution DESC;
	
/*
Analyze Month-over-Month (MoM) changes in sales contribution by category across multiple years, we need to:

- Extract the year and month from the date column.
- Calculate GMV and GMV contribution by month.
- Use LAG() to compute MoM percentage change
*/
-- First, Convert transactions_data column from VARCHAR TO DATE in order to perform charting/viz later on

-- ALTER TABLE master_data ALTER COLUMN log_date TYPE DATE USING log_date::DATE;
-- MoM change
-- Step 1 GMV rolling by month
WITH monthly_gmv AS (
    SELECT 
        category,
        EXTRACT(YEAR FROM transactions_date) AS year,  
        EXTRACT(MONTH FROM transactions_date) AS month,  
        SUM(ordered_gmv::NUMERIC) AS GMV,  -- ✅ Aggregated GMV per category-year-month
        ROUND(
            SUM(ordered_gmv::NUMERIC) / 
            NULLIF(SUM(SUM(ordered_gmv::NUMERIC)) OVER (PARTITION BY EXTRACT(YEAR FROM transactions_date), EXTRACT(MONTH FROM transactions_date)), 0) * 100, 
            2
        ) AS gmv_contribution  -- ✅ GMV contribution (%) per category per month
    FROM master_data
    GROUP BY category, EXTRACT(YEAR FROM transactions_date), EXTRACT(MONTH FROM transactions_date)
)
SELECT 
    category, 
    year, 
    month, 
    TO_CHAR(GMV, 'FM999,999,999,999') AS GMV,  -- ✅ Format with thousand separators
    COALESCE(TO_CHAR(gmv_contribution, 'FM990.00') || '%', '0.00%') AS gmv_contribution  -- ✅ Handle NULL values for contribution
FROM monthly_gmv
ORDER BY year, month, category;

-- 2. Adding Month over Month (MoM) Change for the GMV Contribution
WITH monthly_gmv AS (
    SELECT 
        category,
        EXTRACT(YEAR FROM transactions_date) AS year,  
        EXTRACT(MONTH FROM transactions_date) AS month,  
        SUM(ordered_gmv::NUMERIC) AS GMV,  
        ROUND(
            SUM(ordered_gmv::NUMERIC) / 
            NULLIF(SUM(SUM(ordered_gmv::NUMERIC)) OVER (PARTITION BY EXTRACT(YEAR FROM transactions_date), EXTRACT(MONTH FROM transactions_date)), 0) * 100, 
            2
        ) AS gmv_contribution  
    FROM master_data
    GROUP BY category, EXTRACT(YEAR FROM transactions_date), EXTRACT(MONTH FROM transactions_date)
),
mom_change AS (
    SELECT *,
           LAG(gmv_contribution) OVER (PARTITION BY category ORDER BY year, month) AS prev_month_contribution, 
		    -- to get the previous month's GMV contribution.
			-- The LAG() function in SQL is a window function that allows you to access data from a previous row in relation to the current row within a result set. It's very useful for tasks like calculating differences between consecutive values, finding running totals, or comparing current values to previous ones.
           ROUND(
               (gmv_contribution - LAG(gmv_contribution) OVER (PARTITION BY category ORDER BY year, month)) 
               / NULLIF(LAG(gmv_contribution) OVER (PARTITION BY category ORDER BY year, month), 0) * 100, 
               2
           ) AS mom_change_percent
    FROM monthly_gmv
)
SELECT 
    category, 
    year, 
    month, 
    TO_CHAR(GMV, 'FM999,999,999,999') AS GMV,  
    COALESCE(TO_CHAR(gmv_contribution, 'FM990.00') || '%', '0.00%') AS gmv_contribution,  
    COALESCE(TO_CHAR(mom_change_percent, 'FM990.00') || '%', '0.00%') AS mom_change  
FROM mom_change
ORDER BY year, month, category;

-- 3. Channel (ads & promotions) effectiveness
-- to see what treatment work best with what category
WITH channel_performance AS (
    SELECT 
        category,
        'Ad Spend' AS channel_type,
        SUM(ad_spent::NUMERIC) AS spend,
        SUM(ordered_gmv::NUMERIC) AS GMV
    FROM master_data
    GROUP BY category
    
    UNION ALL
    
    SELECT 
        category,
        'Promotion Spend' AS channel_type,
        SUM(promotion_spent::NUMERIC) AS spend,
        SUM(ordered_gmv::NUMERIC) AS GMV
    FROM master_data
    GROUP BY category
)
SELECT 
    category, 
    channel_type,  
    TO_CHAR(spend, 'FM999,999,999,999') AS spend,  
    TO_CHAR(GMV, 'FM999,999,999,999') AS GMV,  
    COALESCE(TO_CHAR(ROUND(GMV / NULLIF(spend, 0), 2), 'FM990.00'), 'N/A') AS ROI  
FROM channel_performance
ORDER BY category, channel_type;

--4. Top 10 Sub category (by orders sold)


-- bottom 10
SELECT 
    subcategory, 
    SUM(orders::NUMERIC) AS total_orders
FROM master_data
GROUP BY subcategory
ORDER BY total_orders ASC  -- Orders in ascending order (least sold first)
LIMIT 10;

-- 5. How many prodcut have we launch so far
--overall
SELECT 
    COUNT(DISTINCT sku) AS total_launched_products
FROM product_list
WHERE launching_date IS NOT NULL;

-- by year
SELECT 
    EXTRACT(YEAR FROM launching_date::DATE) AS launch_year,
    COUNT(DISTINCT sku) AS total_launched_products
FROM product_list
WHERE launching_date IS NOT NULL
GROUP BY launch_year
ORDER BY launch_year DESC;

-- the end --






