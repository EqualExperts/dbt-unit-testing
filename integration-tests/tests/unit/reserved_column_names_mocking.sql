{{
    config(
        tags=['unit-test', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_references_model_with_reserved_column_name', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_with_reserved_column_name', options={"include_missing_columns": true}) %}
    select 1 as a, 'b' as b, 1 as "END"
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as "END"
  {% endcall %}
{% endcall %}
 
 UNION ALL

 {% call dbt_unit_testing.test('model_references_model_with_reserved_column_name', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_with_reserved_column_name', options={"include_missing_columns": true}) %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b
  {% endcall %}
{% endcall %}
 