/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

call silver.load_silver()
delimiter $$
create  procedure silver.load_silver()
begin

truncate table silver.crm_cust_info;
insert into silver.crm_cust_info (
	cst_id,
	cst_key,
    cst_firstname,
	cst_lastname,
    cst_marital_status,
    cst_gndr, 
	cst_create_date)
select 
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case when upper(cst_marital_status) = 'S' then "Single"
	 when upper(cst_marital_status) = 'M' then "Married"
	 else  "N/A"
end cst_marital_status, 
case when upper(cst_gndr) = 'M' then "Male"
	 when upper(cst_gndr) = 'F' then "Female"
	 else  "N/A"
end cst_gndr, 
cst_create_date
from
(select*,
row_number() over (partition by cst_id order by cst_create_date desc) as flag_last 
from bronze.crm_cust_info
where cst_id is not null
)t where flag_last = 1;

truncate table silver.crm_prd_info;
insert into silver.crm_prd_info(
prd_id,
cat_id, 
prd_key, 
prd_nm, 
prd_cost, 
prd_line, 
prd_start_dt,
prd_end_dt)
select 
prd_id,
replace(substring(prd_key, 1, 5), '-','_') as cat_id,  
substring(prd_key, 7, length(prd_key) ) as prd_key,
prd_nm,
ifnull(prd_cost, 0) as prd_cost,  
case upper(trim(prd_line))
	 when 'S' then "Other Sales"
	 when 'M' then "Mountain"
     when 'R' then "Road"
	 when 'T' then "Touring"
	 else  "N/A"
end as prd_line,
date(prd_start_dt) as prd_start_dt,
date_sub(
	lead(prd_start_dt) over(partition by prd_key order by prd_start_dt), interval 1 day ) as prd_end_dt 
from bronze.crm_prd_info;

truncate table silver.crm_sales_details;
insert into silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price  
)select
sls_ord_num,
sls_prd_key,
sls_cust_id,
case when sls_order_dt <= 0 or length(sls_order_dt)!=8 then null
	 else cast(cast(sls_order_dt as char)as date)
end as sls_order_dt,
case when sls_ship_dt <= 0 or length(sls_ship_dt)!=8 then null
	 else cast(cast(sls_ship_dt as char)as date)
end as sls_ship_dt,
case when sls_due_dt <= 0 or length(sls_due_dt)!=8 then null
	 else cast(cast(sls_due_dt as char)as date)
end as sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0 
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price 
END AS sls_price
from bronze.crm_sales_details;

truncate table silver.erp_cust_az12;
insert into silver.erp_cust_az12 (cid,bdate,gen)
select 
case when cid like 'NAS%' then substring(cid,4,length(cid))
	else cid
end as cid,
case when bdate > current_timestamp() then null
	else bdate
end as bdate,
case when upper(trim(gen)) in ('Male','M') then 'Male'
	 when upper(trim(gen)) in ('F','Female') then 'Female'
	else 'N/A'
end as gen
from bronze.erp_cust_az12;

truncate table silver.erp_loc_a101;
insert into silver.erp_loc_a101(cid,cntry)
select 
replace(cid,'-','') cid,
case when trim(cntry) = 'DE' then "Germany"
	 when trim(cntry) IN ('US','USA') then "United States"
     when trim(cntry) = ' 'or cntry is null then "N/A"
     else trim(cntry)
end as cntry
from bronze.erp_loc_a101;

truncate table silver.erp_px_cat_g1v2;
insert into silver.erp_px_cat_g1v2( id,
cat,
subcat,
maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2;

end $$
delimiter ;
