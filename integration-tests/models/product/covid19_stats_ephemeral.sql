{{ config(materialized='ephemeral')}}
select day,
country_name,
cases
from {{ dbt_unit_testing.ref('covid19_cases_per_day_ephemeral') }} JOIN {{ dbt_unit_testing.source('dbt_unit_testing','covid19_country_stg') }} USING (country_id)