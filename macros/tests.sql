{% macro test(model_name, test_description='(no description)', options={}) %}
  {{ dbt_unit_testing.ref_tested_model(model_name) }}

  {% if execute %}
    {% if flags.WHICH in ('test', 'build') %}
      {{ dbt_unit_testing.set_test_context("is_incremental_should_be_true_for_this_model", "") }}
      {% set mocks_and_expectations_json_str = caller() %}
      {% set model_version = kwargs["version"] | default(kwargs["v"]) | default(none) %}
      {% set model_node = {"package_name": model.package_name, "name": model_name, "version": model_version} %}
      {% set test_configuration, test_queries = dbt_unit_testing.build_configuration_and_test_queries(model_node, test_description, options, mocks_and_expectations_json_str) %}
      {% set test_report = dbt_unit_testing.build_test_report(test_configuration, test_queries) %}

      {% if not test_report.succeeded %}
        {{ dbt_unit_testing.show_test_report(test_configuration, test_report) }}
      {% endif %}
      
      select * from (select 1) as t where {{ not test_report.succeeded }}    
      {{ dbt_unit_testing.clear_test_context() }}
    {% else %}
      select * from (select 1) as t where 1 = 0
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro build_configuration_and_test_queries(model_node, test_description, options, mocks_and_expectations_json_str) %}
  {% set model_name = model_node.name %}
  {% do options.update({"column_transformations": {model_name: options.get("column_transformations", {})}}) %}
  {% set test_configuration = {
    "model_name": model_node.name, 
    "description": test_description, 
    "model_node": model_node,
    "options": dbt_unit_testing.merge_configs([options])} 
  %}
  {{ dbt_unit_testing.set_test_context("options", test_configuration.options) }}

  {{ dbt_unit_testing.verbose("CONFIG: " ~ test_configuration) }}
  
  {% do test_configuration.update (dbt_unit_testing.build_mocks_and_expectations(test_configuration, mocks_and_expectations_json_str)) %}
  {{ dbt_unit_testing.set_test_context("is_incremental_should_be_true_for_this_model", dbt_unit_testing.ref_cte_name(model_node)) }}
  {% set test_queries = dbt_unit_testing.build_test_queries(test_configuration) %}

  {{ return ((test_configuration, test_queries)) }}
{% endmacro %}

{% macro build_mocks_and_expectations(test_configuration, mocks_and_expectations_json_str) %}
    {% set mocks_and_expectations = dbt_unit_testing.split_json_str(mocks_and_expectations_json_str) %}

    {% for mock_or_expectation in mocks_and_expectations %}
      {% do mock_or_expectation.update( {"options": dbt_unit_testing.merge_configs([test_configuration.options, mock_or_expectation.options])}) %}
      {% set input_values = dbt_unit_testing.build_input_values_sql(mock_or_expectation.input_values, mock_or_expectation.options) %}
      {% do mock_or_expectation.update({"input_values": input_values}) %}
    {% endfor %}

    {% set mocks = mocks_and_expectations | selectattr("type", "==", "mock") | list %}
    {% set expectations = mocks_and_expectations | selectattr("type", "==", "expectations") | first %}

    {% for mock in mocks %}
      {% do mock.update({"unique_id": dbt_unit_testing.graph_node(mock).unique_id}) %}
      {% if mock.options.include_missing_columns %}
        {% do dbt_unit_testing.enrich_mock_sql_with_missing_columns(mock, test_configuration.options) %}
      {% endif %}
    {% endfor %}

    {% set mocks_and_expectations_json = {
      "mocks": mocks,
      "expectations": expectations
      }
    %}

    {{ return (mocks_and_expectations_json) }}
{% endmacro %}

{% macro build_test_report(test_configuration, test_queries) %}

  {% set test_report = dbt_unit_testing.run_test_query(test_configuration, test_queries) %}

  {{ dbt_unit_testing.verbose("-------------------- " ~ test_configuration.model_name ~ " --------------------" ) }}
  {{ dbt_unit_testing.verbose(test_queries.test_query) }}
  {{ dbt_unit_testing.verbose("----------------------------------------" ) }}

  {{ return (test_report) }}
{% endmacro %}

{% macro build_test_queries(test_configuration) %}
  {% set expectations = test_configuration.expectations %}
  {% set model_node = dbt_unit_testing.model_node(test_configuration.model_node) %}
  {%- set model_complete_sql = dbt_unit_testing.build_model_complete_sql(model_node, test_configuration.mocks, test_configuration.options) -%}

  {% if expectations.no_rows %}
    {% set expectations_sql = "select * from (" ~ model_complete_sql ~ ") as t where 1 = 0" %}
  {% else %}
    {% set expectations_sql = expectations.input_values %}
  {% endif %}

  {% set column_transformations = test_configuration.options.column_transformations[test_configuration.model_name] | default({}) %}
  {% set columns_list = dbt_unit_testing.extract_columns_list(expectations_sql) %}
  {% set columns_list_str = dbt_unit_testing.quote_and_join_columns(columns_list) %}
  {% set transformed_columns_list_str = dbt_unit_testing.apply_transformations_to_columns(columns_list, column_transformations, use_alias=true) | join(", ") %}
  {% set transformed_columns_list_for_grouping_str = dbt_unit_testing.apply_transformations_to_columns(columns_list, column_transformations, use_alias=false) | join(", ")  %}

  {% set diff_column = test_configuration.options.diff_column | default("diff") %}
  {% set count_column = test_configuration.options.count_column | default("count") %}

  {%- set actual_query -%}
    select count(1) as {{ count_column }}, {{ transformed_columns_list_str }} from ( {{ model_complete_sql }} ) as s group by {{ transformed_columns_list_for_grouping_str }}
  {% endset %}

  {%- set expectations_query -%}
    select count(1) as {{ count_column }}, {{ transformed_columns_list_str }} from ({{ expectations_sql }}) as s group by {{ transformed_columns_list_for_grouping_str }}
  {% endset %}

  {%- set test_query -%}
    with expectations as (
      {{ expectations_query }}
    ),
    actual as (
      {{ actual_query }}
    ),

    extra_entries as (
    select '+' as {{ diff_column }}, {{ count_column }}, {{ columns_list_str }} from actual
    {{ except() }}
    select '+' as {{ diff_column }}, {{ count_column }}, {{ columns_list_str }} from expectations),

    missing_entries as (
    select '-' as {{ diff_column }}, {{ count_column }}, {{ columns_list_str }} from expectations
    {{ except() }}
    select '-' as {{ diff_column }}, {{ count_column }}, {{ columns_list_str }} from actual)
    
    select * from extra_entries
    UNION ALL
    select * from missing_entries

    {% set sort_field = test_configuration.options.get("output_sort_field") %}
    {% if sort_field %}
    ORDER BY {{ sort_field }}
    {% endif %}
  {%- endset -%}

  {% set test_queries = {
    "model_query": model_complete_sql,
    "actual_query": actual_query,
    "expectations_query": expectations_query,
    "test_query": test_query
  } %}

  {{ return (test_queries) }}
{% endmacro %}

{% macro show_test_report(test_configuration, test_report) %}
  {% set model_name = test_configuration.model_name %}
  {% set test_description = test_configuration.description %}

  {{ dbt_unit_testing.println('{RED}MODEL: {YELLOW}' ~ model_name) }}
  {{ dbt_unit_testing.println('{RED}TEST:  {YELLOW}' ~ test_description) }}
  {% if test_report.expectations_row_count != test_report.actual_row_count %}
    {{ dbt_unit_testing.println('{RED}ERROR: {YELLOW}Number of Rows do not match! (Expected: ' ~ test_report.expectations_row_count ~ ', Actual: ' ~ test_report.actual_row_count ~ ')') }}
  {% endif %}
  {% if test_report.different_rows_count > 0 %}
    {{ dbt_unit_testing.println('{RED}ERROR: {YELLOW}Rows mismatch:') }}
    {{ dbt_unit_testing.print_table(test_report.test_differences, options=test_configuration.options) }}
  {% endif %}
{% endmacro %}

{% macro run_test_query(test_configuration, test_queries) %}
  {% set model_name = test_configuration.model_name %}
  {% set test_description = test_configuration.description %}
  {% set actual_query = test_queries.actual_query %}
  {% set expectations_query = test_queries.expectations_query %}
  {% set test_query = test_queries.test_query %}

  {%- set count_query -%}
    select * FROM 
      (select count(1) as expectation_count from (
        {{ expectations_query }}
      ) as exp) as exp_count,
      (select count(1) as actual_count from (
        {{ actual_query }}
      ) as act) as act_count
  {%- endset -%}
  {% set r1 = dbt_unit_testing.run_query(count_query) %}
  {% set expectations_row_count = r1.columns[0].values() | first %}
  {% set actual_row_count = r1.columns[1].values() | first %}

  {% set test_differences = dbt_unit_testing.run_query(test_query) %}
  {% set different_rows_count = test_differences.rows | length %}
  {% set succeeded = different_rows_count == 0 and (expectations_row_count == actual_row_count) %}

  {% set test_report = {
    "expectations_row_count": expectations_row_count,
    "actual_row_count": actual_row_count,
    "different_rows_count": different_rows_count,
    "test_differences": test_differences,
    "succeeded": succeeded,
  } %}
  {{ return (test_report) }}

{% endmacro %}

{% macro ref_tested_model(model_name) %}
  {% set ref_tested_model %}
    -- We add an (unused) reference to the tested model,
    -- so that DBT includes the model as a dependency of the test in the DAG
    select * from {{ ref(model_name) }}
  {% endset %}
{% endmacro %}

