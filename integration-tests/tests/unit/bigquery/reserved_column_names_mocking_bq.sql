{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% call dbt_unit_testing.test('model_references_model_with_reserved_column_name_bq', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('model_with_reserved_column_name_bq') %}
    select 1 as a, 'b' as b, 1 as `end`
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, 'b' as b, 1 as `end`
  {% endcall %}
{% endcall %}
 