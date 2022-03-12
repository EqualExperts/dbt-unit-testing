select day,
country_name,
cases
from {{ dbt_unit_testing.ref('covid19_cases_per_day') }} JOIN {{ dbt_unit_testing.ref('country_codes') }} on country_id = country_code