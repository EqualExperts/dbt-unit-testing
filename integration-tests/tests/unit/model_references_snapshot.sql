{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_references_snapshot', 'sample test') %}
  {% call dbt_unit_testing.mock_ref ('sample_snapshot') %}
    select  'a' as existing_source_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 'a' as existing_source_b
  {% endcall %}
{% endcall %}
