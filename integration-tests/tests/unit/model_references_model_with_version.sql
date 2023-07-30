{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'versioned', '1.5.4']
    )
}}

{% call dbt_unit_testing.test('model_references_model_with_version', 'latest version') %}
  {% call dbt_unit_testing.mock_ref ('model_with_version') %}
    select 0 as a
    UNION ALL
    select 1234 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1234 as a
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_references_model_with_version_1', 'version 1') %}
  {% call dbt_unit_testing.mock_ref ('model_with_version', v=1) %}
    select 1 as a
    UNION ALL
    select 1234 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1234 as a
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_references_model_with_version_2', 'version 2') %}
  {% call dbt_unit_testing.mock_ref ('model_with_version', version=2) %}
    select 2 as a
    UNION ALL
    select 1234 as a
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1234 as a
  {% endcall %}
{% endcall %}
 