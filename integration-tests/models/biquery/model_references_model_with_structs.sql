select a, b, c, d from {{ dbt_unit_testing.ref('model_with_structs')}}
