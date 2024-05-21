CREATE TABLE public.country_vaccination_stats (
    country VARCHAR(255),
    date DATE,
    daily_vaccinations INT,
    vaccines VARCHAR(255)
);

SELECT * FROM Public.country_vaccination_stats
-- The data was copied to the table via the terminal

-- Fill in missing daily vaccination numbers with median for each country
WITH medians AS (
    SELECT country, 
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY daily_vaccinations) AS median_vaccinations
    FROM country_vaccination_stats
    WHERE daily_vaccinations IS NOT NULL
    GROUP BY country
),
to_update AS (
    SELECT cvs.country, cvs.date, m.median_vaccinations
    FROM country_vaccination_stats cvs
    LEFT JOIN medians m ON cvs.country = m.country
    WHERE cvs.daily_vaccinations IS NULL
)
UPDATE country_vaccination_stats
SET daily_vaccinations = to_update.median_vaccinations
FROM to_update
WHERE country_vaccination_stats.country = to_update.country
AND country_vaccination_stats.date = to_update.date;

-- Fill values with zero for countries without valid daily vaccination records
WITH missing_countries AS (
    SELECT DISTINCT country
    FROM country_vaccination_stats
    WHERE country NOT IN (SELECT DISTINCT country FROM country_vaccination_stats WHERE daily_vaccinations IS NOT NULL)
),
to_update_zero AS (
    SELECT cvs.country, cvs.date
    FROM country_vaccination_stats cvs
    JOIN missing_countries mc ON cvs.country = mc.country
    WHERE cvs.daily_vaccinations IS NULL
)
UPDATE country_vaccination_stats
SET daily_vaccinations = 0
FROM to_update_zero
WHERE country_vaccination_stats.country = to_update_zero.country
AND country_vaccination_stats.date = to_update_zero.date;

SELECT * FROM Public.country_vaccination_stats