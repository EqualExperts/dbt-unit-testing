select * 
from {{ dbt_unit_testing.ref('model_a') }}
left join {{ dbt_unit_testing.ref('model_with_complex_query') }} on false
