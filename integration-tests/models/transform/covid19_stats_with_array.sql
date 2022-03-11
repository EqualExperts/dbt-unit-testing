select 
country_id,
ARRAY_AGG(cases) as cases
from {{ dbt_unit_testing.ref('covid19_cases_per_day') }}
group by country_id