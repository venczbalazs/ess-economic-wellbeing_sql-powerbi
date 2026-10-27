#E conomic Wellbeing in Europe | SQL & Power BI
An exploratory project using European Social Survey (ESS) data to examine income, employment, wellbeing and public satisfaction.

**Project objectives**
•	Explore happiness and life satisfaction across countries and survey rounds.
•	Examine how perceived household income relates to wellbeing.
•	Explore public satisfaction across education categories.
•	Prepare regional income and employment data for visualization in Power BI.
Tools
•	Microsoft SQL Server and SQL Server Management Studio
•	SQL for data preparation and exploratory analysis
•	Power BI for the dashboard

**SQL workflow**
The SQL script includes:
1.	Row-count and duplicate checks across four source tables: ess16, ess18, ess20 and ess23.
2.	Combining survey waves with UNION ALL.
3.	Creating tables for geography, demographics, employment, income, wellbeing and public assessments.
4.	Using CASE expressions and NULL to recode selected survey response values.
5.	Joining records using survey round, country and respondent ID.
6.	Creating analytical views for further exploration and visualization.


