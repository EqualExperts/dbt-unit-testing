{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'db-dependency']
    )
}}

{% call dbt_unit_testing.test('m31', 'no need to specify all columns and mock all models', {"include_missing_columns": true, "use_database_models": true}) %}
  {% call dbt_unit_testing.mock_ref ('m21') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('m31', 'avoid roundtrip to fetch extra columns for m21', {"use_database_models": true}) %}
  {% call dbt_unit_testing.mock_ref ('m21') %}
    select 1 as id, null as s1_a, null as s1_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}

