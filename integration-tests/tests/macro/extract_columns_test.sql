select '{{ dbt_unit_testing.extract_columns("SELECT 1 as a, 2 as b") }}'
{{dbt_unit_testing.sql_except()}}
select 'a,b'