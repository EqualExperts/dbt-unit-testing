{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('incremental_model', 'full refresh test') %}
  {% call dbt_unit_testing.mock_ref ('model_for_incremental') %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model') %}
    select 15 as c
    UNION ALL
    select 25 as c
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('incremental_model', 'incremental test', options={"run_as_incremental": "True"}) %}
  {% call dbt_unit_testing.mock_ref ('model_for_incremental') %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model') %}
    select 10 as c
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
{% endcall %}
 