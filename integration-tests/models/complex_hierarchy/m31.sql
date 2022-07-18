select id, m21.s1_a, m21.s1_b, m22.s2_a, m22.s2_b, s3.s3_a, s3.s3_b
from {{ dbt_unit_testing.ref('m21') }}
left join {{ dbt_unit_testing.ref('m22') }} using(id)
left join {{ dbt_unit_testing.source('dbt_unit_testing', 's3') }} as s3 using(id)

