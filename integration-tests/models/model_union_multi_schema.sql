select 'schema_1' as from_schema, multi_schema.name from {{ dbt_unit_testing.source('source_from_schema_1', 'multi_schema') }} as multi_schema
union all
select 'schema_2' as from_schema, multi_schema.name from {{ dbt_unit_testing.source('source_from_schema_2', 'multi_schema') }} as multi_schema
