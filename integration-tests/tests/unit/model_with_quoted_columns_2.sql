{{
    config(
        tags=['unit-test', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_with_quoted_columns_2') %}
  {% call dbt_unit_testing.mock_ref ('model_with_quoted_columns_1', options={"include_missing_columns": true}) %}
    select 1 as lower
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as lower
  {% endcall %}
{% endcall %}
