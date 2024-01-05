{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_refers_different_column_cases') %}
  {% call dbt_unit_testing.mock_ref ('model_with_different_column_cases') %}
    select 
      1 as "UPPER_CASE_COLUMN",
      2 as "Mixed Case Column",
      3 as "lowercasecolumn",
      4 as UPPER_CASE_COLUMN,
      5 as MixedCaseColumn,
      6 as lower_case_column  
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 
      1 as "UPPER_CASE_COLUMN",
      2 as "Mixed Case Column",
      3 as "lowercasecolumn",
      4 as UPPER_CASE_COLUMN,
      5 as MixedCaseColumn,
      6 as lower_case_column  
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_refers_different_column_cases') %}
  {% call dbt_unit_testing.mock_ref ('model_with_different_column_cases', options={"include_missing_columns": true}) %}
    select 0 as c
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 
      CAST(null AS Int) as "UPPER_CASE_COLUMN",
      CAST(null AS Int) as "Mixed Case Column",
      CAST(null AS Int) as "lowercasecolumn",
      CAST(null AS Int) as UPPER_CASE_COLUMN,
      CAST(null AS Int) as MixedCaseColumn,
      CAST(null AS Int) as lower_case_column  
  {% endcall %}
{% endcall %}