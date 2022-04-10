{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model-refers-source-with-dashes', 'Can refer to source with dashes in name') %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 'source-with-dashes') %}
    select 1 as example
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as example
  {% endcall %}
{% endcall %}