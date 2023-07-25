select * from {{ dbt_unit_testing.ref('dbt_unit_testing_sub_package', 'sub_package_model_a') }} where a >=1
