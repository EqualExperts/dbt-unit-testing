{% macro test(model_name, test_description, options={}) %}
    {{ dbt_unit_testing._test(model_name, test_description, caller(), options)}}
{% endmacro %}

{% macro _test(model_name, test_description, test_info, options={}) %}
    {% set test_description = test_description | default('(no description)') %}
    {% set test_info = test_info | trim %}
    {% set test_info_last_comma_removed = test_info[:-1] %}
    {% set test_info_json = fromjson('{' ~ test_info_last_comma_removed ~ '}') %}

    {% for k, v in test_info_json.items() %}
      {% set dummy = test_info_json.update({k: dbt_unit_testing.sql_decode(v)}) %}
    {% endfor %}

    {% set expectations = test_info_json['__EXPECTATIONS__'] %}
    {% set dummy = test_info_json.pop('__EXPECTATIONS__') %}

    {{ dbt_unit_testing.run_test(model_name, test_description, test_info_json, expectations, options)}}
{% endmacro %}

{% macro ref(model_name) %}
  {%- if 'unit-test' in config.get('tags') -%}
      {{model_name}}
  {%- else -%}
      {{ return (builtins.ref(model_name)) }}
  {%- endif -%}
{% endmacro %}

{% macro source(source, model_name) %}
  {%- if 'unit-test' in config.get('tags') -%}
      {{model_name}}
  {%- else -%}
      {{ return (builtins.source(source, model_name)) }}
  {%- endif -%}
{% endmacro %}

{% macro build_input_values_sql(input_values, options) %}
    {% set input_format = options.get("input_format", dbt_unit_testing.get_config("input_format", "sql")) %}

    {% set input_values_sql = input_values %}

    {% if input_format == "csv" %}
      {% set input_values_sql = dbt_unit_testing.sql_from_csv_input(input_values, options) %}
    {%- endif -%}

    {{ return (input_values_sql) }}
{% endmacro %}

{% macro mock_ref(model_name, options={}) %}
    {{ dbt_unit_testing.mock_input(model_name, '', caller(), options) }}
{% endmacro %}

{% macro mock_source(source_name, model_name, options={}) %}
    {{ dbt_unit_testing.mock_input(model_name, source_name, caller(), options) }}
{% endmacro %}

{% macro mock_input(model_name, source_name, input_values, options) %}
  {% if execute %}
    {% set mocking_strategy = dbt_unit_testing.get_mocking_strategy(options) %}

    {% set input_values_sql = dbt_unit_testing.build_input_values_sql(input_values, options) %}
    {% set model_node = dbt_unit_testing.graph_node(source_name, model_name) %}

    {% set options = {"fetch_mode": 'DATABASE' if mocking_strategy.database else 'FULL' } %}
    {% set full_node_sql = dbt_unit_testing.build_node_sql(model_node, options) %}

    {% set model_columns = dbt_unit_testing.extract_columns_list(full_node_sql) %}
    {% set input_columns = dbt_unit_testing.extract_columns_list(input_values_sql) %}
    {% set extra_columns = dbt_unit_testing.extract_columns_difference(model_columns, input_columns) %}

    {%- set input_sql_with_all_columns -%}
      select * from ({{input_values_sql}}) as {{model_name}}_tmp_1

      {% if extra_columns %}
        {% if mocking_strategy.simplified %}
          {% set null_extra_columns = [] %}
          {% for c in extra_columns %}
            {% set null_extra_columns = null_extra_columns.append("null as " ~ c) %}
          {% endfor %}
          left join (select {{ null_extra_columns | join (",")}}) as {{model_name}}_tmp_3 on false
        {% else %}
          {% set simple_node_sql = dbt_unit_testing.build_node_sql(model_node, {"fetch_mode": 'DATABASE' if mocking_strategy.database else 'RAW' }) %}
            left join (select {{ extra_columns | join (",")}}
                      from ({{ simple_node_sql }}) as {{model_name}}_tmp_2) as {{model_name}}_tmp_3 on false
        {% endif %}
      {% endif %}

    {%- endset -%}

    {% set input_as_json = '"' ~ model_name  ~ '": "' ~ dbt_unit_testing.sql_encode(input_sql_with_all_columns) ~ '",' %}
    {{ return (input_as_json) }}
  {% endif %}
{% endmacro %}

{% macro expect(options={}) %}
    {%- set model_sql = dbt_unit_testing.build_input_values_sql(caller(), options) -%}
    {%- set input_as_json = '"__EXPECTATIONS__": "' ~ dbt_unit_testing.sql_encode(model_sql) ~ '",' -%}
    {{ return (input_as_json) }}
{% endmacro %}

{% macro run_test(model_name, test_description, mocked_models, expectations, options) %}
  {% set hide_errors = options.get("hide_errors", false) %}
  {% set mocking_strategy = dbt_unit_testing.get_mocking_strategy(options) %}

  {% set model_node = dbt_unit_testing.model_node(model_name) %}
  {% set sql_options = { "fetch_mode": 'DATABASE' if mocking_strategy.database else 'RAW',
                         "include_all_dependencies": mocking_strategy.full } %}

  {% set model_complete_sql = dbt_unit_testing.build_model_complete_sql(model_node, mocked_models, sql_options) %}
  {% set columns = dbt_unit_testing.quote_and_join_columns(dbt_unit_testing.extract_columns_list(expectations)) %}

  {%- set actual_query -%}
    select {{columns}} from ( {{ model_complete_sql }} ) as s
  {% endset %}

  {%- set expectations_query -%}
    select {{columns}} from ({{ expectations }}) as s
  {% endset %}

  {%- set test_query -%}
    with
  
    expectations as ({{ expectations_query }}),
    actual as ({{ actual_query }}),

    extra_entries as (
    select '+' as diff, {{columns}} from actual 
    {{ dbt_utils.except() }}
    select '+' as diff, {{columns}} from expectations),

    missing_entries as (
    select '-' as diff, {{columns}} from expectations
    {{ dbt_utils.except() }}
    select '-' as diff, {{columns}} from actual)
    
    select * from extra_entries
    UNION ALL
    select * from missing_entries

  {% endset %}

  {% if execute %}
    {% if var('debug', false) or dbt_unit_testing.get_config('debug', false) %}
      {{ dbt_unit_testing.debug("------------------------------------") }}
      {{ dbt_unit_testing.debug("MODEL: " ~ model_name) }}
      {{ dbt_unit_testing.debug(test_query) }}
    {% endif %}

    {% set r1 = run_query("select count(1) from (" ~ expectations_query ~ ") as t") %}
    {% set expectations_row_count = r1.columns[0].values() | first %}
    {% set r2 = run_query("select count(1) from (" ~ actual_query ~ ") as t") %}
    {% set actual_row_count = r2.columns[0].values() | first %}

    {% set results = run_query(test_query) %}
    {% set results_length = results.rows | length %}
    {% set failed = results_length > 0 or expectations_row_count != actual_row_count %}

    {% if failed and not hide_errors %}
      {%- do log('\x1b[31m' ~ 'MODEL: ' ~ model_name ~ '\x1b[0m', info=true) -%}
      {%- do log('\x1b[31m' ~ 'TEST:  ' ~ test_description ~ '\x1b[0m', info=true) -%}
      {% if expectations_row_count != actual_row_count %}
        {%- do log('\x1b[31m' ~ 'Number of Rows do not match! (Expected: ' ~ expectations_row_count ~ ', Actual: ' ~ actual_row_count ~ ')' ~ '\x1b[0m', info=true) -%}
      {% endif %}
      {% if results_length > 0 %}
        {%- do log('\x1b[31m' ~ 'Rows mismatch:' ~ '\x1b[0m', info=true) -%}
        {% do results.print_table(max_columns=None, max_column_width=30) %}
      {% endif %}
    {% endif %}
    select 1 from (select 1) as t where {{ failed }}
  {% endif %}
{% endmacro %}