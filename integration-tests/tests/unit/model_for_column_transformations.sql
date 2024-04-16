{{
    config(
        tags=['unit-test', 'bigquery', 'postgres']
    )
}}

{% set column_transformations = {
  "column_a": "round(##column##, 4)",
  "column_b": "upper(##column##)"
  }
%}

{% call dbt_unit_testing.test('model_for_column_transformations', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 10.0 as a, 'lower' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 3.3333 as column_a, 'LOWER' as column_b
  {% endcall %}
{% endcall %}

UNION ALL

{% set column_transformations = {
  "column_b": "upper(##column##)"
  }
%}

{% call dbt_unit_testing.test('model_for_column_transformations', 'should merge config from dbt_project', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('model_a') %}
    select 10.0 as a, 'lower' as b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 3.33333 as column_a, 'LOWER' as column_b
  {% endcall %}
{% endcall %}
