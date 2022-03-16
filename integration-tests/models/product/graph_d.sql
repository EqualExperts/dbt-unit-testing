select upper(origin) as origin from {{ dbt_unit_testing.ref('graph_c') }}
