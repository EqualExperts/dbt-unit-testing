select '{{ dbt_unit_testing.extract_columns_difference("SELECT 1 as a, 2 as b","SELECT 1 as a, 2 as d") }}'
{{dbt_unit_testing.sql_except()}}
select 'b'