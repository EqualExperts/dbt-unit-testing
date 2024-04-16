select a / 3 as column_a, b as column_b from {{ dbt_unit_testing.ref ('model_a') }}
