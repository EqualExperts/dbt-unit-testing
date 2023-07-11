{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('incremental_model_using_incremental_model', 'full refresh test') %}
  {% call dbt_unit_testing.mock_ref ('incremental_model_1') %}
    select 100 as c1
    UNION ALL
    select 200 as c1
    UNION ALL
    select 300 as c1
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model_using_incremental_model') %}
    select 150 as c1
    UNION ALL
    select 250 as c1
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 100 as c1
    UNION ALL
    select 200 as c1
    UNION ALL
    select 300 as c1
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('incremental_model_using_incremental_model', 'incremental test', options={"run_as_incremental": "True"}) %}
  {% call dbt_unit_testing.mock_ref ('incremental_model_1') %}
    select 100 as c1
    UNION ALL
    select 200 as c1
    UNION ALL
    select 300 as c1
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model_using_incremental_model') %}
    select 100 as c1
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 200 as c1
    UNION ALL
    select 300 as c1
  {% endcall %}
{% endcall %}
 