--*************************************************************************************************************************************************************************************************************************
--***************************************************** PROJECT CODE: PRTFL_DALYs_01                                  *****************************************************************************************************
--***************************************************** INPUT TABLE: PortfolioProject..[dalys-rate-from-all-causes]   *****************************************************************************************************
--***************************************************** OUTPUT TABLE: PortfolioProject..dalys_output                  *****************************************************************************************************
--***************************************************** PROJECT SUMMARY: This is a portfolio project to showcase to   *****************************************************************************************************
--***************************************************** my future clients some of the my data cleaning and exploratory ****************************************************************************************************
--***************************************************** analysis skills using SQL                                     *****************************************************************************************************
--***************************************************** SOFTWARE VERSION: Microsoft SQL Server Management Studio 19.1 *****************************************************************************************************
--***************************************************** LAST UPDATE: 05/10/2023                                       *****************************************************************************************************
--*************************************************************************************************************************************************************************************************************************

-- 1. Checking for incoherence problems 
select * from PortfolioProject..[dalys-rate-from-all-causes]
--Reporting information about the database
USE PortfolioProject
GO
EXEC sp_help'[dalys-rate-from-all-causes]'
GO
select max([DALYs (Disability-Adjusted Life Years) - All causes - Sex  Both - Age  Age-standardized (Rate)]) from PortfolioProject..[dalys-rate-from-all-causes] --99957.86
--Creating a new table named 'dalys_rate_all_causes' with adjusted column names and column types from 'dalys-rate-from-all-causes'
create table PortfolioProject..dalys_rate_all_causes (entity varchar(50), code varchar(50), years int,dalys float(8))
insert into PortfolioProject..dalys_rate_all_causes 
	select Entity, Code, Year, [DALYs (Disability-Adjusted Life Years) - All causes - Sex  Both - Age  Age-standardized (Rate)]
	from PortfolioProject..[dalys-rate-from-all-causes] 
--Checking the new table 'dalys_rate_all_causes'
select * from PortfolioProject..dalys_rate_all_causes
USE PortfolioProject
GO
EXEC sp_help'dalys_rate_all_causes'
GO
-- Number of missing entity: 0
select COUNT(entity) from PortfolioProject..dalys_rate_all_causes where Entity=''
-- Number of missing code: 690
select COUNT(code) from PortfolioProject..dalys_rate_all_causes where code=''
-- Number of missing years: 0
select COUNT(years) from PortfolioProject..dalys_rate_all_causes where years is NULL 
-- Number of missing DALYs: 0
select COUNT(dalys) from PortfolioProject..dalys_rate_all_causes where dalys is NULL
-- Min of years:1990 / Max of years:2019
select min(years) as min_years, max(years) as max_years from PortfolioProject..dalys_rate_all_causes 


--2. Data pre-processing: 
--Grouping entities with missing codes 
create table PortfolioProject..entities_no_code (entity varchar(50) , code varchar(50)) 
insert into PortfolioProject..entities_no_code  
	select distinct entity, code
	from PortfolioProject..dalys_rate_all_causes 
	where code =''

--Grouping entities with codes
create table PortfolioProject..entities_with_code (entity varchar(50) , code varchar(50))
insert into PortfolioProject..entities_with_code  
	select distinct entity, code
	from PortfolioProject..dalys_rate_all_causes
	where code !=''

--Checking if there was any entity with an assigned code which appeared in 'entities_no_code'
select a.entity, a.code from PortfolioProject..entities_with_code as a inner join PortfolioProject..entities_no_code as b on a.code=b.code

-- Assigning a unique code to entities with missing codes 
create table PortfolioProject..entities_no_code_updated (entity varchar(50) , code varchar(50))
insert into PortfolioProject..entities_no_code_updated
	select distinct entity,
			case 
				 when entity = 'African Region (WHO)' then 'AFR' 
				 when entity = 'East Asia & Pacific (WB)' then  'EAP'
				 when entity = 'Eastern Mediterranean Region (WHO)' then  'EMR'
				 when entity = 'England' then  'ENG	'
				 when entity = 'Europe & Central Asia (WB)' then  'ECA'
				 when entity = 'European Region (WHO)' then  'EUR'
				 when entity = 'G20' then  'G20'
				 when entity = 'Latin America & Caribbean (WB)' then  'LAC'
 				 when entity = 'Middle East & North Africa (WB)' then  'MENA'
				 when entity = 'North America (WB)' then  'NA'
				 when entity = 'Northern Ireland' then  'NI'
				 when entity = 'OECD Countries' then  'OECD'
				 when entity = 'Region of the Americas (WHO)' then  'AMR'
				 when entity = 'Scotland' then  'SCT'
				 when entity = 'South Asia (WB)' then  'SA'
				 when entity = 'South-East Asia Region (WHO)' then  'SEA'
				 when entity = 'Sub-Saharan Africa (WB)' then  'SSA'
				 when entity = 'Wales' then  'WAL'
				 when entity = 'Western Pacific Region (WHO)' then  'WPA'
				 when entity = 'World Bank High Income' then  'HIGH'
				 when entity = 'World Bank Low Income' then  'LOW'
				 when entity = 'World Bank Lower Middle Income' then  'LMI'
				 when entity = 'World Bank Upper Middle Income' then  'UMI'
			end as code
		from PortfolioProject..entities_no_code

create table PortfolioProject..dalys_rate_all_causes_updated (entity varchar(50), code varchar(50), years int,dalys float(8))
insert into PortfolioProject..dalys_rate_all_causes_updated
	select a.entity, case when a.code='' then b.code else a.code end as code, a.years, a.dalys
	from PortfolioProject..dalys_rate_all_causes a left join PortfolioProject..entities_no_code_updated b on a.entity=b.entity

select * from PortfolioProject..dalys_rate_all_causes_updated

-- 3. Exploratory Analysis:
-- Highest DALYs VS lowest DALYs
select * from PortfolioProject..dalys_rate_all_causes_updated where dalys=(select max(dalys) from PortfolioProject..dalys_rate_all_causes_updated)
union
select * from PortfolioProject..dalys_rate_all_causes_updated where dalys=(select min(dalys) from PortfolioProject..dalys_rate_all_causes_updated)

-- The average of DALYs across all years by country
create table PortfolioProject..avg_dalys_country (code varchar(50), avg_dalys float(8))
insert into PortfolioProject..avg_dalys_country
	select code, AVG(dalys) as avg_dalys --The averaged DALYs across years
	from PortfolioProject..dalys_rate_all_causes_updated
	group by code

create table PortfolioProject..dalys_output (entity varchar(50), code varchar(50), avg_dalys float(8))
insert into PortfolioProject..dalys_output
select distinct a.entity, a.code, b.avg_dalys from PortfolioProject..dalys_rate_all_causes_updated as a inner join PortfolioProject..avg_dalys_country as b on a.code=b.code

select * from PortfolioProject..dalys_output



