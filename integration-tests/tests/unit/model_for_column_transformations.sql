{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% set column_transformations = {
  "a": "round(##column##, 4)"
  }
%}

{% call dbt_unit_testing.test('model_for_column_transformations', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 10.0 as a, 'lower' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 3.3333 as a, 'LOWER' as b
  {% endcall %}
{% endcall %}
