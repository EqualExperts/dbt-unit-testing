{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'versioned', '1.5.4']
    )
}}

{% call dbt_unit_testing.test('model_with_version', 'version 1', version=1) %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_with_version', 'version 2', v=2) %}
  {% call dbt_unit_testing.expect() %}
    select 2 as a
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_with_version', 'latest version') %}
  {% call dbt_unit_testing.expect() %}
    select 2 as a
  {% endcall %}
{% endcall %}
