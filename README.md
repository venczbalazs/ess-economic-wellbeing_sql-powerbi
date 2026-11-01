# Economic wellbeing in Europe | Survey data with SQL Server and Power BI

I used SQL Server and Power BI to study financial difficulty and wellbeing across Europe. I built a ten-page report from the European Social Survey (ESS) to compare countries, follow changes across survey rounds, and explore how respondents rated their economy and education system.

I included the imported data in the `.pbix` so the report opens in Power BI Desktop after download from GitHub (**Download raw file**). [Power BI report](report/ess_powerbi.pbix)

## Data I used

I imported the same set of fields from four ESS rounds into separate SQL Server tables. Together they contained **181,633 survey responses from 34 countries**. I used the years below as wave labels because fieldwork dates varied by country.

| ESS round | Report year | Input table | Rows loaded | Countries |
| ---: | ---: | --- | ---: | ---: |
| 8 | 2016 | `ess16` | 44,387 | 23 |
| 9 | 2018 | `ess18` | 49,519 | 29 |
| 10 | 2020 | `ess20` | 37,611 | 22 |
| 11 | 2023 | `ess23` | 50,116 | 30 |

## Variables I used

| ESS fields | How I used them |
| --- | --- |
| `essround`, `cntry`, `idno` | I used survey round, country and respondent ID together to match a person’s answers across tables. |
| `hincfel` | I measured how respondents felt about living on their current household income, from *living comfortably* to *very difficult*. |
| `happy`, `stflife`, `health` | I used the 0–10 happiness and life satisfaction scores and labelled self-rated health from *very good* to *very bad*. |
| `stfeco`, `stfedu`, `stfhlth` | I compared satisfaction with the economy and ratings of the education system on 0–10 scales. For the public-assessment charts, I kept respondents who also rated health services. |
| `agea`, `gndr`, `eiscedp` | I used age and gender for demographic breakdowns. In a separate SQL analysis, I used `eiscedp` for the **partner’s** highest completed education. |

<details>
<summary>Input fields in their import order</summary>

```text
name, essround, edition, proddate, idno, cntry, region, regunit, domicil,
agea, gndr, hhmmb, maritalb, eduyrs, eiscedp, mainact, emplrel, wrkctra,
wkhtot, uemp3m, uemp12m, uemp5yr, hincsrca, hinctnta, hincfel, happy,
health, hlthhmp, sclmeet, inprdsc, sclact, stflife, stfeco, stfgov,
stfdem, stfedu, stfhlth
```

</details>

## How I prepared the data in SQL Server

1. **Checked the imports.** I counted rows in each wave and grouped by `essround, cntry, idno` to check for duplicates. I found **zero duplicate combinations**. I used all three fields because an ID can recur in another country or round.
2. **Appended the four waves.** I used `UNION ALL` to stack the rows in `ess_all_waves`. This preserved every record I had counted and let me compare waves with a single query.
3. **Separated the survey topics.** I created tables for geography, demographics, employment, income, wellbeing and public assessments. I retained the respondent key in each so I could join topics for a specific question.
4. **Created reusable cleaning views.** I wrote six `_rec` views to share the same cleaning rules across SQL queries and Power BI. In each view, I used `CASE` to turn question-specific nonresponse codes into `NULL`. I excluded 7, 8 and 9 for income difficulty. For satisfaction scores, I kept the full 0–10 scale and excluded 77, 88 and 99.
5. **Joined answers before summarising them.** I joined income and wellbeing on the respondent key to calculate average happiness and life satisfaction by country, round and income-difficulty category. I also linked income to region and public assessments to partner’s education. For the wellbeing trend and its coverage counts, I used a narrower view of respondents aged **25–65** with recorded gender and health, at least one of the two selected employment fields, and a happiness or life satisfaction answer. [SQL workflow](./--%20ESS_SQL_v1.sql)

## How I built the Power BI report

1. **Prepared readable categories in Power Query.** I connected to the cleaned SQL views and renamed fields such as `stfeco` (*Economy satisfaction*). I grouped ages into 15–24, 25–34, 35–44, 45–54, 55–64 and 65+. For the economy and education charts, I defined low (0–3), moderate (4–6) and high (7–10) ratings. I added numeric sort columns to display the groups in order.
2. **Connected tables at the right level.** I created country and round lookup tables with one row per value so the same slicers could filter multiple visuals. To show education ratings by age, I connected demographics and public assessments one-to-one using a `round|country|id` key. For the map, I used *Slovakia* as the display label and kept `SK` as the relationship key.
3. **Defined measures that respond to filters.** I used DAX to count responses and calculate mean and median wellbeing scores. For income difficulty, I coded *difficult* and *very difficult* as 1, *living comfortably* and *coping* as 0, and other answers as blank. I averaged these values to get the share reporting difficulty in each selection.

   ```dax
   Income difficulty % =
   AVERAGEX(
       'ess_inc_rec',
       SWITCH(
           'ess_inc_rec'[Perceived household financial situation],
           1, 0,
           2, 0,
           3, 1,
           4, 1,
           BLANK()
       )
   )
   ```

4. **Chose visuals for different comparisons.** I used coverage matrices to check response counts, stacked charts to compare rating distributions across age groups, and a demographic chart to show age composition by gender. I used a pie chart for the economy rating bands, a line chart for average happiness, and a map for life satisfaction. I built separate ranking and trend pages for income difficulty so I could compare countries within a wave or follow one country over time.

## What I found in round 11 (2023)

**Household income.** I found that **68.2%** of respondents in Ukraine who answered the income question chose *difficult* or *very difficult*, compared with **5.0%** in Sweden. I included the counts behind each percentage.

| Country | Difficult or very difficult | Valid answers | Share |
| --- | ---: | ---: | ---: |
| Ukraine | 1,772 | 2,598 | 68.2% |
| Bulgaria | 1,067 | 2,229 | 47.9% |
| Hungary | 577 | 2,096 | 27.5% |
| Sweden | 61 | 1,222 | 5.0% |

**Economy and education.** I plotted economy satisfaction horizontally and education ratings vertically, using one bubble per country and sizing it by response count. In Norway, I found a higher average for education (**7.35/10**) than for the economy (**5.66/10**) among 1,312 respondents. In Switzerland, I found similar averages for education (**6.74**) and the economy (**6.88**) among 1,264 respondents.

![Round 11 bubble chart of average economy satisfaction and education system ratings by country](images/economy-and-education-2023.png)

I reported **unweighted sample results**, giving each valid response equal weight. I compared countries within the same round because participation changed across waves, and I checked which respondents each view included.

## How I verified the results

I recalculated the round 11 income percentages in SQL using the same valid-answer rule as the DAX measure. For Hungary, I counted **577 out of 2,096** valid responses, which reproduced the **27.5%** displayed in Power BI.

```sql
SELECT
    cntry,
    COUNT(*) AS valid_answers,
    SUM(CASE WHEN hincfel IN (3, 4) THEN 1 ELSE 0 END) AS difficulty_answers,
    CAST(100.0 * SUM(CASE WHEN hincfel IN (3, 4) THEN 1 ELSE 0 END)
         / COUNT(*) AS decimal(5, 1)) AS difficulty_pct
FROM dbo.ess_income_rec
WHERE essround = 11 AND hincfel IN (1, 2, 3, 4)
GROUP BY cntry
ORDER BY difficulty_pct DESC;
```

## Rebuild details and field notes

I loaded the four input tables into `ESS_EconomicWellbeing` using compatible types and the field order listed above, then ran the SQL script in SSMS. To repeat the build on another server, I would use a fresh database and reconnect Power BI through **Transform data → Data source settings → Change Source** before refreshing.

**Field checks.** I found contract type (`wrkctra`) in the round 10 working-hours position (`wkhtot`). On a rebuild, I would take `wkhtot` from the original ESS file. I also found that *Household size* in `ess_wb_rec` refers to activity limitations (`hlthhmp`). For household size, I would use `hhmmb` in demographics. I calculated the results above from the income and public-assessment fields.

## Data attribution

I used integrated files from the European Social Survey European Research Infrastructure (ESS ERIC), distributed by Sikt, the Norwegian Agency for Shared Services in Education and Research. I selected survey fields, recoded responses and calculated the summaries from the following editions. [Data licence (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)

- ESS round 8, edition 2.3 (2023). [Dataset and citation](https://doi.org/10.21338/ess8e02_3)
- ESS round 9, edition 3.3 (2026). [Dataset and citation](https://doi.org/10.21338/ess9e03_3)
- ESS round 10, edition 3.3 (2025). [Dataset and citation](https://doi.org/10.21338/ess10e03_3)
- ESS round 11, edition 4.2 (2026). [Dataset and citation](https://doi.org/10.21338/ess11e04_2)
