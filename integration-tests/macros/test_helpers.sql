{% macro test_should_fail (model_name, test_description) %}
  {{ dbt_unit_testing.ref_tested_model(model_name) }}
  {% if execute %}
    {% set mocks_and_expectations_json_str = caller() %}
    {% set model_node = {"package_name": model.package_name, "name": model_name} %}
    {% set test_configuration, test_queries = dbt_unit_testing.build_configuration_and_test_queries(model_node, test_description, {}, mocks_and_expectations_json_str) %}
    {% set test_report = dbt_unit_testing.build_test_report(test_configuration, test_queries) %}

    {{ dbt_unit_testing.verbose("-------------------- " ~ test_configuration.model_name ~ " --------------------" ) }}
    {{ dbt_unit_testing.verbose(test_queries.test_query) }}
    {{ dbt_unit_testing.verbose("----------------------------------------" ) }}

    {% if test_report.succeeded %}
        {{ dbt_unit_testing.println("{RED}Test: " ~ "{YELLOW}" ~ test_description ~ " {RED}should have FAILED")}}
    {% endif %}
    select 1 from (select 1) as t where {{ test_report.succeeded }}
  {% endif %}
{% endmacro %}

{% macro test_condition_on_model_query (model_name, test_description, options, condition) %}
  {{ dbt_unit_testing.ref_tested_model(model_name) }}
  {% if execute %}
    {% set mocks_and_expectations_json_str = caller() %}
    {% set model_node = {"package_name": model.package_name, "name": model_name} %}
    {% set test_configuration, test_queries = dbt_unit_testing.build_configuration_and_test_queries(model_node, test_description, options, mocks_and_expectations_json_str) %}

    {% set model_query = test_queries["model_query"] %}

    {{ dbt_unit_testing.verbose("-------------------- " ~ test_configuration.model_name ~ " --------------------" ) }}
    {{ dbt_unit_testing.verbose(test_queries.test_query) }}
    {{ dbt_unit_testing.verbose("----------------------------------------" ) }}

    {% set succeeded = condition(model_query, *varargs) %}
    {% if not succeeded %}
        {{ dbt_unit_testing.println("{RED}Test: " ~ "{YELLOW}" ~ test_description ~ " {RED}FAILED")}}
    {% endif %}

    select 1 from (select 1) as t where {{ not succeeded }}
  {% endif %}
{% endmacro %}

{% macro assert_should_contain(s, should_be_there) %}
 {{ return (should_be_there in s) }}
{% endmacro %}

{% macro assert_should_not_contain(s, should_not_be_there) %}
 {{ return (not should_not_be_there in s) }}
{% endmacro %}

{% macro is_incremental() %}
  {{ return (dbt_unit_testing.is_incremental()) }}
{% endmacro %}

