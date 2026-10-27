-- ESS_SQL_F1
--
Inspecting the ESS 2016 dataset.
-- The results are sorted first by country and then by region in descending order.

select * from ess16
order by cntry desc, region desc;


-- Inspecting respondents from ESS 2018 whose regional classification unit equals 3.
-- The remaining observations are ordered by country and region.

select * from ess18
where regunit=(3)
order by cntry ASC, region asc;


-- Inspecting the ESS 2016 dataset again, this time ordering countries and regions
-- in ascending order.

select * from ess16
order by cntry ASC, region asc;


-- Checking whether all rows were successfully loaded into each ESS wave.
-- COUNT(*) returns the total number of observations in each table.

SELECT
COUNT(*) AS number_of_rows
FROM ess23;

SELECT
COUNT(*) AS number_of_rows
FROM ess20;

SELECT
COUNT(*) AS number_of_rows
FROM ess18;

SELECT
COUNT(*) AS number_of_rows
FROM ess16;


-- Checking for duplicate respondents within each ESS wave.
-- Respondents are identified by the combination of ESS round, country and respondent ID.
-- HAVING keeps only combinations that occur more than once.

select essround, cntry, COUNT(*) as number_of_rows, idno
from ess16
group by essround, cntry,idno
having COUNT(*) >1;

select essround, cntry, COUNT(*) as number_of_rows, idno
from ess18
group by essround, cntry,idno
having COUNT(*) >1;

select essround, cntry, COUNT(*) as number_of_rows, idno
from ess20
group by essround, cntry,idno
having COUNT(*) >1;

select essround, cntry, COUNT(*) as number_of_rows, idno
from ess23
group by essround, cntry,idno
having COUNT(*) >1;


-- Combining the four ESS waves into one table.
-- UNION ALL preserves every observation instead of removing duplicate rows.
-- SELECT INTO creates a new table called ess_all_waves.

select * INTO ess_all_waves from ess16  
UNION ALL
select * from ess18  
UNION ALL
select * from ess20  
UNION ALL
select * from ess23 
order by essround asc, idno asc;


-- Inspect the newly created table containing all ESS waves.

select * from ess_all_waves;


-- Creating separate tables based on substantive variable categories.
-- The respondent identifiers essround, cntry and idno are retained in the tables
-- so that information can later be joined back together at the respondent level.


-- Creating a geography table containing geographical and settlement information.

SELECT essround, cntry, idno, name, edition, proddate, region, regunit, domicil 
into ess_geography FROM  ess_all_waves;


-- Creating a demographic table containing age, gender, household,
-- marital-status and education variables.

SELECT essround, cntry, idno, agea, gndr, hhmmb, maritalb, eduyrs, eiscedp
 into ess_demographics FROM  ess_all_waves;


-- Creating an employment table containing employment status,
-- contractual conditions, working hours and unemployment variables.

SELECT essround, cntry, idno, mainact, emplrel, wrkctra, wkhtot, uemp3m, uemp12m, uemp5yr
 into ess_employment FROM  ess_all_waves;


-- Creating an income table containing the main household income variables.

SELECT essround, cntry, idno, hincsrca, hinctnta, hincfel
 into ess_income FROM  ess_all_waves;


-- Creating a wellbeing table containing happiness, life satisfaction,
-- health and social-connectedness variables.

SELECT essround, cntry, idno, happy, stflife, health, hlthhmp, sclmeet, inprdsc, sclact
 into ess_wellbeing FROM  ess_all_waves;


-- Creating a public-assessments table containing respondents' evaluations
-- of the economy, government, democracy, education and healthcare.

SELECT essround, cntry, idno, stfeco, stfgov, stfdem, stfedu, stfhlth
 into ess_public_assessments FROM  ess_all_waves;


-- Checking the geography table for duplicate Lithuanian respondents.
-- The grouping again uses ESS round, country and respondent ID.

select cntry, idno, COUNT(*) as number_of_rows
from ess_geography
where cntry =('lt')
GROUP BY essround, cntry, idno
having COUNT(*) >1;


-- Creating cleaned views while keeping the original tables unchanged.
-- CASE statements convert ESS missing-value, refusal and "don't know" codes
-- into SQL NULL values according to the survey codebook.


-- Creating a cleaned version of the geography data.
-- Invalid region codes are converted to NULL.
-- Non-substantive domicile responses are also converted to NULL.

CREATE VIEW ess_geography_rec AS
SELECT
    name,
    essround,
    edition,
    proddate,
    idno,
    cntry,
    regunit,
    CASE
        WHEN region = '99999' THEN NULL
        ELSE region
    END AS region,
    CASE
        WHEN domicil BETWEEN 7 AND 9 THEN NULL
        ELSE domicil
    END AS domicil
FROM ess_geography;


-- Creating a cleaned demographic view.
-- Each CASE statement handles the special missing-value codes
-- used for the corresponding demographic variable.

CREATE VIEW ess_demographics_rec AS
SELECT
    essround,
    cntry,
    idno,
    CASE
        WHEN agea = 999 THEN NULL
        ELSE agea
    END AS agea,
    CASE
        WHEN gndr = 9 THEN NULL
        ELSE gndr
    END AS gndr,
    CASE
        WHEN hhmmb IN (77, 88, 99) THEN NULL
        ELSE hhmmb
    END AS hhmmb,
    CASE
        WHEN maritalb IN (77, 88, 99) THEN NULL
        ELSE maritalb
    END AS maritalb,
    CASE
        WHEN eduyrs IN (77, 88, 99) THEN NULL
        ELSE eduyrs
    END AS eduyrs,
    CASE
        WHEN eiscedp IN (66, 77, 88, 99) THEN NULL
        ELSE eiscedp
    END AS eiscedp
FROM ess_demographics;


-- Inspecting the raw unemployment variable before recoding.
-- This makes it possible to verify the values that will be treated as missing.

select * from ess_employment
where uemp3m in (7, 8, 9);


-- Creating a cleaned employment view.
-- Special ESS codes representing missing or non-substantive responses
-- are replaced with SQL NULL values.

create view ess_employment_rec AS
SELECT
    essround,
    cntry,
    idno,
    CASE
        WHEN mainact IN (66, 77, 88, 99) THEN NULL
        ELSE mainact
    END AS mainact,
     CASE
        WHEN emplrel IN (6, 7, 8, 9) THEN NULL
        ELSE emplrel
    END AS emplrel,
    CASE
        WHEN wrkctra IN (6, 7, 8, 9) THEN NULL
        ELSE wrkctra
    END AS wrkctra,
    CASE
        WHEN wkhtot IN (66, 77, 88, 99) THEN NULL
        ELSE wkhtot
    END AS wkhtot,
    CASE
        WHEN uemp3m IN ( 7, 8, 9) THEN NULL
        ELSE uemp3m
    END AS uemp3m,
    CASE
        WHEN uemp12m IN (66, 77, 88, 99) THEN NULL
        ELSE uemp12m
    END AS uemp12m,
    CASE
        WHEN uemp5yr IN (66, 77, 88, 99) THEN NULL
        ELSE uemp5yr
    END AS uemp5yr
from ess_employment;


-- Inspecting the raw household-income-source variable
-- for the special ESS missing-response codes.

select * from ess_income
where hincsrca IN (77, 88, 99);


-- Creating a cleaned income view.
-- Invalid and non-substantive responses are converted to NULL
-- while valid income information is retained.

CREATE VIEW ess_income_rec AS
SELECT
    essround,
    cntry,
    idno,
    CASE
        WHEN hincsrca IN (77, 88, 99) THEN NULL
        ELSE hincsrca
    END AS hincsrca,
    CASE
        WHEN hinctnta IN (77, 88, 99) THEN NULL
        ELSE hinctnta
    END AS hinctnta,
    CASE
        WHEN hincfel IN (7, 8, 9) THEN NULL
        ELSE hincfel
    END AS hincfel
FROM ess_income;


-- Creating a cleaned wellbeing view.
-- Missing, refusal and "don't know" codes are replaced with NULL
-- separately for each wellbeing and social-connectedness variable.

CREATE VIEW ess_wellbeing_rec AS
SELECT
    essround,
    cntry,
    idno,
    CASE
        WHEN happy IN (77, 88, 99) THEN NULL
        ELSE happy
    END AS happy,
    CASE
        WHEN stflife IN (77, 88, 99) THEN NULL
        ELSE stflife
    END AS stflife,
    CASE
        WHEN health IN (7, 8, 9) THEN NULL
        ELSE health
    END AS health,
    CASE
        WHEN hlthhmp IN (7, 8, 9) THEN NULL
        ELSE hlthhmp
    END AS hlthhmp,
    CASE
        WHEN sclmeet IN (77, 88, 99) THEN NULL
        ELSE sclmeet
    END AS sclmeet,
    CASE
        WHEN inprdsc IN (77, 88, 99) THEN NULL
        ELSE inprdsc
    END AS inprdsc,
    CASE
        WHEN sclact IN (7, 8, 9) THEN NULL
        ELSE sclact
    END AS sclact
FROM ess_wellbeing;


-- Creating a cleaned public-assessments view.
-- Invalid responses are converted to NULL before later analysis.

CREATE VIEW ess_public_assessments_rec AS
SELECT
    essround,
    cntry,
    idno,
    CASE
        WHEN stfeco IN (77, 88, 99) THEN NULL
        ELSE stfeco
    END AS stfeco,
    CASE
        WHEN stfgov IN (77, 88, 99) THEN NULL
        ELSE stfgov
    END AS stfgov,
    CASE
        WHEN stfdem IN (77, 88, 99) THEN NULL
        ELSE stfdem
    END AS stfdem,
    CASE
        WHEN stfedu IN (77, 88, 99) THEN NULL
        ELSE stfedu
    END AS stfedu,
    CASE
        WHEN stfhlth IN (77, 88, 99) THEN NULL
        ELSE stfhlth
    END AS stfhlth
FROM ess_public_assessments;


-- Inspecting cleaned public-assessment observations for Hungary
-- in ESS rounds 9, 10 and 11.
-- Results are ordered by satisfaction with the economy.

select * from  ess_public_assessments_rec
where cntry ='HU' and essround in (9,10,11)
order by stfeco desc;


-- Inspecting missing values in the cleaned household-income-decile variable.

select count(distinct hinctnta where is null) as total_hinctnta
 from ess_income_rec
order by essround asc, cntry asc, hinctnta desc;


-- Creating an analytical view combining cleaned wellbeing and income data.
-- Respondents are matched across the two views using ESS round,
-- country and respondent ID.
-- The resulting data are aggregated by round, country and subjective income category.

CREATE VIEW ess_wellbeing_by_inc_cntry AS
select w.essround, w.cntry, i.hincfel,
count(DISTINCT w.idno) as RespondentCount,
avg(w.happy) as AverageHappiness,
avg(w.stflife) as AverageLifeSatisfaction
from ess_wellbeing_rec as w    
join ess_income_rec as i 
on w.essround=i.essround
and w.cntry=i.cntry  
and w.idno=i.idno 
where i.hincfel is NOT NULL
 or w.happy is NOT NULL
  or w.stflife is NOT NULL
group by w.essround, w.cntry, i.hincfel;


-- Inspecting the newly created wellbeing-by-income view.

select * from ess_wellbeing_by_inc_cntry;


-- Modifying the wellbeing-by-income view.
-- The WHERE condition now requires all three variables
-- to contain valid information rather than accepting cases
-- where only one of them is available.

alter VIEW ess_wellbeing_by_inc_cntry AS
select w.essround, w.cntry, i.hincfel,
count(DISTINCT w.idno) as RespondentCount,
avg(w.happy) as AverageHappiness,
avg(w.stflife) as AverageLifeSatisfaction
from ess_wellbeing_rec as w    
join ess_income_rec as i 
on w.essround=i.essround
and w.cntry=i.cntry  
and w.idno=i.idno 
where i.hincfel is NOT NULL
 and w.happy is NOT NULL
 and w.stflife is NOT NULL
group by w.essround, w.cntry, i.hincfel;


-- Inspecting the altered analytical view.
-- Results are ordered by subjective income category and ESS round.

select * from ess_wellbeing_by_inc_cntry
order by hincfel desc, essround desc;


-- Inspecting the cleaned demographic data before creating
-- the next analytical view.

select *f from ess_demographics_rec;


-- Createing an analytical view combining education
-- with satisfaction with the economy, government and democracy.
-- Respondents are matched using round, country and respondent ID.
-- The result contains one row per round, country and education category.

create view ess_public_assessment_by_education AS
select d.essround, d.cntry, d.eiscedp,
count(distinct d.idno) as RespondentCount,
avg(p.stfeco) as AverageEconomicSatisfaction, 
avg(p.stfgov) as AverageGovernmentSatisfaction,
avg(p.stfdem) as AverageDemocracySatisfaction
from ess_demographics_rec as d  
join ess_public_assessments_rec as p 
on d.essround=p.essround
and d.cntry=p.cntry  
and d.idno=p.idno 
where d.eiscedp is NOT NULL
 and p.stfeco is NOT NULL
 and p.stfgov is NOT NULL
 and p.stfdem is NOT NULL
group by d.essround, d.cntry, d.eiscedp;


-- Inspecting the public-assessment-by-education view.
-- Results are ordered by ESS round and education category.

select * from ess_public_assessment_by_education
order by essround desc, eiscedp desc;


-- Modifying the education/public-assessment view.
-- Education categories 55 and 0 are additionally excluded
-- while retaining the previous missing-value restrictions.

alter view ess_public_assessment_by_education AS
select d.essround, d.cntry, d.eiscedp,
count(distinct d.idno) as RespondentCount,
avg(p.stfeco) as AverageEconomicSatisfaction, 
avg(p.stfgov) as AverageGovernmentSatisfaction,
avg(p.stfdem) as AverageDemocracySatisfaction
from ess_demographics_rec as d  
join ess_public_assessments_rec as p 
on d.essround=p.essround
and d.cntry=p.cntry  
and d.idno=p.idno 
where d.eiscedp is NOT NULL 
AND d.eiscedp <> 55
  AND d.eiscedp <> 0
 and p.stfeco is NOT NULL
 and p.stfgov is NOT NULL
 and p.stfdem is NOT NULL
group by d.essround, d.cntry, d.eiscedp;


-- Inspecting the altered education/public-assessment view.

select * from ess_public_assessment_by_education
order by essround desc, eiscedp desc;


-- Createing a respondent-level view combining income
-- with regional information.
-- Unlike the previous analytical views, this view does not aggregate respondents.
-- The same respondent is matched across the income and geography views.

create view ess_income_with_region AS
select i.essround, i.cntry, i.idno, i.hincfel, i.hinctnta,
g.region, g.regunit
from ess_income_rec as i 
join ess_geography_rec as g   
on i.essround=g.essround
and i.cntry=g.cntry
and i.idno=g.idno
where g.region is not null 
and (i.hincfel is NOT NULL
or i.hinctnta is NOT NULL);


-- Creating a more complex respondent-level analytical view.
-- Three cleaned views are joined together:
-- demographics, employment and wellbeing.
-- Respondents are matched using ESS round, country and respondent ID.
-- The sample is restricted to respondents aged 25–65 with valid gender information.
-- Employment information is retained when either main activity or unemployment data are available.
-- Wellbeing information is retained when either happiness or life satisfaction is available,
-- while health must always contain a valid value.

create view ess_employment_wellbeing_demographics AS 
select d.essround, d.cntry, d.idno, d.agea, d.gndr, d.eiscedp,
 e.mainact, e.emplrel, e.uemp12m,
 w.happy, w.stflife, w.health
from ess_demographics_rec as d  
join ess_employment_rec as e 
on d.essround=e.essround
and d.cntry=e.cntry
and d.idno=e.idno 
join ess_wellbeing_rec as w 
on w.essround=e.essround
and w.cntry=e.cntry
and w.idno=e.idno
where d.agea between 25 and 65
and d.gndr is not null -- Get a list of tables and views in the current database
and (e.mainact is NOT NULL or e.uemp12m is NOT NULL)
and (w.happy is not null or w.stflife is not null)
and w.health is not null;