select a.* 
from {{dbt_unit_testing.ref('model_a')}} as a 
left join {{dbt_unit_testing.ref('model_with_comment')}} on True