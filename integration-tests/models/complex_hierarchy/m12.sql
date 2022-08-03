select id, s2.s2_a, s2.s2_b, s3.s3_a, s3.s3_b
from {{ dbt_unit_testing.source('dbt_unit_testing', 's2') }} as s2
left join {{ dbt_unit_testing.source('dbt_unit_testing', 's3') }} as s3 using(id)
