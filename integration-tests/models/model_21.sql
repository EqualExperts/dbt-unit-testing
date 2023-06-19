select * 
from {{ dbt_unit_testing.ref('model_11') }}
left join {{ dbt_unit_testing.ref('model_12') }} using(id)
