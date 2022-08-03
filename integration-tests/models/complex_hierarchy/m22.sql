select id, m12.s2_a, m12.s2_b, s3.s3_a, s3.s3_b
from {{ dbt_unit_testing.ref('m12') }}
left join {{ dbt_unit_testing.source('dbt_unit_testing', 's3') }} as s3 using(id)
