select id, m11.s1_a, m11.s1_b, m11.s2_a, m11.s2_b, m12.s3_a, m12.s3_b
from {{ dbt_unit_testing.ref('m11') }}
left join {{ dbt_unit_testing.ref('m12') }} using(id)
