/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================



drop view if exists gold.dim_customers;
create view gold.dim_customers as
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, 
    ci.cst_id  AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname  AS first_name,
    ci.cst_lastname  AS last_name,
    la.cntry  AS country,
    ci.cst_marital_status  AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')  			   
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
    
drop view if exists gold.dim_products; 

create view gold.dim_products as
select
row_number() over(order by pn.prd_start_dt, pn.prd_key) as product_key, 
pn.prd_id as product_id,
pn.prd_key as product_number,
pn.prd_nm as product_name,
pn.cat_id as category_id,
pc.cat as category,
pc.subcat as sub_category,
pc.maintenance as maintenance,
pn.prd_cost as product_cost,
pn.prd_line as product_line,
pn.prd_start_dt as start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on 				pn.cat_id=pc.id
where prd_end_dt is null;

drop view if exists gold.fact_sales;

create view gold.fact_sales as
select
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as ship_date, 
sd.sls_due_dt as due_date,
sd.sls_sales as sales_amount, 
sd.sls_quantity as sales_quantity,
sd.sls_price as price
from silver.crm_sales_details sd
left join gold.dim_products as pr
on 	sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu
on 	sd.sls_cust_id = cu.customer_id



