select 
        {{ dbt_utils.star(ref('model_in_database')) }},
        {{ dbt_utils.star(source('dbt_unit_testing', 'sample_source_name')) }} 
from {{ dbt_unit_testing.ref('model_in_database') }}
left join {{ dbt_unit_testing.source('dbt_unit_testing', 'sample_source_name') }} on false
