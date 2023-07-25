{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres', 'db-dependency']
    )
}}

{% call test_condition_on_model_query('model_31', "should not include model_11 if model_21 is mocked", {}, 
                                       assert_should_not_contain, "model_11") %}
  {% call dbt_unit_testing.mock_ref ('model_21') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call dbt_unit_testing.test('model_31', "unless we need to fetch missing columns") %}
  {% call dbt_unit_testing.mock_ref ('model_21', options={"include_missing_columns": true}) %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test_condition_on_model_query('model_31', "should not include source_1 if model_11 is mocked", {}, 
                                       assert_should_not_contain, "source_1") %}
  {% call dbt_unit_testing.mock_ref ('model_11') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}

UNION ALL

{% call test_condition_on_model_query('model_31', "should not include model_11 if using database models", 
                                       {"use_database_models": true}, 
                                       assert_should_not_contain, "model_11") %}
  {% call dbt_unit_testing.mock_ref ('model_22') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}
 
UNION ALL

{% call test_condition_on_model_query('model_31', "should not include model_12 if using database models", 
                                       {"use_database_models": true}, 
                                       assert_should_not_contain, "model_12") %}
  {% call dbt_unit_testing.mock_ref ('model_22') %}
    select 1 as id
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as id
  {% endcall %}
{% endcall %}
 