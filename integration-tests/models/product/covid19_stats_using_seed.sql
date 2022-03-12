select day,
cases,
value
from {{ dbt_unit_testing.ref('covid19_cases_per_day') }}, {{ dbt_unit_testing.ref('seed_test') }}