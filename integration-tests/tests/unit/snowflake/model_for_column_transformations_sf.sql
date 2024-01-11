{{
    config(
        tags=['unit-test', 'snowflake']
    )
}}

{% set column_transformations = {
  "COLUMN_A": "round(##column##, 4)",
  "COLUMN_B": "upper(##column##)"
  }
%}

{% call dbt_unit_testing.test('model_for_column_transformations', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 10.0 as a, 'lower' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 3.3333 as COLUMN_A, 'LOWER' as column_b
  {% endcall %}
{% endcall %}
