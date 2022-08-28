{% macro test_should_fail (model_name, test_description) %}
  {% set mocks_and_expectations_json_str = caller() %}
  {{ dbt_unit_testing.ref_tested_model(model_name) }}
  {% if execute %}
    {% set test_configuration = {
      "model_name": model_name, 
      "description": test_description, 
      "options": {"hide_errors": true}} 
    %}

    {% do test_configuration.update (dbt_unit_testing.build_mocks_and_expectations(test_configuration, mocks_and_expectations_json_str)) %}
    {% set test_report = dbt_unit_testing.build_test_report(test_configuration) %}

    {% if test_report.succeeded %}
        {{ dbt_unit_testing.println("{RED}Test: " ~ "{YELLOW}" ~ test_description ~ " {RED}should have FAILED")}}
    {% endif %}
    select 1 from (select 1) as t where {{ test_report.succeeded }}
  {% endif %}
{% endmacro %}
