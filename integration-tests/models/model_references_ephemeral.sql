select * from {{ dbt_unit_testing.ref('model_ephemeral') }} where a >= 1
