select * 
from {{ dbt_unit_testing.source('dbt_unit_testing', 's1') }}
left join {{ dbt_unit_testing.source('dbt_unit_testing', 's2') }} using(id)
