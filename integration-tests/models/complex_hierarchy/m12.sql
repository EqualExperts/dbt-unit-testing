select id, s2.s2_a, s2.s2_b, s3.s3_a, s3.s3_b
from {{ dbt_unit_testing.source('dbt_unit_testing_complex_hierarchy', 's2') }}
left join {{ dbt_unit_testing.source('dbt_unit_testing_complex_hierarchy', 's3') }} using(id)
