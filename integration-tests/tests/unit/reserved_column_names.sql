{{
    config(
        tags=['unit-test', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_with_reserved_column_name', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 1 as a, 'b' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as "END"
  {% endcall %}
{% endcall %}
 