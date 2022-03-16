select origin from {{ dbt_unit_testing.ref('graph_b') }}
union all
select origin from {{ dbt_unit_testing.ref('graph_a') }}
