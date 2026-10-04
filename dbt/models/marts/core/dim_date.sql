{{ config(
    unique_key='date_id'
) }}

WITH date_spine AS (
    -- Generates a continuous series of dates using dbt_utils
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2018-12-31' as date)"
    ) }}
),

base_dates AS (
    SELECT 
        cast(date_day as date) AS full_date
    FROM date_spine
),

date_calculations AS (
    SELECT
        -- Unique Integer Key (Format: YYYYMMDD, e.g., 20260726)
        cast(to_char(full_date, 'YYYYMMDD') as integer) AS date_id,
        full_date,
        cast(extract(year from full_date) as integer) AS year,
        cast(extract(month from full_date) as integer) AS month,
        cast(extract(day from full_date) as integer) AS day,
        
        -- Day of week (1 = Monday, 7 = Sunday)
        cast(extract(isodow from full_date) as integer) AS weekday,
        
        -- Identify Saturday (6) and Sunday (7)
        CASE 
            WHEN extract(isodow from full_date) IN (6, 7) THEN true 
            ELSE false 
        END AS is_weekend,

        -- Prior Year Same Date (Exact calendar day 1 year ago)
        cast(full_date - interval '1 year' as date) AS prior_year_same_date,

        -- Prior Year Same Weekday (Subtracting 52 weeks / 364 days aligns day-of-week)
        cast(full_date - interval '52 weeks' as date) AS prior_year_same_weekday
    FROM base_dates
),

floating_holiday as (
    select * from {{ref('brazil_floating_holidays')}}
)

SELECT 
    c.*,
    -- Simple holiday fallback logic. Moving floating holidays to a seed is recommended.
    CASE 
        WHEN c.month = 1 AND c.day = 1 THEN true  -- New Year's Day
        WHEN c.month = 4 AND c.day = 21 THEN true  -- Tiradentes Day
        WHEN c.month = 5 AND c.day = 1 THEN true  -- Labor Day
        WHEN c.month = 9 AND c.day = 7 THEN true  -- Independence Day
        WHEN c.month = 10 AND c.day = 12 THEN true  -- Our Lady of Aparecida
        WHEN c.month = 11 AND c.day = 2 THEN true  -- All Souls' Day
        WHEN c.month = 11 AND c.day = 15 THEN true  -- Republic Proclamation Day
        WHEN c.month = 12 AND c.day = 25 THEN true  -- Christmas Day
        WHEN f.full_date is not null THEN true
        ELSE false
    END AS is_holiday
FROM date_calculations c left join floating_holiday f on c.full_date = f.full_date
