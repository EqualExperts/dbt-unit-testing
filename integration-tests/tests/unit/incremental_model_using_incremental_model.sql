{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('incremental_model_using_incremental_model', 'incremental test', options={"run_as_incremental": "True"}) %}
  {% call dbt_unit_testing.mock_ref ('incremental_model') %}
    select 100 as d
    UNION ALL
    select 200 as d
    UNION ALL
    select 300 as d
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model_using_incremental_model') %}
    select 100 as d
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 200 as d
    UNION ALL
    select 300 as d
  {% endcall %}
{% endcall %}
 