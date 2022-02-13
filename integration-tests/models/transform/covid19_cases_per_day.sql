{{ config(dataset='transform')}}
select 
day,
country_id,
SUM(COALESCE(CAST(JSON_EXTRACT(payload,'$[0].newCases')  AS INT64),0)) as cases
from {{ dbt_unit_testing.source('dbt_unit_testing_staging','covid19_stg') }} group by day, country_id