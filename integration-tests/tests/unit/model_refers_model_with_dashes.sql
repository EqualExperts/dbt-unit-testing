{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model-refers-model-with-dashes', 'Can refer to model with dashes in name') %}
  {% call dbt_unit_testing.mock_ref ('model-with-dashes') %}
    select 1 as example
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as example
  {% endcall %}
{% endcall %}