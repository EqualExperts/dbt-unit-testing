select * 
from {{ dbt_unit_testing.ref('model_21') }}
left join {{ dbt_unit_testing.ref('model_22') }} using(id)
