select 'schema_1' as from_schema, * from {{ dbt_unit_testing.source('schema_1', 'multi_schema_1') }}
union all
select 'schema_2' as from_schema, * from {{ dbt_unit_testing.source('schema_2', 'multi_schema_2') }}
