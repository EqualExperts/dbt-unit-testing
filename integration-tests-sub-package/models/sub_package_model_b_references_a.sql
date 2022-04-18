select * from {{ dbt_unit_testing.ref('sub_package_model_a') }} where a >=1
union all
select * from {{ dbt_unit_testing.source('dbt_unit_testing', 'sub_package_sample_source' )}} where a >= 1