Bronze Layer Data Loading

OVERVIEW :

The Bronze layer stores raw source data imported from CRM and ERP systems.

Data Sources

- CRM source files (CSV)
- ERP source files (CSV)

Table Creation :

Bronze tables were created using MySQL DDL scripts.

Data Loading Method :

Due to MySQL "secure_file_priv" restrictions, data was loaded using the MySQL Workbench Table "Data Import Wizard."

Steps :

1. Create Bronze tables in MySQL.
2. Right-click the target table in MySQL Workbench.
3. Select Table Data Import Wizard.
4. Browse to the CSV file.
5. Map columns to the target table.
6. Complete the import process.
7. Validate row counts using:

SELECT COUNT(*) FROM bronze.crm_cust_info;

VALIDATION :

After import, row counts were verified for all Bronze tables to ensure successful data loading.

Technologies Used :

- MySQL 8.x
- MySQL Workbench
- CSV Source Files
- GitHub
