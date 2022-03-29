WITH
s1 AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="cast('2020-01-01' as date)",
      end_date= "cast('2022-01-01' as date)"
     )
  }}
),
s2 AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="cast('2020-01-01' as date)",
      end_date= "cast('2022-01-01' as date)"
     )
  }}
),
s3 AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="cast('2020-01-01' as date)",
      end_date= "cast('2022-01-01' as date)"
     )
  }}
),
s4 AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="cast('2020-01-01' as date)",
      end_date= "cast('2022-01-01' as date)"
     )
  }}
),
s5 AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="cast('2020-01-01' as date)",
      end_date= "cast('2022-01-01' as date)"
     )
  }}
)

select 1 as complex_1,
       2 as complex_2
from s1
left join s2 on false
left join s3 on false
left join s4 on false
left join s5 on false
where false
