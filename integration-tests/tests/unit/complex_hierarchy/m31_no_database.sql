{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'no-db-dependency']
    )
}}

{% call dbt_unit_testing.test('m31', 'mock all models and sources') %}
  {% call dbt_unit_testing.mock_ref ('m21') %}
    select 1 as id, null as s1_a, null as s1_b
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('m22') %}
    select 1 as id, null as s2_a, null as s2_b
  {% endcall %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 's3') %}
    select 1 as id, null as s3_a, null as s3_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('m31', 'mock only one model, source s2 need to be mocked too') %}
  {% call dbt_unit_testing.mock_ref ('m21') %}
    select 1 as id, null as s1_a, null as s1_b
  {% endcall %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 's2') %}
    select 1 as id, null as s2_a, null as s2_b
  {% endcall %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing', 's3') %}
    select 1 as id, null as s3_a, null as s3_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}

