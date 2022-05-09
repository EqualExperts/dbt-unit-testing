select 'dbt_unit_testing' as from_schema, * from {{ dbt_unit_testing.source('dbt_unit_testing', 'multi_schema') }}
union all
select 'dbt_unit_testing_2' as from_schema, * from {{ dbt_unit_testing.source('dbt_unit_testing_2', 'multi_schema') }}
