{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% call dbt_unit_testing.test('model_with_quoted_columns_2_bq') %}
  {% call dbt_unit_testing.mock_ref ('model_with_quoted_columns_1_bq', options={"include_missing_columns": true}) %}
    select 10 as lower
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 10 as lower
  {% endcall %}
{% endcall %}
