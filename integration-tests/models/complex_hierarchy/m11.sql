select * 
from {{ dbt_unit_testing.source('dbt_unit_testing_complex_hierarchy', 's1') }}
left join {{ dbt_unit_testing.source('dbt_unit_testing_complex_hierarchy', 's2') }} using(id)
